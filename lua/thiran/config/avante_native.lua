-- Avante talks to Cursor through a compiled library, lua/avante_acp.so.
-- Neovim's module search does not look in that file, and a failed search is
-- what the chat saved as "module 'avante_acp' not found". Load the file by
-- path instead. Cursor also forgets a session when Neovim quits, so a saved
-- session id is cleared before the chat tries to resume it.

local M = {}

local searcher

local function library_path()
  return vim.fs.normalize(vim.fn.stdpath("data") .. "/lazy/avante.nvim/lua/avante_acp.so")
end

local cached

local function load_library()
  if type(cached) == "table" then
    return cached
  end
  local so = library_path()
  if vim.fn.filereadable(so) == 0 then
    return nil, "Avante ACP library is not built yet. Restart Neovim and let the Avante build finish."
  end
  local open_module, err = package.loadlib(so, "luaopen_avante_acp")
  if not open_module then
    return nil, err
  end
  local mod = open_module()
  -- Opening the same library twice can return true. Keep the real module table.
  if type(mod) ~= "table" and type(package.loaded["avante_acp"]) == "table" then
    mod = package.loaded["avante_acp"]
  end
  if type(mod) ~= "table" then
    return nil, "avante_acp did not return a module table"
  end
  cached = mod
  return mod
end

local raw_require

local function install_require()
  if raw_require then
    return
  end
  raw_require = require
  _G.require = function(name, ...)
    if name ~= "avante_acp" then
      return raw_require(name, ...)
    end
    local current = package.loaded[name]
    if type(current) == "table" then
      return current
    end
    local mod, err = load_library()
    if not mod then
      error(err, 2)
    end
    package.loaded[name] = mod
    return mod
  end
end

searcher = function(name)
  if name ~= "avante_acp" then
    return
  end
  return function()
    local mod, err = load_library()
    if not mod then
      error(err, 2)
    end
    package.loaded[name] = mod
    return mod
  end
end

local function link_search_path(so)
  local data = vim.fn.stdpath("data")
  for _, sub in ipairs({ "lib/lua/5.1", "lib64/lua/5.1" }) do
    local dest_dir = vim.fs.normalize(data .. "/lazy-rocks/avante.nvim/" .. sub)
    vim.fn.mkdir(dest_dir, "p")
    local dest = dest_dir .. "/avante_acp.so"
    if vim.uv.fs_readlink(dest) ~= so then
      if vim.uv.fs_lstat(dest) then
        vim.uv.fs_unlink(dest)
      end
      vim.uv.fs_symlink(so, dest)
    end
  end
end

local function searcher_lists()
  -- LuaJIT calls them loaders. Neovim later aliases searchers to the same table.
  if package.searchers == nil then
    package.searchers = package.loaders
  end
  if package.searchers == nil then
    return {}
  end
  if package.searchers == package.loaders or package.loaders == nil then
    return { package.searchers }
  end
  return { package.searchers, package.loaders }
end

function M.install()
  local so = library_path()
  if vim.fn.filereadable(so) == 0 then
    return false
  end
  install_require()
  for _, list in ipairs(searcher_lists()) do
    local listed = false
    for _, existing in ipairs(list) do
      if existing == searcher then
        listed = true
        break
      end
    end
    if not listed then
      table.insert(list, 1, searcher)
    end
  end
  package.preload["avante_acp"] = function()
    local mod, err = load_library()
    if not mod then
      error(err, 2)
    end
    return mod
  end
  link_search_path(so)
  if package.loaded["avante_acp"] == nil then
    local mod = load_library()
    if mod then
      package.loaded["avante_acp"] = mod
    end
  end
  return package.loaded["avante_acp"] ~= nil
end

local function saved_error(message)
  if type(message) ~= "table" then
    return false
  end
  local content = message.message and message.message.content
  if type(content) ~= "string" then
    return false
  end
  if content:find("Failed to load avante_acp native module", 1, true) then
    return true
  end
  return content:find("invalid_input", 1, true) ~= nil and content:find("not found", 1, true) ~= nil
end

-- A Cursor agent process lives only as long as this Neovim process. Any
-- session id in the history files belongs to an agent that has already exited.
function M.forget_dead_sessions()
  local root = vim.fs.joinpath(vim.fn.stdpath("state"), "avante", "projects")
  if vim.fn.isdirectory(root) == 0 then
    return
  end
  for name, kind in vim.fs.dir(root) do
    if kind == "directory" then
      local history = vim.fs.joinpath(root, name, "history")
      if vim.fn.isdirectory(history) == 1 then
        for file, file_kind in vim.fs.dir(history) do
          if file_kind == "file" and file:match("%.json$") and file ~= "metadata.json" then
            local path = vim.fs.joinpath(history, file)
            local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
            if ok and type(data) == "table" then
              local changed = false
              if data.acp_session_id ~= nil then
                data.acp_session_id = nil
                changed = true
              end
              if type(data.messages) == "table" then
                local kept = {}
                for _, message in ipairs(data.messages) do
                  if not saved_error(message) then
                    table.insert(kept, message)
                  end
                end
                if #kept ~= #data.messages then
                  data.messages = kept
                  changed = true
                end
              end
              if changed then
                local encoded_ok, encoded = pcall(vim.json.encode, data)
                if encoded_ok and type(encoded) == "string" then
                  vim.fn.writefile({ encoded }, path)
                end
              end
            end
          end
        end
      end
    end
  end
end

return M
