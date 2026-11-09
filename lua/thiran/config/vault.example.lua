-- Copy this file to vault.lua in the same folder, then edit the path.
--
--   cp lua/thiran/config/vault.example.lua lua/thiran/config/vault.lua
--
-- vault.lua is listed in .gitignore, so the path stays on your machine.
-- Restart Neovim after you change it.
--
-- `path` is the vault root: the folder that contains the .obsidian directory.
-- Add another table inside workspaces for a second vault.
return {
	workspaces = {
		{
			name = "notes",
			path = "~/path/to/your/vault",
		},
	},
}
