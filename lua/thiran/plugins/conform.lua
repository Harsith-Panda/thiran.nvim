return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	opts = {
		formatters_by_ft = {
			-- 1. Explicitly list ONLY the tools you care about configuring manually
			lua = { "stylua" },
			python = { "ruff" },

			-- 2. THE MAGIC WILDCARD: For any language NOT listed above,
			-- try to find a configured LSP project-wide and use its formatter automatically.
			["_"] = { "lsp" },
		},

		-- Stay quiet when a filetype has no formatter. Markdown is one of those
		-- until a Markdown formatter or an LSP that can format it is installed.
		notify_no_formatters = false,
		format_on_save = {
			timeout_ms = 200,
			lsp_format = "fallback",
		},
	},
}
