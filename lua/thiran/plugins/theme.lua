local choice = require("thiran.config.theme")

local function statusline()
	local sections = {
		lualine_a = {
			{
				"mode",
				fmt = function(mode)
					return mode:lower()
				end,
			},
		},
		lualine_b = {
			{
				"branch",
				-- The section color would square this chip off. The arrow has to
				-- live on the component so it keeps the git background.
				separator = { right = "" },
				color = function()
					return require("thiran.theme").git_status_color()
				end,
			},
		},
		lualine_c = {
			{
				"diff",
				symbols = { added = "+", modified = "~", removed = "-" },
			},
			{
				"diagnostics",
				sources = { "nvim_diagnostic" },
				colored = true,
				diagnostics_color = {
					error = "DiagnosticError",
					warn = "DiagnosticWarn",
					info = "DiagnosticInfo",
					hint = "DiagnosticHint",
				},
				symbols = {
					error = "󰅚 ",
					warn = "󰀪 ",
					info = "󰋽 ",
					hint = "󰌶 ",
				},
			},
			{
				"filename",
				path = 0,
				symbols = {
					modified = "[+]",
					readonly = "[-]",
					unnamed = "[No Name]",
				},
				fmt = function(name)
					return (name:gsub(" %[%+%]", "[+]"):gsub(" %[%-]", "[-]"))
				end,
			},
		},
		lualine_x = { "filetype" },
		lualine_y = { "progress", "location" },
		lualine_z = {
			{
				function()
					return "thiran"
				end,
				padding = { left = 1, right = 1 },
				color = function()
					if vim.g.colors_name ~= "thiran" then
						return require("thiran.theme").lualine_section("z")
					end
					local p = require("thiran.theme.palette")
					return { fg = p.ink, bg = p.accent, gui = "bold" }
				end,
			},
		},
	}
	return {
		options = {
			theme = "auto",
			-- Per window, so the Avante prompt keeps the Cursor usage line.
			globalstatus = false,
			component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
			disabled_filetypes = {
				statusline = { "dashboard", "alpha" },
			},
		},
		extensions = {
			{
				filetypes = { "neo-tree", "oil" },
				sections = {
					lualine_a = {
						{
							function()
								local dir = vim.fn.getcwd()
								if vim.bo.filetype == "oil" then
									local ok, oil = pcall(require, "oil")
									if ok then
										dir = oil.get_current_dir() or dir
									end
								end
								return vim.fn.fnamemodify(dir, ":~")
							end,
							padding = { left = 1, right = 1 },
							separator = { right = "" },
							color = function()
								if vim.g.colors_name ~= "thiran" then
									return require("thiran.theme").lualine_section("a")
								end
								local p = require("thiran.theme.palette")
								return { fg = p.ink, bg = p.accent, gui = "bold" }
							end,
						},
					},
				},
			},
			"lazy",
			"mason",
			"fugitive",
			"nvim-dap-ui",
			"quickfix",
			{
				filetypes = { "AvanteInput" },
				sections = {
					lualine_a = {
						function()
							return "ask"
						end,
					},
					lualine_c = {
						{
							function()
								local text = require("thiran.config.cursor_usage").plain or ""
								return ("↻ " .. text):gsub("%%", "%%%%")
							end,
							color = "ThiranCursorUsage",
						},
					},
				},
			},
			-- The chat buffer is markdown.Avante. The stock extension matches
			-- the Avante suffix, then compares the full name and returns nil.
			{
				filetypes = {
					"Avante",
					"AvanteSelectedCode",
					"AvanteSelectedFiles",
					"AvanteTodos",
					"AvanteConfirm",
					"AvantePromptInput",
				},
				sections = {
					lualine_a = {
						function()
							local ft = vim.bo.filetype
							if ft == "AvanteSelectedCode" then
								return "code"
							elseif ft == "AvanteSelectedFiles" then
								return "files"
							elseif ft == "AvanteTodos" then
								return "todos"
							elseif ft == "AvanteConfirm" then
								return "confirm"
							elseif ft == "AvantePromptInput" then
								return "ask"
							end
							return "chat"
						end,
					},
				},
			},
		},
		sections = sections,
		inactive_sections = vim.deepcopy(sections),
	}
end

return {
	{
		"nvim-tree/nvim-web-devicons",
		config = function()
			require("nvim-web-devicons").setup({ default = true, color_icons = true })
			if vim.g.colors_name == "thiran" then
				require("thiran.theme").icons()
			end
		end,
	},
	{
		"nvim-lualine/lualine.nvim",
		lazy = false,
		priority = 1000,
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = statusline,
		config = function(_, opts)
			local theme = require("thiran.theme")
			theme.chrome()
			theme.install_hooks()
			if choice.colorscheme and choice.colorscheme ~= false then
				local ok, err = pcall(vim.cmd.colorscheme, choice.colorscheme)
				if not ok then
					vim.notify(
						"Colorscheme '" .. choice.colorscheme .. "' is not installed.\n" .. tostring(err),
						vim.log.levels.WARN
					)
				end
			end
			-- Devicons is already loaded, and its ColorScheme hook just restored brand colors.
			theme.icons()
			require("lualine").setup(opts)
			vim.keymap.set("n", "<leader>t", function()
				require("thiran.theme").toggle_transparency()
			end, { desc = "Toggle transparent background" })
			vim.api.nvim_create_autocmd("User", {
				group = vim.api.nvim_create_augroup("thiran_lualine_git", { clear = true }),
				pattern = "GitSignsUpdate",
				callback = function()
					require("lualine").refresh()
				end,
			})
		end,
	},
}
