# layout-switch.nvim

Neovim plugin for macOS. Switches the keyboard layout to the default one when
leaving Insert mode and restores the previous layout when entering it again.

## Requirements

- macOS
- Neovim built with LuaJIT (`:lua print(jit and jit.version)`)

No external tools are required.

Tested only on Apple Silicon: macOS 27.0, Neovim 0.11.0. Only keyboard layouts
were tested, input methods (e.g. Chinese, Japanese) were not.

## Installation

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "newrlan/layout-switch.nvim",
  lazy = false,
  opts = {},
}
```

## Behaviour

| Event         | Action                                                          |
|---------------|-----------------------------------------------------------------|
| `setup()`     | switch to the default layout                                    |
| `InsertLeave` | remember the current layout for the tab page, switch to default |
| `InsertEnter` | restore the layout remembered for the tab page                  |
| `FocusLost`   | remember the current layout                                     |
| `FocusGained` | restore the layout remembered on `FocusLost`                    |

## Options

Defaults:

```lua
{
  -- Input source ID used outside of Insert mode, e.g. "com.apple.keylayout.ABC".
  -- nil: the current ASCII-capable layout, or the last used one.
  default = nil,
  -- Remember layout on InsertLeave, restore it on InsertEnter.
  restore_insert = true,
  -- Remember layout on FocusLost, restore it on FocusGained.
  restore_focus = true,
}
```

Enabled layout IDs:

```vim
:lua print(vim.inspect(require("layout-switch").list()))
```

## API

```lua
local layout = require("layout-switch")

layout.get()          -- current input source ID
layout.set(id)        -- select input source, false if it was not selected
layout.get_default()  -- default input source ID
layout.set_default()  -- select the default input source
layout.list()         -- IDs of enabled keyboard input sources
```

Example: switch to the default layout inside a snippet and restore it after.

```lua
local saved = layout.get()
layout.set_default()
-- ...
layout.set(saved)
```

## Health check

```vim
:checkhealth layout-switch
```

Checks LuaJIT, the Text Input Sources API, enabled input sources, the default
input source and whether `setup()` is called.

## Documentation

```vim
:help layout-switch
```

## License

[MIT](LICENSE)
