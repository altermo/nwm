# BUGS to fix
+ In neovim-qt, it just doesn't work
# REFACTORING
+ Add type hints
+ Only remove x-window-buffer when x-window is closed
    + When `:bdelete` is run on the x-window-buffer, then don't delete the buffer, but send a delete-x-window request to the x-window
    + When `:bdelete!` is run on the x-window-buffer, then xkill the x-window (or first try sending a request, and if that doesn't work, then xkill the x-window (or prompt the user whether to xkill the x-window))
# FEATURES
+ Using neovim's UI protocol make it so that floating windows and pop-up menus appear above x-windows (or below depending on z-indices).
+ Display(mirror) the x-window in multiple vim-windows at once.
+ Instead of using config to create mappings, create a function which can create mappings.
+ Be able to create global mappings.
+ Detect terminal padding
+ Detect if other window managers are running
    + Have an `autostart` option to autostart if no window manager is running
+ Statusline systray (or some other way to implement systrays)
+ Set minimal size for windows which ask for it (using `winheight`/`winwidth`)
+ Create an API for easier scripting
+ When x-window is floating, open it in vim-window floating window
+ Support mouse grab for vim-windows containing x-windows (for drag/resize (floating))
+ Support fullscreen windows
+ Support window borders
+ Use customisation for x-window-buffer name
    + Live change x-window-buffer name depending on x-window name
+ Multi screen support
# META
+ Look into recreating the plugin in Wayland
