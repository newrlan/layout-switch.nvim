# layout-switch.nvim

Neovim plugin for macOS. Switches the keyboard layout to the default one when
leaving Insert mode and restores the previous layout when entering it again.

Layouts are switched in-process with LuaJIT FFI calls to the Carbon Text Input
Sources API, no external helper binary is used.

## Requirements

- macOS
- Neovim built with LuaJIT (`:lua print(jit and jit.version)`)

## Installation

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  dir = "/path/to/layout-switch.nvim",
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

Insert mode and focus layouts are stored separately, so switching windows or
tabs in Normal mode does not overwrite the Insert mode layout.

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
