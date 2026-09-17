-- Switch keyboard layout to default outside of Insert mode and restore it back.

local tis = require("layout-switch.tis")

local M = {}

---@class LayoutSwitchConfig
---@field default string|nil Input source ID outside of Insert mode, nil: ASCII-capable layout
---@field restore_insert boolean Remember layout on InsertLeave, restore on InsertEnter (per tab)
---@field restore_focus boolean Remember layout on FocusLost, restore on FocusGained
local config = {
  default = nil,
  restore_insert = true,
  restore_focus = true,
}

local insert_layout = {} -- tabpage handle -> input source ID
local focus_layout = nil

---ID of the current keyboard input source.
---@return string|nil
function M.get()
  if not tis.load() then
    return nil
  end
  return tis.current()
end

---Select input source by ID, do nothing if it is already selected.
---@param id string|nil
---@return boolean
function M.set(id)
  if id == nil or not tis.load() then
    return false
  end
  if tis.current() == id then
    return true
  end
  return tis.select(id)
end

---ID of the default input source: `default` option or ASCII-capable layout.
---@return string|nil
function M.get_default()
  if not tis.load() then
    return nil
  end
  return config.default or tis.ascii()
end

---Select the default input source.
---@return boolean
function M.set_default()
  return M.set(M.get_default())
end

---IDs of enabled keyboard input sources, candidates for `default`.
---@return string[]
function M.list()
  if not tis.load() then
    return {}
  end
  return tis.list()
end

---@param opts LayoutSwitchConfig|nil
function M.setup(opts)
  config = vim.tbl_extend("force", config, opts or {})

  local ok, err = tis.load()
  if not ok then
    vim.notify("layout-switch: disabled, " .. err, vim.log.levels.WARN)
    return
  end

  local group = vim.api.nvim_create_augroup("LayoutSwitch", { clear = true })
  local autocmd = function(event, callback)
    vim.api.nvim_create_autocmd(event, { group = group, callback = callback })
  end

  autocmd("InsertEnter", function()
    if config.restore_insert then
      M.set(insert_layout[vim.api.nvim_get_current_tabpage()])
    end
  end)

  autocmd("InsertLeave", function()
    if config.restore_insert then
      insert_layout[vim.api.nvim_get_current_tabpage()] = tis.current()
    end
    M.set_default()
  end)

  autocmd("TabClosed", function()
    for tab in pairs(insert_layout) do
      if not vim.api.nvim_tabpage_is_valid(tab) then
        insert_layout[tab] = nil
      end
    end
  end)

  if config.restore_focus then
    autocmd("FocusLost", function()
      focus_layout = tis.current()
    end)
    autocmd("FocusGained", function()
      M.set(focus_layout)
    end)
  end

  M.set_default()
end

return M
