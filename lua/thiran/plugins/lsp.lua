return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			-- Bridges Mason downloads directly to lspconfig hooks
			"williamboman/mason-lspconfig.nvim",

			-- Highly Recommended: Adds autocompletion capabilities to LSP
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")

			-- 1. Setup the bridge between Mason and Lspconfig
			mason_lspconfig.setup({
				-- Automatically installs these LSPs if they aren't present
				ensure_installed = { "lua_ls", "clangd" },
				automatic_installation = true,
			})

			-- 2. Configure autocomplete integration capabilities
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			if pcall(require, "cmp_nvim_lsp") then
				capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
			end

			-- 3. Define global LSP Keymaps when a server attaches to a file
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					local opts = { buffer = ev.buf }

					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts) -- Go to definition
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts) -- Show documentation
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- Smart variable rename
					vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- Code Actions
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				end,
			})

			-- 4. Handlers: Automatically activate any LSP you download in Mason
			mason_lspconfig.setup_handlers({
				-- The default handler applies to every server unless overridden
				function(server_name)
					lspconfig[server_name].setup({
						capabilities = capabilities,
					})
				end,

				-- Example of overriding a specific server's settings (e.g. Lua)
				["lua_ls"] = function()
					lspconfig.lua_ls.setup({
						capabilities = capabilities,
						settings = {
							Lua = {
								diagnostics = {
									globals = { "vim" }, -- Stop "undefined global vim" errors
								},
							},
						},
					})
				end,
			})
		end,
	},
}
