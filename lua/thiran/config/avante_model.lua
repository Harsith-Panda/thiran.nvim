-- The chat header learns the model from the Cursor agent after that process
-- starts. The same choice is already in Cursor's local config, so the header
-- can show it on the first paint and replace it when the live session answers.

local M = {}

local memory = {}

local function read_json(path)
  if vim.fn.filereadable(path) == 0 then
    return
  end
  local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
  if ok and type(data) == "table" then
    return data
  end
end

local function variant_from_cli(data)
  local selected = data.selectedModel
  if type(selected) ~= "table" or type(selected.modelId) ~= "string" or selected.modelId == "" then
    return
  end
  local params = {}
  if type(selected.parameters) == "table" then
    for _, param in ipairs(selected.parameters) do
      if type(param) == "table" and param.id and param.value ~= nil then
        table.insert(params, tostring(param.id) .. "=" .. tostring(param.value))
      end
    end
  end
  if #params == 0 then
    return selected.modelId
  end
  return selected.modelId .. "[" .. table.concat(params, ",") .. "]"
end

local function from_disk()
  local acp = read_json(vim.fs.normalize("~/.cursor/acp-config.json"))
  local model = acp and acp.selectedModelVariantId
  if type(model) ~= "string" or model == "" then
    local cli = read_json(vim.fs.normalize("~/.cursor/cli-config.json"))
    model = cli and variant_from_cli(cli)
  end
  local saved = read_json(vim.fn.stdpath("cache") .. "/thiran-avante-model.json")
  if type(model) ~= "string" or model == "" then
    model = saved and saved.model
  end
  if type(model) ~= "string" or model == "" then
    return
  end
  local mode = saved and saved.mode
  if type(mode) ~= "string" or mode == "" then
    mode = "agent"
  end
  return model, mode
end

function M.current()
  local stamp = 0
  local path = vim.fs.normalize("~/.cursor/acp-config.json")
  local stat = vim.uv.fs_stat(path)
  if stat then
    stamp = stat.mtime.sec
  end
  if memory.model and memory.stamp == stamp then
    return memory.model, memory.mode
  end
  local model, mode = from_disk()
  if not model then
    return memory.model, memory.mode
  end
  memory.model = model
  memory.mode = mode
  memory.stamp = stamp
  return model, mode
end

function M.remember(model, mode)
  if type(model) ~= "string" or model == "" then
    return
  end
  memory.model = model
  memory.mode = (type(mode) == "string" and mode ~= "") and mode or (memory.mode or "agent")
  memory.stamp = nil
  local path = vim.fn.stdpath("cache") .. "/thiran-avante-model.json"
  pcall(vim.fn.writefile, { vim.json.encode({ model = memory.model, mode = memory.mode }) }, path)
end

local function live_choice(sidebar)
  local options = sidebar.acp_client and sidebar.acp_client.config_options
  if type(options) ~= "table" then
    return
  end
  local model, mode
  for _, opt in ipairs(options) do
    if type(opt) == "table" and type(opt.currentValue) == "string" and opt.currentValue ~= "" then
      if opt.category == "model" then
        model = opt.currentValue
      elseif opt.category == "mode" then
        mode = opt.currentValue
      end
    end
  end
  if model then
    return model, mode
  end
end

local function show_cached(winid, model, mode)
  local Utils = require("avante.utils")
  local label = "cursor | " .. (mode or "agent") .. " | " .. model
  local function segment(text, highlight)
    return "%#" .. highlight .. "#" .. text
  end
  local pill = segment(Utils.icon("", "『"), "AvanteReversedTitle")
    .. segment(label, "AvanteTitle")
    .. segment(Utils.icon("", "』"), "AvanteReversedTitle")
  local winbar = pill .. "%=" .. segment("", "AvanteSidebarWinHorizontalSeparator")
  if vim.api.nvim_win_is_valid(winid) then
    vim.api.nvim_set_option_value("winbar", winbar, { win = winid })
  end
end

function M.install()
  local Sidebar = require("avante.sidebar")
  if Sidebar._thiran_model_header then
    return
  end
  Sidebar._thiran_model_header = true
  local render_header = Sidebar.render_header
  function Sidebar:render_header(winid, bufnr, header_text, hl, reverse_hl, opts)
    local model, mode = live_choice(self)
    if model then
      M.remember(model, mode)
    end
    render_header(self, winid, bufnr, header_text, hl, reverse_hl, opts)
    if model or not (opts and opts.include_model) then
      return
    end
    model, mode = M.current()
    if model then
      show_cached(winid, model, mode)
    end
  end
end

return M
