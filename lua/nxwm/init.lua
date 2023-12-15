local x11=require'nxwm.x11'
local M={}
M.augroup=vim.api.nvim_create_augroup('nxwm',{})
---@type table<string,{buf:number,conf:table,win:number,focus:boolean}>
M.windows={}

M.default_config={
    ---@diagnostic disable-next-line: unused-local
    on_win_open=function (buf,xwin)
        vim.cmd.vsplit()
        vim.api.nvim_set_current_buf(buf)
    end,
    ---@diagnostic disable-next-line: unused-local
    on_win_get_conf=function (conf,xwin) return conf end,
    ---@diagnostic disable-next-line: unused-local
    on_multiple_win_open=function (vwins,buf,xwin)
        for k,vwin in ipairs(vwins) do
            if k~=1 then
                local scratchbuf=vim.api.nvim_create_buf(false,true)
                vim.bo[scratchbuf].bufhidden='wipe'
                vim.api.nvim_win_set_buf(vwin,scratchbuf)
            end
        end
    end,
    verbose=false,
    unfocus_map={mods={'mod1'},key='F4'},
    maps={
        --{{mods={'control','mod1'},key='Delete'},function () vim.cmd'quitall!' end},
    },
    autofocus=false,
    delhidden=true,
    clickgoto=true,
}
M.conf=vim.deepcopy(M.default_config)
function M.setup(conf)
    M.conf=vim.tbl_deep_extend('force',M.default_config,conf)
end

function M.term_supported()
    local info=x11.term_get_info()
    return info.xpixel~=0 and info.ypixel~=0
end
function M.term_set_size()
    x11.win_position(x11.term_root,0,0,x11.screen_get_size())
end

function M.win_update_all(event)
    if event=='enter' then x11.term_focus() end
    for win,_ in pairs(M.windows) do
        M.win_update(win,event)
    end
end
function M.win_update(hash,event)
    hash=type(hash)=='string' and hash or tostring(hash)
    local opt=M.windows[hash]
    if not opt then return true end
    local win=opt.win
    if not vim.api.nvim_buf_is_valid(opt.buf) then
        M.win_del_win(win)
        return
    end
    if opt.conf.delhidden then
        if not vim.fn.win_findbuf(opt.buf)[1] then
            M.win_del(win)
            return
        end
    end
    local vwins={}
    local _repeat=0
    while true do
        for _,vwin in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.api.nvim_win_get_buf(vwin)==opt.buf then
                table.insert(vwins,vwin)
            end
        end
        if #vwins<=1 then break end
        opt.conf.on_multiple_win_open(vwins,opt.buf,win)
        vwins={}
        _repeat=_repeat+1
        if _repeat>100 then error() end
    end
    if #vwins==0 then
        x11.win_unmap(win)
        return
    end
    local vwin=vwins[1]
    x11.win_map(win)
    local terminfo=x11.term_get_info()
    local xpx=math.floor(terminfo.xpixel/vim.o.columns)
    local ypx=math.floor(terminfo.ypixel/vim.o.lines)
    local height=vim.api.nvim_win_get_height(vwin)
    local width=vim.api.nvim_win_get_width(vwin)
    local row,col=unpack(vim.api.nvim_win_get_position(vwin))
    x11.win_position(win,col*xpx,row*ypx,width*xpx,height*ypx)
    if vim.api.nvim_get_current_buf()==opt.buf then
        ---@diagnostic disable-next-line: redundant-parameter
        if opt.conf.autofocus and event=='enter'  then
            opt.focus=true
        end
        if opt.focus then
            vim.cmd.startinsert()
            x11.win_focus(win)
        else
            M.win_unfocus(win)
        end
    end
end
function M.win_init(win,conf)
    if M.windows[tostring(win)] then return end
    local opt={win=win,conf=conf.on_win_get_conf(conf,win),focus=false}
    opt.buf=vim.api.nvim_create_buf(true,true)
    vim.api.nvim_open_term(opt.buf,{})
    M.windows[tostring(win)]=opt
    vim.api.nvim_buf_set_name(opt.buf,'nxwm://'..tonumber(win))
    vim.api.nvim_create_autocmd('TermEnter',{callback=function ()
        opt.focus=true
        M.win_update(win)
    end,buffer=opt.buf})
    vim.api.nvim_create_autocmd('TermLeave',{callback=function ()
        opt.focus=false
        M.win_update(win)
    end,buffer=opt.buf})
    M.win_set_button(win,conf)
    M.win_set_keys(win,conf)
    conf.on_win_open(opt.buf,win)
end
function M.win_set_keys(win,conf)
    x11.win_set_key(win,conf.unfocus_map.key,conf.unfocus_map.mods)
    for _,map in ipairs(conf.maps) do
        x11.win_set_key(win,map[1].key,map[1].mods)
    end
end
function M.win_set_button(win,conf)
    if not conf.clickgoto then return end
    x11.win_grab_all_button(win)
end
function M.win_unfocus(win)
    local opt=M.windows[tostring(win)]
    opt.focus=false
    if vim.api.nvim_get_current_buf()==M.windows[tostring(win)].buf then
        vim.cmd.stopinsert()
        x11.term_focus()
    end
end
function M.win_del(win)
    M.win_del_buf(win)
    M.win_del_win(win)
end
function M.win_del_buf(win)
    if not M.windows[tostring(win)] then return end
    local buf=M.windows[tostring(win)].buf
    pcall(vim.api.nvim_buf_delete,buf,{force=true})
    M.windows[tostring(win)]=nil
end
function M.win_del_win(win)
    x11.win_send_del_signal(win)
end
function M.win_goto(win)
    M.win_update_all()
    local opt=M.windows[tostring(win)]
    if not opt then return end
    for _,vwin in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.api.nvim_win_get_buf(vwin)==opt.buf then
            vim.api.nvim_set_current_win(vwin)
            break
        end
    end
end

function M.key_handle(win,key,mod)
    local conf=M.windows[tostring(win)].conf
    if mod==x11.key_get_mods(conf.unfocus_map.mods) and key==x11.key_get_key(conf.unfocus_map.key) then
        M.win_unfocus(win) return
        M.win_update(win)
    end
    for _,map in ipairs(conf.maps) do
        if mod==x11.key_get_mods(map[1].mods) and key==x11.key_get_key(map[1].key) then
            map[2]() return
        end
    end
    if M.conf.verbose then
        vim.notify('key not handled '..key..' '..mod)
    end
end

function M.step()
    local ev=x11.step()
    if not ev then return end
    if ev.type=='map' then
        M.win_init(ev.win,M.conf)
    elseif ev.type=='unmap' then
        --TODO: close window
    elseif ev.type=='key' then
        M.key_handle(ev.win,ev.key,ev.mod)
    elseif ev.type=='destroy' then
        M.win_del_buf(ev.win)
    elseif ev.type=='_update' then ---HACK: see x11.lua
        M.win_update_all()
    elseif ev.type=='focus' then
        M.win_goto(ev.win)
    elseif ev.type=='other' then
        if M.conf.verbose then
            vim.notify('event not handled '..x11.code_to_name[ev.type_id],vim.log.levels.INFO)
        end
    else
        error()
    end
end

function M.start()
    x11.start()
    vim.api.nvim_create_autocmd('VimLeave',{callback=M.stop,group=M.augroup})
    vim.api.nvim_create_autocmd({'WinResized','WinNew','TermOpen','BufDelete'},{callback=function ()
        vim.schedule(M.win_update_all)
    end,group=M.augroup})
    vim.api.nvim_create_autocmd({'WinEnter','BufWinEnter','TabEnter'},{callback=function ()
        vim.schedule_wrap(M.win_update_all)('enter')
    end,group=M.augroup})
    M.term_set_size()
    local function t()
        if not x11.display then return end
        M.step()
        vim.defer_fn(t,1)
    end
    t()
end
function M.stop()
    vim.api.nvim_create_augroup('nxwm',{clear=true})
    x11.stop()
end
return M
