-- :checkhealth layout-switch

local M = {}

function M.check()
  vim.health.start("layout-switch")

  if jit then
    vim.health.ok("LuaJIT: " .. jit.version)
  else
    vim.health.error("Neovim is built without LuaJIT, FFI is not available")
    return
  end

  local tis = require("layout-switch.tis")
  local ok, err = tis.load()
  if not ok then
    vim.health.error("Text Input Sources API is not available: " .. tostring(err))
    return
  end
  vim.health.ok("Text Input Sources API is loaded")

  local ids = tis.list()
  if #ids == 0 then
    vim.health.warn("No enabled keyboard input sources found")
  else
    vim.health.info("Enabled keyboard input sources: " .. table.concat(ids, ", "))
  end

  local layout = require("layout-switch")
  vim.health.info("Current input source: " .. tostring(layout.get()))

  local default = layout.get_default()
  if default == nil then
    vim.health.error("Default input source is not found")
  elseif vim.tbl_contains(ids, default) then
    vim.health.ok("Default input source: " .. default)
  else
    vim.health.warn("Default input source is not enabled: " .. default, {
      "Set `default` to one of the enabled input sources",
    })
  end

  local has_group, autocmds = pcall(vim.api.nvim_get_autocmds, { group = "LayoutSwitch" })
  if has_group and #autocmds > 0 then
    vim.health.ok("setup() is called, autocommands: " .. #autocmds)
  else
    vim.health.warn("setup() is not called, layout is not switched automatically", {
      "Call require('layout-switch').setup() or use `opts = {}` with lazy.nvim",
    })
  end
end

return M
