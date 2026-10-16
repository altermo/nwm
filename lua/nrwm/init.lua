local ffi=require'ffi'
local wayland=require'nrwm.c.wayland'
local rwm=require'nrwm.c.river-window-management-v1'
local wcp=require'nrwm.c.wayland-client-protocol'
local clib=require'nrwm.c.clib'

local M={}

local state={
    display=nil,
    window_manager_ptr=nil,

    main_output=nil,
    top_window=nil,
    active_window=nil,

    outputs={},
    windows={},
    seats={},
}
state=nil

local function add(tbl,item)
    local id=ffi.cast('void*',assert(item.ptr))
    tbl[tostring(id)]=item
    return id
end
local function remove(tbl,item)
    local id=ffi.cast('void*',assert(item.ptr))
    tbl[tostring(id)]=nil
end
local function get(tbl,id)
    return assert(tbl[tostring(id)])
end

local function get_display()
    return state and assert(state.display)
end

local function noop() end

local function win_update(id)
    local window=get(state.windows,id)
    if not window.buf then
        return
    end
    local buf=window.buf
    if not vim.api.nvim_buf_is_valid(buf) then
        window.to_close=true
        window.buf=nil
        rwm.river_window_manager_v1.manage_dirty(state.window_manager_ptr)
        return
    end

    local vwins={}
    local _repeat=0
    while true do
        for _,vwin in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.api.nvim_win_get_buf(vwin)==buf then
                table.insert(vwins,vwin)
            end
        end
        if #vwins<=1 then break end
        TODO()
        vwins={}
        _repeat=_repeat+1
        if _repeat>100 then error'' end
    end
    if vim.api.nvim_get_current_buf()==window.buf and vim.fn.mode()=='t' then
        if state.active_window~=window then
            rwm.river_window_manager_v1.manage_dirty(state.window_manager_ptr)
        end
        state.active_window=window
    elseif state.active_window==window then
        state.active_window=nil
        rwm.river_window_manager_v1.manage_dirty(state.window_manager_ptr)
    end
    if #vwins==0 then
        if window.hide==false then
            rwm.river_window_manager_v1.manage_dirty(state.window_manager_ptr)
        end
        window.hide=true
        return
    end
    if window.hide==true then
        rwm.river_window_manager_v1.manage_dirty(state.window_manager_ptr)
    end
    window.hide=false
    local vwin=vwins[1]

    local sz=ffi.new'struct winsize[1]'
    clib.ioctl(0,clib.TIOCGWINSZ,sz)
    local xpx=math.floor(sz[0].ws_xpixel/vim.o.columns)
    local ypx=math.floor(sz[0].ws_ypixel/vim.o.lines)
    local height=vim.api.nvim_win_get_height(vwin)
    local width=vim.api.nvim_win_get_width(vwin)
    local row,col=unpack(vim.api.nvim_win_get_position(vwin))
    local colpx=col*xpx
    local rowpx=row*ypx
    local widthpx=width*xpx
    local heightpx=height*ypx
    if window.x~=colpx or window.y~=rowpx or
        window.width~=widthpx or window.height~=heightpx then
        window.x=colpx
        window.y=rowpx
        window.width=widthpx
        window.height=heightpx
        rwm.river_window_manager_v1.manage_dirty(state.window_manager_ptr)
    end
end

local function win_update_all()
    for id in pairs(state.windows) do
        win_update(id)
    end
end

local window_listener=ffi.new('struct river_window_v1_listener[1]',{{
    closed=noop,dimensions_hint=noop,dimensions=noop,app_id=noop,
    title=noop,parent=noop,decoration_hint=noop,pointer_move_requested=noop,
    pointer_resize_requested=noop,show_window_menu_requested=noop,
    maximize_requested=noop,unmaximize_requested=noop,fullscreen_requested=noop,
    exit_fullscreen_requested=noop,minimize_requested=noop,presentation_hint=noop,
    identifier=noop,
    unreliable_pid=function(id,_,win_pid)
        local window=get(state.windows,id)
        if not state.top_window then
            local pid=vim.uv.os_getpid()
            while pid and pid~=0 do
                if win_pid==pid then
                    state.top_window=window
                    return
                end
                pid=vim.api.nvim_get_proc(pid).ppid
            end
        end

        local buf=vim.api.nvim_create_buf(true,true)
        vim.api.nvim_open_term(buf,{})
        vim.api.nvim_buf_set_name(buf,('nrwm://%p'):format(id))
        window.buf=buf

        vim.cmd.vsplit()
        vim.api.nvim_set_current_buf(buf)

        window.hide=true
        win_update(id)
    end,
}})

local output_listener=ffi.new('struct river_output_v1_listener[1]',{{
    removed=noop,wl_output=noop,
    position=function(id,_,x,y)
        local output=get(state.outputs,id)
        output.x=x
        output.y=y
    end,
    dimensions=function(id,_,width,height)
        local output=get(state.outputs,id)
        output.width=width
        output.height=height
    end,
}})

local seat_listener=ffi.new('struct river_seat_v1_listener[1]',{{
    removed=noop,wl_seat=noop,pointer_enter=noop,pointer_leave=noop,
    window_interaction=noop,shell_surface_interaction=noop,op_delta=noop,
    op_release=noop,pointer_position=noop,
}})

local wm_listener=ffi.new('struct river_window_manager_v1_listener[1]',{{
    session_locked=noop,session_unlocked=noop,
    unavailable=function()
        state=nil
        error('already managed by another process')
    end,
    finished=function()
        state=nil
    end,
    manage_start=function()
        for _,window in pairs(state.windows) do
            if window.to_close then
                river_window_v1.close(window)
            end
        end

        for _,output in pairs(state.outputs) do
            if output.removed then
                TODO()
            end
        end
        for _,window in pairs(state.windows) do
            if window.removed then
                TODO()
            end
        end
        for _,seat in pairs(state.seats) do
            if seat.removed then
                TODO()
            end
        end

        if state.main_output and state.main_output.removed then
            state.main_output=nil
        end
        if state.top_window and state.top_window.removed then
            TODO()
        end
        if state.active_window and state.active_window.removed then
            state.active_window=nil
        end

        if not state.main_output then
            local _,output=next(state.outputs)
            state.main_output=output
        end
        if state.main_output and state.top_window then
            state.top_window.x=state.main_output.x
            state.top_window.y=state.main_output.y
            state.top_window.width=state.main_output.width
            state.top_window.height=state.main_output.height
        end

        for _,window in pairs(state.windows) do
            rwm.river_window_v1.use_ssd(window.ptr)
            if window.width and window.height then
                rwm.river_window_v1.propose_dimensions(window.ptr,window.width,window.height)
            end
        end

        for _,seat in pairs(state.seats) do
            if state.active_window then
                rwm.river_seat_v1.focus_window(seat.ptr,state.active_window.ptr)
            else
                rwm.river_seat_v1.focus_window(seat.ptr,state.top_window.ptr)
            end
        end

        rwm.river_window_manager_v1.manage_finish(state.window_manager_ptr)
    end,
    render_start=function()
        for _,window in pairs(state.windows) do
            if window.x and window.y then
                --TODO: relativize to main_output
                rwm.river_node_v1.set_position(window.node,window.x,window.y)
            end
            if window.width and window.height then
                rwm.river_window_v1.set_clip_box(window.ptr,0,0,window.width,window.height)
            end

            if window.hide then
                rwm.river_window_v1.hide(window.ptr)
            else
                rwm.river_window_v1.show(window.ptr)
            end
        end

        rwm.river_window_manager_v1.render_finish(state.window_manager_ptr)
    end,
    window=function(_,_,window_ptr)
        local window={
            ptr=window_ptr,
            node=rwm.river_window_v1.get_node(window_ptr),
        }
        local id=add(state.windows,window)
        rwm.river_window_v1.add_listener(window_ptr,window_listener,id)
    end,
    output=function(_,_,output_ptr)
        local output={
            ptr=output_ptr,
        }
        local id=add(state.outputs,output)
        rwm.river_output_v1.add_listener(output_ptr,output_listener,id)
    end,
    seat=function(_,_,seat_ptr)
        local seat={
            ptr=seat_ptr,
        }
        local id=add(state.seats,seat)
        rwm.river_seat_v1.add_listener(seat_ptr,seat_listener,id)
    end,
}})

local window_manager_v1
local registry_listener=ffi.new('struct wl_registry_listener[1]',{{
    global_remove=noop,
    global=function(_,registry,name,interface,version)
        if ffi.string(interface)==ffi.string(rwm.river_window_manager_v1.interface.name)
            and version>=4 then
            window_manager_v1=wcp.wl_registry.bind(registry,name,rwm.river_window_manager_v1.interface_ptr,4)
        end
    end,
}})

local function wm_step()
    local display=get_display()
    if not display then return true end
    win_update_all()
    if wayland.wl_display_prepare_read(display)~=-1 then
        if wayland.wl_display_flush(display)==-1 then
            wayland.wl_display_cancel_read(display)
            error'flush failed'
        end
        if wayland.wl_display_read_events(display)==-1 then
            error'read failed'
        end
    end
    if wayland.wl_display_dispatch_pending(display)<0 then
        error'dispatch failed'
    end
end

local function wm_start()
    if state then return true end
    local display=wayland.wl_display_connect(nil)
    if display==nil then error('river-wayland failed to connect') end
    local registry=wcp.wl_display.get_registry(display)
    window_manager_v1=nil
    wcp.wl_registry.add_listener(registry,registry_listener,nil)
    if wayland.wl_display_roundtrip(display)<0 then
        error'roundtrip failed'
    end
    if window_manager_v1==nil then
        error('interface river_window_manager_v1 not implemented by wayland server')
    end

    rwm.river_window_manager_v1.add_listener(window_manager_v1,wm_listener,nil)

    state={
        display=display,
        windows={},
        seats={},
        outputs={},
        window_manager_ptr=window_manager_v1,
    }
end

function M.start()
    wm_start()
    local function t()
        if wm_step() then
            return
        end
        vim.defer_fn(t,1)
    end
    t()
end

return M
