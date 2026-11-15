-- Relative numbers while a code window is focused and in normal mode.
-- Absolute numbers in insert, command, and when the window is not focused.
-- The current line number stays visible either way.
return {
	{
		"sitiom/nvim-numbertoggle",
		event = "VeryLazy",
		init = function()
			vim.opt.relativenumber = true
		end,
		config = function()
			local hidden = {
				["neo-tree"] = true,
				["lazy"] = true,
				["mason"] = true,
				["qf"] = true,
				["TelescopePrompt"] = true,
				["TelescopeResults"] = true,
				["dap-repl"] = true,
				["Avante"] = true,
				["AvanteInput"] = true,
				["AvanteSelectedCode"] = true,
				["AvanteSelectedFiles"] = true,
				["AvanteTodos"] = true,
				["AvanteConfirm"] = true,
				["AvantePromptInput"] = true,
			}

			local function hide(buf)
				local ft = vim.bo[buf].filetype
				if hidden[ft] or ft:find("Avante", 1, true) or ft:find("^dapui_", 1) then
					return true
				end
				return false
			end

			-- The plugin sets the global option on WinEnter. Sidebars turn it
			-- back off on the next tick, after that assignment.
			vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "FileType" }, {
				group = vim.api.nvim_create_augroup("thiran_number_chrome", { clear = true }),
				callback = function(args)
					local buf = args.buf
					vim.schedule(function()
						if not vim.api.nvim_buf_is_valid(buf) or not hide(buf) then
							return
						end
						for _, win in ipairs(vim.fn.win_findbuf(buf)) do
							if vim.api.nvim_win_is_valid(win) then
								vim.wo[win].number = false
								vim.wo[win].relativenumber = false
							end
						end
					end)
				end,
			})
		end,
	},
}
