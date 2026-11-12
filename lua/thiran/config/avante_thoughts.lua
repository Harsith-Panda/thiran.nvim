-- Thought blocks in the Avante chat start closed.
-- Press za or Enter on a thought to open or close it.

local M = {}

local open_thoughts = {}

function M.foldtext()
  return "▸ Thought    za"
end

local function quote_line(line)
  return line:match("^%s*>") ~= nil
end

local function ranges(lines)
  local found = {}
  local index = 1
  while index <= #lines do
    if lines[index]:find("Thought content", 1, true) then
      local last = index
      local cursor = index + 1
      while cursor <= #lines do
        if quote_line(lines[cursor]) then
          last = cursor
          cursor = cursor + 1
        elseif lines[cursor]:match("^%s*$") then
          local ahead = cursor + 1
          while ahead <= #lines and lines[ahead]:match("^%s*$") do
            ahead = ahead + 1
          end
          if ahead <= #lines and quote_line(lines[ahead]) then
            cursor = ahead
          else
            break
          end
        else
          break
        end
      end
      if last > index then
        table.insert(found, { index, last, lines[index] .. "\n" .. (lines[index + 1] or "") })
      end
      index = last + 1
    else
      index = index + 1
    end
  end
  return found
end

local function on_thought()
  local line = vim.fn.line(".")
  if vim.fn.foldlevel(line) == 0 then
    return false
  end
  local closed = vim.fn.foldclosed(line)
  local head = closed == -1 and line or closed
  local text = vim.api.nvim_buf_get_lines(0, head - 1, head, false)[1] or ""
  return text:find("Thought", 1, true) ~= nil
end

local function fold_buffer(bufnr)
  local wins = vim.fn.win_findbuf(bufnr)
  if #wins == 0 then
    return
  end
  local win = wins[1]
  vim.api.nvim_win_call(win, function()
    vim.wo.foldenable = true
    vim.wo.foldmethod = "manual"
    vim.wo.foldlevel = 0
    vim.wo.foldtext = "v:lua.require'thiran.config.avante_thoughts'.foldtext()"
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local blocks = ranges(lines)
    local keep_open = {}
    for _, block in ipairs(blocks) do
      if vim.fn.foldlevel(block[1]) > 0 then
        open_thoughts[block[3]] = vim.fn.foldclosed(block[1]) == -1
      end
      if open_thoughts[block[3]] then
        keep_open[block[3]] = true
      end
    end
    pcall(vim.cmd, "silent! normal! zE")
    for _, block in ipairs(blocks) do
      pcall(vim.cmd, string.format("silent! %d,%dfold", block[1], block[2]))
      if keep_open[block[3]] then
        pcall(vim.cmd, string.format("silent! %dfoldopen", block[1]))
      else
        open_thoughts[block[3]] = nil
      end
    end
  end)
  if vim.fn.maparg("<CR>", "n", false, true).desc ~= "Toggle thought" then
    vim.keymap.set("n", "<CR>", function()
      if on_thought() then
        local line = vim.fn.line(".")
        local closed = vim.fn.foldclosed(line)
        local head = closed == -1 and line or closed
        local body = vim.api.nvim_buf_get_lines(bufnr, head - 1, head + 1, false)
        local key = (body[1] or "") .. "\n" .. (body[2] or "")
        vim.cmd("normal! za")
        open_thoughts[key] = vim.fn.foldclosed(head) == -1
        return
      end
      vim.cmd("normal! j")
    end, { buffer = bufnr, silent = true, desc = "Toggle thought" })
  end
end

function M.attach()
  local group = vim.api.nvim_create_augroup("thiran_avante_thoughts", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "AvanteViewBufferUpdated",
    callback = function()
      vim.schedule(function()
        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_valid(bufnr) then
            local filetype = vim.bo[bufnr].filetype
            if filetype == "Avante" or filetype == "markdown.Avante" then
              fold_buffer(bufnr)
            end
          end
        end
      end)
    end,
  })
end

return M
