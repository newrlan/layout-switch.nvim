-- macOS Text Input Sources (Carbon TIS) via LuaJIT FFI.

local M = {}

local ffi
local carbon, cf
local load_error

local UTF8 = 0x08000100 -- kCFStringEncodingUTF8
local RUN_LOOP_HANDLED_SOURCE = 4 -- kCFRunLoopRunHandledSource

local CDEF = [[
typedef const void *CFTypeRef;
typedef const struct __CFString *CFStringRef;
typedef const struct __CFArray *CFArrayRef;
typedef struct __TISInputSource *TISInputSourceRef;
typedef long CFIndex;
typedef int32_t OSStatus;

TISInputSourceRef TISCopyCurrentKeyboardInputSource(void);
TISInputSourceRef TISCopyCurrentASCIICapableKeyboardLayoutInputSource(void);
CFArrayRef TISCreateInputSourceList(CFTypeRef properties, bool includeAllInstalled);
CFTypeRef TISGetInputSourceProperty(TISInputSourceRef source, CFStringRef key);
OSStatus TISSelectInputSource(TISInputSourceRef source);
extern const CFStringRef kTISPropertyInputSourceID;
extern const CFStringRef kTISPropertyInputSourceCategory;
extern const CFStringRef kTISPropertyInputSourceIsSelectCapable;
extern const CFStringRef kTISCategoryKeyboardInputSource;

CFIndex CFArrayGetCount(CFArrayRef array);
CFTypeRef CFArrayGetValueAtIndex(CFArrayRef array, CFIndex index);
bool CFStringGetCString(CFStringRef str, char *buffer, CFIndex size, uint32_t encoding);
bool CFEqual(CFTypeRef a, CFTypeRef b);
bool CFBooleanGetValue(CFTypeRef boolean);
void CFRelease(CFTypeRef cf);
extern const CFStringRef kCFRunLoopDefaultMode;
int32_t CFRunLoopRunInMode(CFStringRef mode, double seconds, bool returnAfterSourceHandled);
]]

---Load frameworks on first use.
---@return boolean ok, string|nil err
function M.load()
  if carbon then
    return true
  end
  if load_error then
    return false, load_error
  end

  local ok, err = pcall(function()
    ffi = require("ffi")
    if ffi.os ~= "OSX" then
      error("macOS is required, current OS: " .. ffi.os)
    end
    -- Types survive module reload, cdef must not run twice
    if not pcall(ffi.typeof, "TISInputSourceRef") then
      ffi.cdef(CDEF)
    end
    carbon = ffi.load("/System/Library/Frameworks/Carbon.framework/Carbon")
    cf = ffi.load("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation")
  end)
  if not ok then
    carbon, cf = nil, nil
    load_error = tostring(err)
    return false, load_error
  end
  return true
end

-- TIS caches the current input source per process and updates the cache from
-- notifications delivered through CFRunLoop. Neovim runs libuv, not CFRunLoop,
-- so without this a layout switched by the user is never seen.
local function refresh()
  for _ = 1, 16 do
    if cf.CFRunLoopRunInMode(cf.kCFRunLoopDefaultMode, 0, true) ~= RUN_LOOP_HANDLED_SOURCE then
      break
    end
  end
end

---@return string|nil
local function source_id(source)
  if source == nil then
    return nil
  end
  local value = carbon.TISGetInputSourceProperty(source, carbon.kTISPropertyInputSourceID)
  if value == nil then
    return nil
  end
  local buffer = ffi.new("char[256]")
  if not cf.CFStringGetCString(ffi.cast("CFStringRef", value), buffer, 256, UTF8) then
    return nil
  end
  return ffi.string(buffer)
end

---Take ownership of a TIS "Copy" result, return its ID.
---@return string|nil
local function copied_source_id(source)
  if source == nil then
    return nil
  end
  local id = source_id(source)
  cf.CFRelease(source)
  return id
end

---Call fn(source) for every enabled input source until it returns true.
local function each_source(fn)
  local list = carbon.TISCreateInputSourceList(nil, false)
  if list == nil then
    return
  end
  for i = 0, tonumber(cf.CFArrayGetCount(list)) - 1 do
    local source = ffi.cast("TISInputSourceRef", cf.CFArrayGetValueAtIndex(list, i))
    if fn(source) then
      break
    end
  end
  cf.CFRelease(list)
end

---ID of the current keyboard input source.
---@return string|nil
function M.current()
  refresh()
  return copied_source_id(carbon.TISCopyCurrentKeyboardInputSource())
end

---ID of the current ASCII-capable layout, or the last used one.
---@return string|nil
function M.ascii()
  refresh()
  return copied_source_id(carbon.TISCopyCurrentASCIICapableKeyboardLayoutInputSource())
end

---Select enabled input source by ID.
---@param id string
---@return boolean
function M.select(id)
  refresh()
  local selected = false
  each_source(function(source)
    if source_id(source) == id then
      selected = carbon.TISSelectInputSource(source) == 0
      return true
    end
  end)
  return selected
end

---IDs of enabled selectable keyboard input sources.
---@return string[]
function M.list()
  local ids = {}
  each_source(function(source)
    local category = carbon.TISGetInputSourceProperty(source, carbon.kTISPropertyInputSourceCategory)
    local selectable = carbon.TISGetInputSourceProperty(source, carbon.kTISPropertyInputSourceIsSelectCapable)
    if category ~= nil and cf.CFEqual(category, carbon.kTISCategoryKeyboardInputSource)
      and selectable ~= nil and cf.CFBooleanGetValue(selectable)
    then
      table.insert(ids, source_id(source))
    end
  end)
  return ids
end

return M
