# NXWM
**N**eovim **X**11 **W**indow **M**anager allows you to use x11 windows as if they were buffers.
When entering a x-window-buffer, you'll need to start insert-mode to focus the x-window (unless some configurations are set to do this automatically).
## Requirements
+ `libx11`
+ `libxfixes` (almost always installed if libx11 is installed)
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
{'altermo/nwm',branch='x11'},
```
- packer
```lua
use {'altermo/nwm',branch='x11'},
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
    --Whether to show float windows above x-windows (depending on z-index)
    floatover=true,
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
<!--
local terminals={
    kitty=[[kitty -c NONE -o placement_strategy=top-left -e nvim -c 'lua require("nxwm").start()']],
    alacritty=[[alacritty --config-file /dev/null -e nvim -c 'lua require("nxwm").start()']],
    wezterm=[[wezterm -n --config enable_tab_bar=false --config window_padding='{left=0,right=0,top=0,bottom=0}' start nvim -c 'lua require"nxwm".start()']]
}
local clients={
    wayland={
        'From <b>wayland</b> window manager using Xwayland',
        'Install Xwayland (may have the package name `xwayland`, `xorg-xwayland` or `xorg-x11-server-Xwayland`)',
        'Xwayland :99 -noreset&\nenv -u WAYLAND_DISPLAY DISPLAY=:99 %s\njobs -p | xargs kill',
    },
    x11={
        'From <b>X11</b> window manager using Xephyr',
        'Install Xephyr (may be installed together with `xorg-sever` or have the package name `xorg-server-xephyr`)',
        'Xephyr -ac -br -noreset :99&\nenv DISPLAY=:99 %s\njobs -p | xargs kill',
    },
    tty={
        'From <b>tty</b> using sx',
        'Install sx (most distros don\'t have it as a package so you may need to install from [source](https://github.com/Earnestly/sx))',
        'sx %s',
    }
}
local out={}
for c,i in vim.spairs(clients) do
    table.insert(out,('<details><summary>%s</summary>'):format(i[1]))
    table.insert(out,'')
    table.insert(out,i[2])
    for k,v in vim.spairs(terminals) do
        table.insert(out,('<details><summary>Using <i>%s</i></summary>'):format(k))
        table.insert(out,'')
        if c=='tty' and k=='wezterm' then --HACK
            table.insert(out,"**IMPORTANT:** Running NXWM in Wezterm started with sx sometimes doesn't work")
        end
        table.insert(out,'```bash')
        table.insert(out,'#!/bin/bash')
        vim.list_extend(out,vim.split(i[3]:format(v),'\n'))
        table.insert(out,'```')
        table.insert(out,'</details>')
    end
    table.insert(out,'')
    table.insert(out,'---')
    table.insert(out,'')
    table.insert(out,'</details>')
end
table.insert(out,38,'sleep 0.05 # HACK to make alacritty work with Xwayland') --HACK
table.insert(out,73,'sleep 0.05 # HACK to make alacritty work with Xephyr') --HACK
vim.fn.writefile(out,'/tmp/out.md')
-->
### Start
Create an executable file with the following contents (or run directly in bash):\
(click triangle to expand)

<!--tag:auto-generated-->
<details><summary>From <b>tty</b> using sx</summary>

Install sx (most distros don't have it as a package so you may need to install from [source](https://github.com/Earnestly/sx))
<details><summary>Using <i>alacritty</i></summary>

```bash
#!/bin/bash
sx alacritty --config-file /dev/null -e nvim -c 'lua require("nxwm").start()'
```
</details>
<details><summary>Using <i>kitty</i></summary>

```bash
#!/bin/bash
sx kitty -c NONE -o placement_strategy=top-left -e nvim -c 'lua require("nxwm").start()'
```
</details>
<details><summary>Using <i>wezterm</i></summary>

**IMPORTANT:** Running NXWM in Wezterm started with sx sometimes doesn't work
```bash
#!/bin/bash
sx wezterm -n --config enable_tab_bar=false --config window_padding='{left=0,right=0,top=0,bottom=0}' start nvim -c 'lua require"nxwm".start()'
```
</details>

---

</details>
<details><summary>From <b>wayland</b> window manager using Xwayland</summary>

Install Xwayland (may have the package name `xwayland`, `xorg-xwayland` or `xorg-x11-server-Xwayland`)
<details><summary>Using <i>alacritty</i></summary>

```bash
#!/bin/bash
Xwayland :99 -noreset&
sleep 0.05 # HACK to make alacritty work with Xwayland
env -u WAYLAND_DISPLAY DISPLAY=:99 alacritty --config-file /dev/null -e nvim -c 'lua require("nxwm").start()'
jobs -p | xargs kill
```
</details>
<details><summary>Using <i>kitty</i></summary>

```bash
#!/bin/bash
Xwayland :99 -noreset&
env -u WAYLAND_DISPLAY DISPLAY=:99 kitty -c NONE -o placement_strategy=top-left -e nvim -c 'lua require("nxwm").start()'
jobs -p | xargs kill
```
</details>
<details><summary>Using <i>wezterm</i></summary>

```bash
#!/bin/bash
Xwayland :99 -noreset&
env -u WAYLAND_DISPLAY DISPLAY=:99 wezterm -n --config enable_tab_bar=false --config window_padding='{left=0,right=0,top=0,bottom=0}' start nvim -c 'lua require"nxwm".start()'
jobs -p | xargs kill
```
</details>

---

</details>
<details><summary>From <b>X11</b> window manager using Xephyr</summary>

Install Xephyr (may be installed together with `xorg-sever` or have the package name `xorg-server-xephyr`)
<details><summary>Using <i>alacritty</i></summary>

```bash
#!/bin/bash
Xephyr -ac -br -noreset :99&
sleep 0.05 # HACK to make alacritty work with Xephyr
env DISPLAY=:99 alacritty --config-file /dev/null -e nvim -c 'lua require("nxwm").start()'
jobs -p | xargs kill
```
</details>
<details><summary>Using <i>kitty</i></summary>

```bash
#!/bin/bash
Xephyr -ac -br -noreset :99&
env DISPLAY=:99 kitty -c NONE -o placement_strategy=top-left -e nvim -c 'lua require("nxwm").start()'
jobs -p | xargs kill
```
</details>
<details><summary>Using <i>wezterm</i></summary>

```bash
#!/bin/bash
Xephyr -ac -br -noreset :99&
env DISPLAY=:99 wezterm -n --config enable_tab_bar=false --config window_padding='{left=0,right=0,top=0,bottom=0}' start nvim -c 'lua require"nxwm".start()'
jobs -p | xargs kill
```
</details>

---

</details>
<!--tag_end:auto-generated-->

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

