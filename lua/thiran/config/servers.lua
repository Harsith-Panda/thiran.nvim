-- Servers installed for every Thiran user, and the settings layered on top of
-- nvim-lspconfig. Edit this file to add a language or change a server.
-- The plugin wiring that reads this file is lua/thiran/plugins/lsp.lua.
--
-- A server set to false is not started.
-- `filetypes` replaces that server's filetype list.
return {
	ensure_installed = { "lua_ls", "clangd" },

	servers = {
		lua_ls = {
			settings = {
				Lua = {
					diagnostics = { globals = { "vim" } },
				},
			},
		},

		-- nvim-lspconfig also lists c.doxygen and cpp.doxygen. Those are syntax
		-- combinations, not filetypes Neovim detects, so :checkhealth vim.lsp warns.
		-- Add them here if you use :set filetype=c.doxygen.
		clangd = {
			filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
		},
	},
}
