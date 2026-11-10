-- gc is Neovim's comment operator and gcc comments the current line.
-- which-key reads vim.health.warn once, when its health module loads.
local function install_health_filter()
	package.preload["which-key.health"] = function()
		local file
		for _, path in ipairs(vim.api.nvim_get_runtime_file("lua/which-key/health.lua", true)) do
			if path:find("/which-key.nvim/", 1, true) then
				file = path
				break
			end
		end
		if not file then
			return {
				check = function()
					vim.health.error("which-key.nvim health check was not found")
				end,
			}
		end

		local health = vim.health
		local warn = health.warn
		health.warn = function(msg, ...)
			if type(msg) == "string" and msg:find("<gc> overlaps with <gcc>", 1, true) then
				return
			end
			return warn(msg, ...)
		end
		local ok, mod = pcall(function()
			return assert(loadfile(file))()
		end)
		health.warn = warn
		if not ok then
			error(mod)
		end
		return mod
	end
end

return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = install_health_filter,
		dependencies = {
			-- File, directory, LSP, and OS icons. which-key uses this ahead of nvim-web-devicons.
			{ "nvim-mini/mini.icons", opts = {} },
		},
		opts = {},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
	},
}
