-- Plan usage under the Avante prompt.
--
-- This uses the same login Pi and OpenCode use: the shared fetch script,
-- then ~/.pi/agent/auth.json, then the cursor-access-token keychain item.
-- It does not read the Cursor app's sealed login, so the app does not have
-- to be running.

local M = {}

local CACHE_SECONDS = 60

M.plain = "Cursor Models: … · Other Models: …"

local fetched_at = 0
local inflight = false
local ns = vim.api.nvim_create_namespace("thiran_cursor_usage")

local function rounded_percent(value)
  local number = tonumber(value)
  if not number then
    return nil
  end
  if number < 0 then
    number = 0
  end
  return string.format("%d%%", math.floor(number + 0.5))
end

function M.label_from(body)
  if type(body) ~= "table" or body.error then
    return nil
  end
  local plan = body.planUsage
  if type(plan) ~= "table" then
    plan = {}
  end
  local cursor_pct = rounded_percent(body.autoPercent or plan.autoPercentUsed)
  local other_pct = rounded_percent(body.apiPercent or plan.apiPercentUsed)
  if cursor_pct and other_pct then
    return string.format("Cursor Models: %s used · Other Models: %s used", cursor_pct, other_pct)
  end
  if type(body.text) == "string" and body.text ~= "" and body.text ~= "Cursor …" then
    return body.text
  end
end

local function paint(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  if vim.bo[bufnr].filetype ~= "AvanteInput" then
    return
  end
  -- Keep the typing area clear. The usage sits on this window's bottom bar.
  pcall(vim.api.nvim_buf_clear_namespace, bufnr, ns, 0, -1)
  local text = (M.plain or ""):gsub("%%", "%%%%")
  local statusline = "%#ThiranCursorUsage# ↻ " .. text
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_set_option_value("statusline", statusline, { win = win })
    end
  end
end

local function paint_all()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == "AvanteInput" then
      paint(bufnr)
    end
  end
end

local function finish(label, remember)
  inflight = false
  if label and label ~= "" then
    M.plain = label
    if remember then
      fetched_at = os.time()
    end
  end
  paint_all()
end

local function decode_json(text)
  local ok, body = pcall(vim.json.decode, text)
  if ok and type(body) == "table" then
    return body
  end
end

local function fetch_script()
  local path = vim.fs.normalize("~/.local/share/cursor-usage/fetch.mjs")
  if vim.fn.filereadable(path) == 1 and vim.fn.executable("node") == 1 then
    return path
  end
end

local function read_pi_token()
  local path = vim.fs.normalize("~/.pi/agent/auth.json")
  if vim.fn.filereadable(path) == 0 then
    return
  end
  local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
  if not ok or type(data) ~= "table" or type(data.cursor) ~= "table" then
    return
  end
  local access = data.cursor.access
  if type(access) == "string" and access ~= "" then
    return access
  end
end

local function request_usage(token, callback)
  local bearer = token:gsub("\\", "\\\\"):gsub('"', '\\"')
  local config = table.concat({
    "silent",
    "show-error",
    "max-time = 15",
    "request = POST",
    'url = "https://api2.cursor.sh/aiserver.v1.DashboardService/GetCurrentPeriodUsage"',
    'data = "{}"',
    'header = "Authorization: Bearer ' .. bearer .. '"',
    'header = "Content-Type: application/json"',
    'write-out = "HTTPSTATUS:%{http_code}"',
  }, "\n")
  vim.system({ "curl", "--config", "-" }, {
    stdin = config,
    text = true,
  }, function(result)
    vim.schedule(function()
      local stdout = result.stdout or ""
      local payload = stdout:gsub("HTTPSTATUS:%d+%s*$", "")
      callback(M.label_from(decode_json(payload)))
    end)
  end)
end

local function from_script(force, callback)
  local script = fetch_script()
  if not script then
    callback(nil)
    return
  end
  local args = { "node", script, "--json" }
  if force then
    table.insert(args, "--force")
  end
  vim.system(args, { text = true }, function(result)
    vim.schedule(function()
      local line = (result.stdout or ""):match("\n(%b{})$") or (result.stdout or ""):match("(%b{})$")
      callback(M.label_from(decode_json(line or "")))
    end)
  end)
end

local function from_agent_login(callback)
  local token = read_pi_token()
  if token then
    request_usage(token, callback)
    return
  end
  if vim.fn.executable("security") == 0 then
    callback(nil)
    return
  end
  vim.system({
    "security",
    "find-generic-password",
    "-s",
    "cursor-access-token",
    "-w",
  }, { text = true }, function(result)
    vim.schedule(function()
      local keychain = (result.stdout or ""):gsub("%s+$", "")
      if result.code ~= 0 or keychain == "" then
        callback(nil)
        return
      end
      request_usage(keychain, callback)
    end)
  end)
end

function M.refresh(force)
  if inflight then
    return
  end
  if not force and fetched_at > 0 and (os.time() - fetched_at) < CACHE_SECONDS then
    paint_all()
    return
  end
  paint_all()
  inflight = true
  from_script(force, function(label)
    if label then
      finish(label, true)
      return
    end
    from_agent_login(function(agent_label)
      if agent_label then
        finish(agent_label, true)
      else
        finish("Cursor usage unavailable")
      end
    end)
  end)
end

function M.attach()
  vim.api.nvim_set_hl(0, "ThiranCursorUsage", { link = "Comment", default = true })
  local group = vim.api.nvim_create_augroup("thiran_cursor_usage", { clear = true })
  vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "WinEnter" }, {
    group = group,
    callback = function(ev)
      if vim.bo[ev.buf].filetype ~= "AvanteInput" then
        return
      end
      paint(ev.buf)
      if ev.event == "FileType" or ev.event == "BufWinEnter" then
        M.refresh(false)
      end
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "AvanteInputSubmitted",
    callback = function()
      vim.defer_fn(function()
        M.refresh(true)
      end, 1500)
    end,
  })
  local timer = vim.uv.new_timer()
  if timer then
    timer:start(CACHE_SECONDS * 1000, CACHE_SECONDS * 1000, vim.schedule_wrap(function()
      M.refresh(true)
    end))
  end
end

return M
