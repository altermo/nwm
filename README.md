# NXWM
**N**eovim **X**11 **W**indow **M**anager allows you to use x11 windows as if they were buffers.
When entering a x-window-buffer, you'll need to start insert-mode to focus the x-window (unless some configurations are set to do this automatically).
## Requirements
+ `libx11`
+ `glibc` (or most other standard C libraries)
+ Terminal supporting `TIOCGWINSZ`
    + Recommended terminal is `kitty`
    + Run `:lua= require'nxwm'.term_supported()` to check
        + NOTE: some terminals may support `TIOCGWINSZ` while still not working (like `neovim-qt`)
## Installation
Use whichever package manager you like.\
It is recommended to lock/pin the plugin to one version/branch because of changes.

- lazy
```lua
{'altermo/nxwm',branch='x11'},
```
- packer
```lua
use {'altermo/nxwm',branch='x11'},
```

## Configuration
Using `require("nxwm").setup({})` is **not required**, it is only there if you want to change the default config.
```lua
{
    --What happens when a new x-window is created
    on_win_open=function (buf,xwin)
        vim.cmd.vsplit()
        vim.api.nvim_set_current_buf(buf)
    end,
    --Configuration to pass to window
    --`conf` is global config
    on_win_get_conf=function (conf,xwin) return conf end,
    --How to handle when multiple windows in the same tabpage has the x-window-buffer open
    on_multiple_win_open=function (vwins,buf,xwin)
        for k,vwin in ipairs(vwins) do
            if k~=1 then
                local scratchbuf=vim.api.nvim_create_buf(false,true)
                vim.bo[scratchbuf].bufhidden='wipe'
                vim.api.nvim_win_set_buf(vwin,scratchbuf)
            end
        end
    end,
    --Whether to be more verbose
    verbal=false,
    --Map to unfocus a window (multiple key mappings is not (yet) supported)
    unfocus_map='<A-F4>',
    --Create your own mappings
    --IMPORTANT: the x-window needs to be focused for such mappings to work
    maps={
        --{'<C-A-del>',function () vim.cmd'quitall!' end},
        --Or you could also have lhs as a table
        --{{mods={'control','mod1'},key='Delete'},function () vim.cmd'quitall!' end},
    },
    --Window-opt: auto focus x-window when entering x-window-buffer
    autofocus=false,
    --Window-opt: try-delete x-window if no vim-window shows buffer (similar to `bufhidden=wipe`)
    delhidden=true,
    --Window-opt: when click on x-window, goto that buffer (may not focus x-window)
    clickgoto=true,
    --Window-opt: offset the window this many x pixels (useful if terminal has padding)
    xoffset=0,
    --Window-opt: offset the window this many y pixels (useful if terminal has padding)
    yoffset=0,
}
```
## Usage
### Start (from wayland window manager)
1. Install Xwayland.
2. Run `Xwayland :99`.
3. Run `DISPLAY=:99 WAYLAND_DISPLAY= {NXWM}` in a **terminal** where `{NXWM}` is path to a terminal which runs Neovim and starts NXWM. \
NOTE: the terminal should have it's start in the top left, have zero padding, have no title bar...\
NOTE2: some applications (like `kitty` with default config) tries (and fails) to spawn in wayland even when `WAYLAND_DISPLAY` is empty...\
Examples of how to start for specific terminals:
    + kitty: `DISPLAY=:99 WAYLAND_DISPLAY=  kitty -c NONE -o placement_strategy=top-left -o linux_display_server=x11 -e nvim -c 'lua require("nxwm").start()'`
    + alacritty: `DISPLAY=:99 WAYLAND_DISPLAY= alacritty --config-file /dev/null -e nvim -c 'lua require("nxwm").start()'`
    + wezterm: `DISPLAY=:99 WAYLAND_DISPLAY= wezterm -n --config enable_tab_bar=false --config window_padding='{left=0,right=0,top=0,bottom=0}' start nvim -c 'lua require"nxwm".start()'`

### Start (from Xephyr in x11)
  * Install `Xephyr`.
  * Run `Xephyr -ac -br -noreset :99`.
    * You may add `-screen 800x600` to set the Xephyr window size.
  * Start your terminal emulator, passing `DISPLAY=:99` to start it in the Xephyr session.
    * Wezterm example: `DISPLAY=:99 wezterm -n --config enable_tab_bar=false --config window_padding='{left=0,right=0,top=0,bottom=0}' start nvim -c 'lua require"nxwm".start()'`
### Start (from tty)
1. Install [sx](https://github.com/Earnestly/sx).
2. Run `sx {NXWM}` in a **tty** where `{NXWM}` is path to a terminal which runs Neovim and starts NXWM.\
NOTE: the terminal should have it's start in the top left, have zero padding, have no title bar...\
Examples of how to start for specific terminals:
    + kitty: `sx kitty -c NONE -o placement_strategy=top-left -e nvim -c 'lua require("nxwm").start()'`
    + alacritty: `sx alacritty --config-file /dev/null -e nvim -c 'lua require("nxwm").start()'`
    + wezterm: `sx wezterm -n --config enable_tab_bar=false --config window_padding='{left=0,right=0,top=0,bottom=0}' start nvim -c 'lua require"nxwm".start()'`
    <!--+ neovim-qt: `nvim-qt --nofork -- -c 'lua require("nxwm").start()'`-->
### Use
Open up a terminal (with `:term`) and run your wanted GUI.
NOTE: x-windows aren't auto focused by default, so start insert (by pressing `i` or similar) and then you'll focus the window.
To unfocus an x-window, either click into another buffer, or press `alt-F4`(unless the default config has been changed).
#### Donate
If you want to donate then you need to find the correct link (hint: No Break Here):
* [10]() [11]() [12]() [13]() [14]() [15]() [16]() [17]() [18]()
* [20]() [21]() [22]() [23]() [24]() [25]() [26]() [27]() [28]()
* [30]() [31]() [32]() [33]() [34]() [35]() [36]() [37]() [38]()
* [40]() [41]() [42]() [43]() [44]() [45]() [46]() [47]() [48]()
* [50]() [51]() [52]() [53]() [54]() [55]() [56]() [57]() [58]()
* [60]() [61]() [62]() [63]() [64]() [65]() [66]() [67]() [68]()
* [70]() [71]() [72]() [73]() [74]() [75]() [76]() [77]() [78]()
* [80]() [81]() [82]() [83](https://www.buymeacoffee.com/altermo) [84]() [85]() [86]() [87]() [88]()

