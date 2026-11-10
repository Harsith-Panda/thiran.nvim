-- Edit and run .ipynb notebooks.
-- Turn this off in lua/thiran/config/notebooks.lua.
local notebooks = require("thiran.config.notebooks")

local function notebook_buffer(bufnr)
	return vim.api.nvim_buf_get_name(bufnr):match("%.ipynb$") ~= nil
end

-- A percent cell starts with `# %%`. A tag such as `[markdown]` sets the
-- header. Anything else is code.
local function cell_kind(line)
	if not line:match("^# %%%%") then
		return nil
	end
	local tagged = line:match("%[([%w-]+)%]")
	if tagged then
		return tagged:lower()
	end
	return "python"
end

-- Inner lines of the cell under the cursor: after its marker, through the
-- line before the next marker.
local function cell_bounds(bufnr, cursor_line)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local current
	local next_marker
	for i, line in ipairs(lines) do
		if cell_kind(line) then
			if i <= cursor_line then
				current = i
				next_marker = nil
			elseif current and not next_marker then
				next_marker = i
			end
		end
	end
	if not current then
		return
	end
	local last = next_marker and next_marker - 1 or #lines
	local first = current + 1
	if first > last then
		return
	end
	return first, last
end

-- Molten's own run helper evaluates one line past the cell. That lands the
-- output on the next `# %%` line, which this config hides, so the result
-- never shows. Stop on the last content line and pass its real end column
-- so the final character of the code is still executed.
local function evaluate_cell(bufnr, first, last)
	local last_line = vim.api.nvim_buf_get_lines(bufnr, last - 1, last, false)[1] or ""
	local end_col = math.max(#last_line, 0) + 1
	pcall(vim.fn.MoltenEvaluateRange, first, last, 1, end_col)
end

local function when_kernel_ready(fn)
	local ok, status = pcall(vim.fn.MoltenStatusLineInit)
	if ok and status == "Molten" then
		fn()
		return
	end
	vim.api.nvim_create_autocmd("User", {
		pattern = "MoltenKernelReady",
		once = true,
		callback = function()
			vim.schedule(fn)
		end,
	})
	notebooks.register_conda_kernels(true)
	vim.cmd("MoltenInit")
end

local function map_notebook(bufnr)
	if not notebook_buffer(bufnr) then
		return
	end

	local function map(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
	end

	local nn = require("notebook-navigator")
	map("n", "]j", function()
		nn.move_cell("d")
	end, "Notebook: Next cell")
	map("n", "[j", function()
		nn.move_cell("u")
	end, "Notebook: Previous cell")
	map("n", "<leader>jr", function()
		local first, last = cell_bounds(bufnr, vim.api.nvim_win_get_cursor(0)[1])
		if not first then
			return
		end
		when_kernel_ready(function()
			evaluate_cell(bufnr, first, last)
		end)
	end, "Notebook: Run cell")
	map("n", "<leader>jR", function()
		local first, last = cell_bounds(bufnr, vim.api.nvim_win_get_cursor(0)[1])
		if not first then
			return
		end
		when_kernel_ready(function()
			evaluate_cell(bufnr, first, last)
			nn.move_cell("d")
		end)
	end, "Notebook: Run cell and move")
	map("n", "<leader>ja", function()
		when_kernel_ready(function()
			nn.run_all_cells()
		end)
	end, "Notebook: Run all cells")
	map("n", "<leader>jb", function()
		when_kernel_ready(function()
			nn.run_cells_below()
		end)
	end, "Notebook: Run cells below")
	map("n", "<leader>jo", function()
		nn.add_cell_below()
	end, "Notebook: Add cell below")
	map("n", "<leader>jO", function()
		nn.add_cell_above()
	end, "Notebook: Add cell above")

	map("n", "<localleader>i", function()
		-- Refresh Conda environments so a new one shows up in the list.
		notebooks.register_conda_kernels(true)
		vim.cmd("MoltenInit")
	end, "Notebook: Pick kernel")
	map("n", "<localleader>rr", "<cmd>MoltenReevaluateCell<cr>", "Notebook: Re-run cell")
	map("n", "<localleader>ri", "<cmd>MoltenInterrupt<cr>", "Notebook: Interrupt kernel")
	map("n", "<localleader>rd", "<cmd>MoltenDelete<cr>", "Notebook: Clear output")
	map("n", "<localleader>os", "<cmd>noautocmd MoltenEnterOutput<cr>", "Notebook: Enter output")
	map("n", "<localleader>oh", "<cmd>MoltenHideOutput<cr>", "Notebook: Hide output")
	map("v", "<localleader>r", ":<C-u>MoltenEvaluateVisual<CR>gv", "Notebook: Run selection")
end

---@type LazySpec
return {
	{
		"benlubas/molten-nvim",
		enabled = notebooks.enabled,
		version = "^1.0.0",
		-- Remote plugins are registered at startup.
		lazy = false,
		build = ":UpdateRemotePlugins",
		init = function()
			-- Text output stays under the cell. Plots need an image provider,
			-- which is left off so this works in any terminal.
			vim.g.molten_image_provider = "none"
			vim.g.molten_auto_open_output = false
			vim.g.molten_wrap_output = true
			vim.g.molten_virt_text_output = true
			vim.g.molten_virt_lines_off_by_1 = false
			-- Long prints stay under the cell instead of stopping at a dozen lines.
			vim.g.molten_virt_text_max_lines = 40
			vim.g.molten_output_win_max_height = 20
			-- The output window, opened with \os, is a rounded box.
			vim.g.molten_output_win_border = "rounded"
			vim.g.molten_use_border_highlights = true
		end,
	},
	{
		"goerz/jupytext.nvim",
		enabled = notebooks.enabled,
		version = "0.2.0",
		-- Has to hook BufReadCmd before a notebook is opened.
		lazy = false,
		init = function()
			-- The plugin's own check runs `jupytext` from PATH and throws when
			-- that binary is absent. The notebook host installs it in its venv.
			package.preload["jupytext.health"] = function()
				return {
					check = function()
						vim.health.start("jupytext.nvim")
						local cmd = notebooks.jupytext_cmd()
						if vim.fn.executable(cmd) ~= 1 then
							vim.health.error(
								"Jupytext is not available",
								"Restart Neovim so the notebook Python host can install it."
							)
							return
						end
						local ok, proc = pcall(vim.system, { cmd, "--version" })
						if not ok then
							vim.health.error("Jupytext is not available", tostring(proc))
							return
						end
						proc = proc:wait()
						local version = ((proc.stdout or "") .. (proc.stderr or "")):gsub("%s+$", "")
						if proc.code == 0 then
							vim.health.ok(version ~= "" and version or "jupytext is available")
						else
							vim.health.error("Jupytext is not available", version)
						end
					end,
				}
			end
		end,
		opts = function()
			return {
				-- Percent scripts are real Python, so treesitter, Ruff, and the
				-- debugger apply. Existing notebook outputs are kept on save.
				format = "py:percent",
				jupytext = notebooks.jupytext_cmd(),
			}
		end,
	},
	{
		"GCBallesteros/NotebookNavigator.nvim",
		enabled = notebooks.enabled,
		lazy = false,
		dependencies = { "benlubas/molten-nvim" },
		opts = {
			repl_provider = "molten",
			-- Highlight `# %%` without another plugin.
			syntax_highlight = true,
		},
		config = function(_, opts)
			require("notebook-navigator").setup(opts)

			local cell_ns = vim.api.nvim_create_namespace("thiran_notebook_cells")
			local draw_pending = {}

			local function setup_highlights()
				vim.api.nvim_set_hl(0, "ThiranNotebookBorder", { link = "FloatBorder" })
				vim.api.nvim_set_hl(0, "ThiranNotebookLabel", { link = "Title" })
				-- Molten's default is Comment, which disappears on a dark theme.
				vim.api.nvim_set_hl(0, "MoltenVirtualText", { link = "Normal" })
			end

			local function window_for(bufnr)
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					if vim.api.nvim_win_get_buf(win) == bufnr then
						return win
					end
				end
			end

			-- How many leading bytes of a markdown line are the Jupytext comment
			-- wrapper (`# `). The markdown itself stays. Code cells are left
			-- alone, so a Python comment keeps its hash.
			local function markdown_wrapper(line)
				if line:sub(1, 2) == "# " then
					return 2
				end
				if line == "#" then
					return 1
				end
			end

			-- Closed cell: header, a left and right rule, padding inside, and a
			-- footer. The `# %%` marker is removed from the screen. Side rules
			-- are inline text, not virtual lines, so Molten can still draw the
			-- result under the last line of the cell.
			local function draw_cells(bufnr)
				if not vim.api.nvim_buf_is_valid(bufnr) or not notebook_buffer(bufnr) then
					return
				end
				local win = window_for(bufnr)
				if not win then
					return
				end

				setup_highlights()
				vim.wo[win].conceallevel = 2
				-- Keep the wrapper hidden while reading. Insert mode shows it.
				vim.wo[win].concealcursor = "nc"
				vim.api.nvim_buf_clear_namespace(bufnr, cell_ns, 0, -1)

				local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
				local markers = {}
				for i, line in ipairs(lines) do
					local kind = cell_kind(line)
					if kind then
						table.insert(markers, { line = i, kind = kind })
					end
				end

				local info = vim.fn.getwininfo(win)[1]
				local width = math.max(24, info.width - info.textoff)
				local gutter = "│ "
				for index, marker in ipairs(markers) do
					local last = index < #markers and markers[index + 1].line - 1 or #lines
					local dashes = math.max(2, width - #marker.kind - 5)
					local top = {
						{ "╭─ ", "ThiranNotebookBorder" },
						{ marker.kind, "ThiranNotebookLabel" },
						{ " " .. string.rep("─", dashes) .. "╮", "ThiranNotebookBorder" },
					}
					local bottom = {
						{ "╰" .. string.rep("─", width - 2) .. "╯", "ThiranNotebookBorder" },
					}

					local first = marker.line + 1
					if first > last then
						local marker_line = lines[marker.line] or ""
						vim.api.nvim_buf_set_extmark(bufnr, cell_ns, marker.line - 1, 0, {
							end_col = #marker_line,
							conceal = "",
							virt_lines = { top, bottom },
							virt_lines_above = true,
						})
					else
						-- Hide the marker completely. Do not hang virtual lines
						-- on it: a hidden line hides those too, and that was
						-- swallowing cell output.
						vim.api.nvim_buf_set_extmark(bufnr, cell_ns, marker.line - 1, 0, {
							end_row = marker.line - 1,
							conceal_lines = "",
						})
						vim.api.nvim_buf_set_extmark(bufnr, cell_ns, first - 1, 0, {
							virt_lines = { top },
							virt_lines_above = true,
						})
						vim.api.nvim_buf_set_extmark(bufnr, cell_ns, last - 1, 0, {
							virt_lines = { bottom },
						})

						for row = first, last do
							local line = lines[row] or ""
							local opts = {
								virt_text = { { gutter, "ThiranNotebookBorder" } },
								virt_text_pos = "inline",
								hl_mode = "combine",
							}
							if marker.kind == "markdown" then
								local hidden = markdown_wrapper(line)
								if hidden then
									opts.end_col = hidden
									opts.conceal = ""
								end
							end
							vim.api.nvim_buf_set_extmark(bufnr, cell_ns, row - 1, 0, opts)
							vim.api.nvim_buf_set_extmark(bufnr, cell_ns, row - 1, 0, {
								virt_text = { { " │", "ThiranNotebookBorder" } },
								virt_text_pos = "right_align",
								hl_mode = "combine",
							})
						end
					end
				end
			end

			local function schedule_draw(bufnr)
				if draw_pending[bufnr] then
					return
				end
				draw_pending[bufnr] = true
				vim.defer_fn(function()
					draw_pending[bufnr] = nil
					pcall(draw_cells, bufnr)
				end, 40)
			end

			local group = vim.api.nvim_create_augroup("thiran_notebooks", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI", "WinResized" }, {
				group = group,
				callback = function(event)
					local bufnr = event.buf
					if event.event == "WinResized" then
						bufnr = vim.api.nvim_get_current_buf()
					end
					if not notebook_buffer(bufnr) then
						return
					end
					if event.event == "BufEnter" then
						map_notebook(bufnr)
						vim.schedule(function()
							notebooks.register_conda_kernels()
						end)
					end
					schedule_draw(bufnr)
				end,
			})

			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()
					local ok, wk = pcall(require, "which-key")
					if ok then
						wk.add({ { "<leader>j", group = "Notebook" } })
					end
				end,
			})
		end,
	},
}
