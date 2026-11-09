-- In-buffer Markdown view. Obsidian keeps the vault, links, and note commands.
-- Turn this off in lua/thiran/config/markdown.lua. Live preview is separate.
local markdown = require("thiran.config.markdown")

---@type LazySpec
return {
	"MeanderingProgrammer/render-markdown.nvim",
	enabled = markdown.enabled,
	ft = "markdown",
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	---@module "render-markdown"
	---@type render.md.UserConfig
	opts = {
		-- Normal mode is the preview. Insert mode shows the raw Markdown,
		-- and leaving insert mode renders it again.
		render_modes = { "n", "c", "t" },
		-- On the cursor line, drop the rendered marks. A link then shows
		-- [[wikilink]] or [text](url) instead of the preview.
		anti_conceal = {
			enabled = true,
		},
		-- Loads with the markdown filetype, after treesitter has highlighted
		-- the buffer. Restart so those highlights settle.
		restart_highlighter = true,
	},
}
