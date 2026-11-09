-- Markdown notes for Thiran.
--
-- This switch controls Obsidian and render-markdown. It does not touch live
-- preview. Live preview stays installed. Delete lua/thiran/plugins/live-preview.lua
-- only if you do not want that plugin.
--
--   enabled = true   both plugins load. On startup, Neovim installs them if
--                    their folders are missing.
--   enabled = false  both plugins stay unloaded, and their install folders are
--                    deleted. Set this back to true and restart Neovim to
--                    install and enable them again.
--
-- The config files stay in the repo either way:
--   lua/thiran/plugins/obsidian.lua
--   lua/thiran/plugins/render-markdown.lua
--
-- Your vault path does not belong in this file. Copy
-- lua/thiran/config/vault.example.lua to lua/thiran/config/vault.lua and edit
-- the path there. vault.lua is gitignored.
local M = {
	enabled = true,
	-- Folder names under Neovim's lazy install directory.
	plugins = { "obsidian.nvim", "render-markdown.nvim" },
}

function M.sync()
	if M.enabled then
		return
	end

	local root = vim.fs.normalize(vim.fn.stdpath("data") .. "/lazy")
	local removed = {}
	for _, name in ipairs(M.plugins) do
		local dir = vim.fs.normalize(root .. "/" .. name)
		if vim.fn.isdirectory(dir) == 1 then
			if vim.fn.delete(dir, "rf") == 0 then
				table.insert(removed, name)
			else
				vim.notify("Could not remove " .. name .. ".", vim.log.levels.WARN)
			end
		end
	end

	if #removed > 0 then
		vim.notify(
			"Removed "
				.. table.concat(removed, " and ")
				.. ". Set enabled = true in lua/thiran/config/markdown.lua and restart Neovim to install them again.",
			vim.log.levels.INFO
		)
	end
end

return M
