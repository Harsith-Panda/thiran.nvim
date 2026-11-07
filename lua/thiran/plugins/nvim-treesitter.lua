return {
	{
		"nvim-treesitter/nvim-treesitter",
		-- main is the current rewrite. master is frozen and still uses the removed configs module.
		branch = "main",
		-- The rewrite does not support lazy-loading.
		lazy = false,
		build = ":TSUpdate",
		dependencies = { "mason-org/mason.nvim" },
		config = function()
			local treesitter = require("nvim-treesitter")

			-- Installed up front. Opening any other supported filetype installs its parser
			-- (the old auto_install = true). install() is async and a no-op when present.
			local ensure_installed = {
				"lua",
				"vim",
				"vimdoc",
				"query",
				"markdown",
				"markdown_inline",
				"c",
				"python",
				"javascript",
				"typescript",
			}

			local ready = false

			local function start(bufnr, lang)
				if not vim.api.nvim_buf_is_valid(bufnr) then
					return
				end
				if not pcall(vim.treesitter.start, bufnr, lang) then
					return
				end
				-- Experimental, same role as the old indent = { enable = true }.
				vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
			end

			-- Parser builds need the tree-sitter CLI. Mason provides it when it is not already on PATH.
			local function ensure_cli(callback)
				if vim.fn.executable("tree-sitter") == 1 then
					callback()
					return
				end

				local registry = require("mason-registry")

				local function install()
					if not registry.has_package("tree-sitter-cli") then
						vim.notify(
							"tree-sitter CLI is missing, and Mason has no tree-sitter-cli package.",
							vim.log.levels.ERROR
						)
						return
					end

					local pkg = registry.get_package("tree-sitter-cli")
					if pkg:is_installed() then
						callback()
						return
					end

					vim.notify("Installing tree-sitter CLI", vim.log.levels.INFO)
					pkg:install({}, function(success, err)
						vim.schedule(function()
							if not success then
								vim.notify("tree-sitter CLI install failed: " .. tostring(err), vim.log.levels.ERROR)
								return
							end
							if vim.fn.executable("tree-sitter") ~= 1 then
								vim.notify("tree-sitter CLI installed, but it is not on PATH.", vim.log.levels.ERROR)
								return
							end
							callback()
						end)
					end)
				end

				registry.refresh(function(success)
					vim.schedule(function()
						if not success then
							vim.notify("Could not refresh Mason to install the tree-sitter CLI.", vim.log.levels.ERROR)
							return
						end
						install()
					end)
				end)
			end

			local function enable(bufnr)
				if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].filetype == "" then
					return
				end

				local filetype = vim.bo[bufnr].filetype
				local lang = vim.treesitter.language.get_lang(filetype) or filetype
				if not vim.tbl_contains(treesitter.get_available(), lang) then
					return
				end

				local function attach()
					if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].filetype == filetype then
						start(bufnr, lang)
					end
				end

				if vim.tbl_contains(treesitter.get_installed("parsers"), lang) then
					attach()
					return
				end

				treesitter.install(lang):await(function(err)
					if err then
						return
					end
					vim.schedule(attach)
				end)
			end

			vim.api.nvim_create_autocmd("FileType", {
				group = vim.api.nvim_create_augroup("thiran.treesitter", { clear = true }),
				callback = function(args)
					if not ready and vim.fn.executable("tree-sitter") ~= 1 then
						return
					end
					enable(args.buf)
				end,
			})

			ensure_cli(function()
				ready = true
				treesitter.install(ensure_installed)
				for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
					if vim.api.nvim_buf_is_loaded(bufnr) then
						enable(bufnr)
					end
				end
			end)
		end,
	},
}
