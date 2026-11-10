-- Mason reports every language toolchain it can install. Thiran does not
-- require these. Mason reads vim.health.warn once, when its health module loads.
local function install_health_filter()
	local skip = {
		["cargo: not available"] = true,
		["Composer: not available"] = true,
		["PHP: not available"] = true,
		["julia: not available"] = true,
	}

	package.preload["mason.health"] = function()
		local file
		for _, path in ipairs(vim.api.nvim_get_runtime_file("lua/mason/health.lua", true)) do
			if path:find("/mason.nvim/", 1, true) then
				file = path
				break
			end
		end
		if not file then
			return {
				check = function()
					vim.health.error("mason.nvim health check was not found")
				end,
			}
		end

		local health = vim.health
		local warn = health.warn
		health.warn = function(msg, ...)
			if type(msg) == "string" and skip[msg] then
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
		"mason-org/mason.nvim",
		init = install_health_filter,
		config = function()
			require("mason").setup({
				-- Silences unnecessary logs across user environments
				log_level = vim.log.levels.ERROR,

				ui = {
					-- Ensures the window uses universal border boundaries for styling
					border = "rounded",
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
		end,
	},
}
