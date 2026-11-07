-- Lazy spec for nvim-lspconfig and mason-lspconfig.
-- Add servers and change their settings in lua/thiran/config/servers.lua.

local function register_filetype(filetype)
	if vim.filetype._get_known_filetypes()[filetype] then
		return
	end

	-- A name counts as known only after it is in the filetype registry.
	-- The path is absolute so it does not match files in a project.
	vim.filetype.add({
		filename = {
			["/thiran/filetype/" .. filetype] = filetype,
		},
	})
end

-- Lists passed to vim.lsp.config replace the previous list.
local function replace_filetypes(name, filetypes)
	vim.lsp.config(name, { filetypes = filetypes })

	for _, filetype in ipairs(filetypes) do
		register_filetype(filetype)
	end
end

local function apply_servers(servers)
	local disabled = {}

	for name, opts in pairs(servers or {}) do
		if opts == false then
			if name ~= "*" then
				disabled[#disabled + 1] = name
			end
		elseif type(opts) == "table" then
			local filetypes = opts.filetypes
			opts = vim.deepcopy(opts)
			opts.filetypes = nil

			if next(opts) ~= nil then
				vim.lsp.config(name, opts)
			end
			if filetypes then
				replace_filetypes(name, filetypes)
			end
		end
	end

	return disabled
end

return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"mason-org/mason.nvim",
			"mason-org/mason-lspconfig.nvim",
		},
		config = function()
			local lsp = require("thiran.config.servers")

			-- Define global LSP Keymaps when a server attaches
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspConfig", {}),
				callback = function(ev)
					local opts = { buffer = ev.buf }
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
					vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
					vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
					vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)
					vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
				end,
			})

			local capabilities = vim.lsp.protocol.make_client_capabilities()
			-- cmp-nvim-lsp calls require("cmp") on InsertEnter, so it is used only
			-- when nvim-cmp is installed. Thiran does not ship a completion plugin.
			if pcall(require, "cmp") then
				local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
				if ok then
					capabilities = cmp_lsp.default_capabilities(capabilities)
				end
			end

			-- Applies to every server mason-lspconfig enables.
			vim.lsp.config("*", {
				capabilities = capabilities,
			})

			local disabled = apply_servers(lsp.servers)

			require("mason-lspconfig").setup({
				ensure_installed = lsp.ensure_installed,
				automatic_enable = {
					exclude = disabled,
				},
			})

			if #disabled > 0 then
				vim.lsp.enable(disabled, false)
			end
		end,
	},
}
