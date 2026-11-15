local palette = require("thiran.theme.palette")
local choice = require("thiran.config.theme")

local M = {}

local saved_icon

function M.box()
	if choice.border == "rounded" then
		return {
			tl = "╭",
			tr = "╮",
			bl = "╰",
			br = "╯",
			h = "─",
			v = "│",
			chars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
		}
	end
	return {
		tl = "┌",
		tr = "┐",
		bl = "└",
		br = "┘",
		h = "─",
		v = "│",
		chars = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
	}
end

function M.chrome()
	vim.opt.termguicolors = true
	vim.opt.background = "dark"
	vim.opt.cursorline = true
	vim.opt.number = true
	vim.opt.signcolumn = "yes"
	-- One statusline per window, so the Avante prompt can keep its usage line.
	vim.opt.laststatus = 2
	vim.opt.guicursor = "a:block-Cursor-blinkon0"
	vim.opt.fillchars:append({
		eob = " ",
		fold = " ",
		diff = "╱",
	})
	pcall(function()
		vim.opt.winborder = choice.border == "rounded" and "rounded" or "single"
	end)
end

local function hi(group, spec)
	vim.api.nvim_set_hl(0, group, spec)
end

local function link(group, target)
	hi(group, { link = target })
end

local function paint(groups, spec)
	for _, group in ipairs(groups) do
		hi(group, spec)
	end
end

function M.apply()
	local p = palette
	vim.g.colors_name = "thiran"

	for index, color in ipairs(p.ansi) do
		vim.g["terminal_color_" .. (index - 1)] = color
	end

	hi("Normal", { fg = p.text, bg = p.bg })
	hi("NormalNC", { fg = p.text, bg = p.bg })
	hi("NormalFloat", { fg = p.text, bg = p.float })
	hi("FloatBorder", { fg = p.border_strong, bg = p.float })
	hi("FloatTitle", { fg = p.accent, bg = p.float })
	hi("ThiranTerminal", { fg = p.text, bg = p.term_bg })

	hi("Cursor", { fg = p.term_bg, bg = p.cursor })
	hi("lCursor", { fg = p.term_bg, bg = p.cursor })
	hi("CursorLine", { bg = p.bg_raised })
	hi("CursorColumn", { bg = p.bg_raised })
	hi("CursorLineNr", { fg = p.accent, bg = p.bg_raised })
	hi("LineNr", { fg = p.faint })
	hi("SignColumn", { fg = p.faint, bg = p.bg })
	hi("ColorColumn", { bg = p.bg_alt })
	hi("WinSeparator", { fg = p.border, bg = p.bg })
	hi("VertSplit", { fg = p.border, bg = p.bg })
	link("EndOfBuffer", "NonText")
	hi("NonText", { fg = p.recessed })
	hi("Whitespace", { fg = p.border })
	hi("SpecialKey", { fg = p.recessed })
	hi("Conceal", { fg = p.recessed })

	hi("Visual", { fg = p.selected_text, bg = p.selection })
	link("VisualNOS", "Visual")
	hi("Search", { fg = p.bright, bg = p.search })
	hi("IncSearch", { fg = p.bright, bg = p.search_current })
	hi("CurSearch", { fg = p.bright, bg = p.search_current })
	hi("Substitute", { fg = p.ink, bg = p.accent })
	hi("MatchParen", { fg = p.bright, bg = p.focus })

	hi("StatusLine", { fg = p.text, bg = p.float })
	hi("StatusLineNC", { fg = p.faint, bg = p.bg_alt })
	hi("ThiranCursorUsage", { fg = p.muted, bg = p.float })
	hi("WinBar", { fg = p.muted, bg = p.bg })
	hi("WinBarNC", { fg = p.faint, bg = p.bg })
	hi("TabLine", { fg = p.faint, bg = p.bg })
	hi("TabLineSel", { fg = p.text, bg = p.bg_raised })
	hi("TabLineFill", { fg = p.recessed, bg = p.bg })

	hi("Pmenu", { fg = p.text, bg = p.float })
	hi("PmenuSel", { fg = p.bright, bg = p.hover })
	hi("PmenuMatch", { fg = p.accent, bg = p.float })
	hi("PmenuMatchSel", { fg = p.accent_hover, bg = p.hover })
	hi("PmenuSbar", { bg = p.bg_raised })
	hi("PmenuThumb", { bg = p.selection })
	link("WildMenu", "PmenuSel")

	hi("ErrorMsg", { fg = p.rose })
	hi("WarningMsg", { fg = p.accent })
	hi("MoreMsg", { fg = p.success })
	hi("Question", { fg = p.success })
	hi("ModeMsg", { fg = p.muted })
	hi("Title", { fg = p.accent, bold = true })
	hi("Directory", { fg = p.path })

	hi("Folded", { fg = p.faint, bg = p.bg_alt })
	hi("FoldColumn", { fg = p.recessed, bg = p.bg })
	hi("QuickFixLine", { fg = p.bright, bg = p.focus })

	hi("DiffAdd", { fg = p.success, bg = p.diff_add })
	hi("DiffChange", { fg = p.accent, bg = p.diff_change })
	hi("DiffDelete", { fg = p.rose, bg = p.diff_delete })
	hi("DiffText", { fg = p.bright, bg = p.diff_text })
	link("Added", "DiffAdd")
	link("Changed", "DiffChange")
	link("Removed", "DiffDelete")

	hi("SpellBad", { undercurl = true, sp = p.rose })
	hi("SpellCap", { undercurl = true, sp = p.accent })
	hi("SpellLocal", { undercurl = true, sp = p.teal })
	hi("SpellRare", { undercurl = true, sp = p.mauve })

	hi("DiagnosticError", { fg = p.rose })
	hi("DiagnosticWarn", { fg = p.accent })
	hi("DiagnosticInfo", { fg = p.teal })
	hi("DiagnosticHint", { fg = p.muted })
	hi("DiagnosticOk", { fg = p.success })
	hi("DiagnosticUnderlineError", { undercurl = true, sp = p.rose })
	hi("DiagnosticUnderlineWarn", { undercurl = true, sp = p.accent })
	hi("DiagnosticUnderlineInfo", { undercurl = true, sp = p.teal })
	hi("DiagnosticUnderlineHint", { undercurl = true, sp = p.muted })
	link("DiagnosticVirtualTextError", "DiagnosticError")
	link("DiagnosticVirtualTextWarn", "DiagnosticWarn")
	link("DiagnosticVirtualTextInfo", "DiagnosticInfo")
	link("DiagnosticVirtualTextHint", "DiagnosticHint")
	link("DiagnosticSignError", "DiagnosticError")
	link("DiagnosticSignWarn", "DiagnosticWarn")
	link("DiagnosticSignInfo", "DiagnosticInfo")
	link("DiagnosticSignHint", "DiagnosticHint")

	-- Syntax. Roles follow the shell map: lightness first, then hue.
	hi("Comment", { fg = p.comment })
	hi("BiscuitColor", { fg = p.comment })
	hi("Todo", { fg = p.accent })
	paint({ "Constant", "Number", "Boolean", "Float" }, { fg = p.accent })
	paint({ "String", "Character" }, { fg = p.sand })
	paint({
		"Statement",
		"Conditional",
		"Repeat",
		"Label",
		"Exception",
		"Keyword",
		"PreProc",
		"Include",
		"Define",
		"Macro",
		"PreCondit",
	}, { fg = p.func, bold = true })
	hi("Function", { fg = p.func, bold = true })
	paint({ "Type", "StorageClass", "Structure", "Typedef" }, { fg = p.path })
	paint({ "Identifier", "Variable" }, { fg = p.path })
	paint({ "Special", "Tag", "SpecialChar", "SpecialComment" }, { fg = p.mauve })
	paint({ "Operator", "Delimiter" }, { fg = p.punct })
	hi("Underlined", { fg = p.sand, underline = true })
	hi("Bold", { bold = true })
	hi("Italic", { italic = true })
	-- Invalid syntax stays recessed. Diagnostics carry the rose.
	hi("Error", { fg = p.recessed })
	hi("Debug", { fg = p.faint })

	hi("@comment", { fg = p.comment })
	hi("@comment.documentation", { fg = p.comment })
	hi("@error", { fg = p.recessed })
	paint({
		"@keyword",
		"@keyword.function",
		"@keyword.operator",
		"@keyword.return",
		"@keyword.conditional",
		"@keyword.repeat",
		"@keyword.exception",
		"@keyword.import",
		"@function.builtin",
		"@variable.builtin",
	}, { fg = p.func, bold = true })
	paint({
		"@function",
		"@function.call",
		"@function.method",
		"@function.method.call",
		"@method",
		"@method.call",
	}, { fg = p.teal, bold = true })
	paint({ "@string", "@string.documentation", "@character" }, { fg = p.sand })
	hi("@string.escape", { fg = p.accent })
	hi("@string.special.path", { fg = p.path, underline = true })
	hi("@string.special.url", { fg = p.sand, underline = true })
	paint({ "@number", "@boolean", "@constant", "@constant.builtin" }, { fg = p.accent })
	paint({
		"@type",
		"@type.builtin",
		"@variable",
		"@variable.parameter",
		"@variable.member",
		"@property",
		"@field",
		"@module",
	}, { fg = p.path })
	paint({ "@tag", "@tag.attribute", "@attribute" }, { fg = p.mauve })
	hi("@tag.delimiter", { fg = p.punct })
	paint({
		"@operator",
		"@punctuation",
		"@punctuation.bracket",
		"@punctuation.delimiter",
		"@punctuation.special",
	}, { fg = p.punct })

	local headings = { p.accent, p.sand, p.func, p.teal, p.mauve, p.muted }
	for level, color in ipairs(headings) do
		local spec = { fg = color, bold = level == 1 }
		hi("@markup.heading." .. level, spec)
		hi("@markup.heading." .. level .. ".markdown", spec)
		hi("markdownH" .. level, spec)
		hi("RenderMarkdownH" .. level, spec)
		hi("RenderMarkdownH" .. level .. "Bg", { fg = color, bg = p.bg })
		hi("@markup.heading." .. level .. ".marker", { fg = p.recessed })
	end
	hi("@markup.strong", { fg = p.bright, bold = true })
	hi("@markup.italic", { fg = p.text, italic = true })
	hi("@markup.strikethrough", { fg = p.faint, strikethrough = true })
	hi("@markup.link", { fg = p.sand })
	hi("@markup.link.label", { fg = p.sand })
	hi("@markup.link.url", { fg = p.sand, underline = true })
	hi("@markup.raw", { fg = p.sand, bg = p.bg_alt })
	hi("@markup.quote", { fg = p.path })
	hi("@markup.list", { fg = p.faint })
	hi("@markup.list.checked", { fg = p.git_clean })
	hi("@markup.list.unchecked", { fg = p.faint })
	hi("RenderMarkdownCode", { bg = p.bg_alt })
	hi("RenderMarkdownCodeInline", { fg = p.sand, bg = p.bg_alt })
	link("RenderMarkdownQuote", "@markup.quote")
	link("RenderMarkdownChecked", "@markup.list.checked")
	link("RenderMarkdownUnchecked", "@markup.list.unchecked")

	hi("helpHeader", { fg = p.sand, bold = true })
	hi("helpHeadline", { fg = p.accent, bold = true })
	hi("helpSectionDelim", { fg = p.recessed })
	hi("helpHyperTextJump", { fg = p.sand, underline = true })
	hi("helpCommand", { fg = p.func, bold = true })
	hi("helpExample", { fg = p.sand })
	hi("helpOption", { fg = p.punct })
	hi("helpSpecial", { fg = p.mauve })
	hi("helpNote", { fg = p.accent })
	hi("helpURL", { fg = p.sand, underline = true })

	hi("GitSignsAdd", { fg = p.success })
	hi("GitSignsChange", { fg = p.accent })
	hi("GitSignsDelete", { fg = p.rose })
	hi("GitSignsUntracked", { fg = p.faint })
	link("GitSignsAddPreview", "DiffAdd")
	link("GitSignsDeletePreview", "DiffDelete")
	hi("GitSignsCurrentLineBlame", { fg = p.recessed })

	hi("NeoTreeNormal", { fg = p.text, bg = p.bg })
	hi("NeoTreeNormalNC", { fg = p.text, bg = p.bg })
	hi("NeoTreeCursorLine", { bg = p.bg_raised })
	hi("NeoTreeDirectoryName", { fg = p.path })
	hi("NeoTreeDirectoryIcon", { fg = p.path })
	hi("NeoTreeFileName", { fg = p.text })
	hi("NeoTreeFileNameOpened", { fg = p.bright })
	hi("NeoTreeRootName", { fg = p.bright, bold = true })
	hi("NeoTreeDimText", { fg = p.faint })
	hi("NeoTreeDotfile", { fg = p.comment })
	hi("NeoTreeGitAdded", { fg = p.success })
	hi("NeoTreeGitModified", { fg = p.accent })
	hi("NeoTreeGitDeleted", { fg = p.rose })
	hi("NeoTreeGitUntracked", { fg = p.sand })
	hi("NeoTreeGitConflict", { fg = p.rose })
	hi("NeoTreeWinSeparator", { fg = p.border, bg = p.bg })
	hi("NeoTreeFloatBorder", { fg = p.border_strong, bg = p.float })
	hi("NeoTreeTitleBar", { fg = p.ink, bg = p.muted })

	hi("TelescopeNormal", { fg = p.text, bg = p.float })
	hi("TelescopeBorder", { fg = p.border_strong, bg = p.float })
	hi("TelescopePromptNormal", { fg = p.text, bg = p.bg_raised })
	hi("TelescopePromptBorder", { fg = p.accent_line, bg = p.bg_raised })
	hi("TelescopePromptPrefix", { fg = p.accent, bg = p.bg_raised })
	hi("TelescopePromptTitle", { fg = p.ink, bg = p.accent })
	hi("TelescopeResultsTitle", { fg = p.faint, bg = p.float })
	hi("TelescopePreviewTitle", { fg = p.ink, bg = p.muted })
	hi("TelescopeSelection", { fg = p.bright, bg = p.hover })
	hi("TelescopeSelectionCaret", { fg = p.accent, bg = p.hover })
	hi("TelescopeMatching", { fg = p.accent })
	hi("TelescopeResultsComment", { fg = p.comment })

	hi("WhichKey", { fg = p.text })
	hi("WhichKeyGroup", { fg = p.accent })
	hi("WhichKeyDesc", { fg = p.text })
	hi("WhichKeySeparator", { fg = p.recessed })
	hi("WhichKeyValue", { fg = p.sand })
	hi("WhichKeyBorder", { fg = p.border_strong, bg = p.float })
	link("WhichKeyFloat", "NormalFloat")
	hi("WhichKeyTitle", { fg = p.accent })

	hi("OilDir", { fg = p.path })
	link("OilDirIcon", "OilDir")
	hi("OilHidden", { fg = p.comment })

	hi("MiniIconsGrey", { fg = p.faint })
	hi("MiniIconsBlue", { fg = p.path })
	hi("MiniIconsAzure", { fg = p.path })
	hi("MiniIconsCyan", { fg = p.teal })
	hi("MiniIconsGreen", { fg = p.func })
	hi("MiniIconsYellow", { fg = p.sand })
	hi("MiniIconsOrange", { fg = p.accent })
	hi("MiniIconsPurple", { fg = p.mauve })
	hi("MiniIconsRed", { fg = p.rose })

	-- Mason's defaults are gold and cyan. These win because Mason sets them
	-- with default = true only when the group is still empty.
	hi("MasonHeader", { fg = p.ink, bg = p.accent, bold = true })
	hi("MasonHeaderSecondary", { fg = p.ink, bg = p.muted, bold = true })
	hi("MasonHighlight", { fg = p.accent })
	hi("MasonHighlightBlock", { fg = p.ink, bg = p.accent })
	hi("MasonHighlightBlockBold", { fg = p.ink, bg = p.accent, bold = true })
	hi("MasonHighlightSecondary", { fg = p.sand })
	hi("MasonHighlightBlockSecondary", { fg = p.ink, bg = p.muted })
	hi("MasonHighlightBlockBoldSecondary", { fg = p.ink, bg = p.muted, bold = true })
	hi("MasonMuted", { fg = p.faint })
	hi("MasonMutedBlock", { fg = p.ink, bg = p.faint })
	hi("MasonMutedBlockBold", { fg = p.ink, bg = p.faint, bold = true })
	hi("MasonNormal", { fg = p.text, bg = p.float })
	hi("MasonBackdrop", { bg = p.bg })
	link("MasonError", "DiagnosticError")
	link("MasonWarning", "DiagnosticWarn")
	hi("MasonHeading", { fg = p.text, bold = true })

	hi("DapUIFloatBorder", { fg = p.border_strong, bg = p.float })
	hi("DapUIStop", { fg = p.rose })
	hi("DapUIPlayPause", { fg = p.success })
	hi("DapUIRestart", { fg = p.accent })
	hi("DapUIUnavailable", { fg = p.recessed })
	hi("DapUIStepOver", { fg = p.func })
	hi("DapUIStepInto", { fg = p.func })
	hi("DapUIStepBack", { fg = p.func })
	hi("DapUIStepOut", { fg = p.func })
	hi("DapUIBreakpointsCurrentLine", { fg = p.accent })
	hi("DapUIBreakpointsPath", { fg = p.path })
	hi("DapUIWatchesError", { fg = p.rose })
	hi("DapUIWatchesValue", { fg = p.success })
	hi("DapUIType", { fg = p.path })
	hi("DapUIDecoration", { fg = p.punct })
	hi("DapUIModifiedValue", { fg = p.func, bold = true })
	hi("DapUIThread", { fg = p.teal })
	hi("DapUIStoppedThread", { fg = p.accent })

	hi("DiffviewFilePanelTitle", { fg = p.accent, bold = true })
	hi("DiffviewFilePanelCounter", { fg = p.muted })
	hi("DiffviewFolderSign", { fg = p.path })
	link("DiffviewStatusAdded", "DiffAdd")
	link("DiffviewStatusModified", "DiffChange")
	link("DiffviewStatusDeleted", "DiffDelete")

	M.terminal_windows()
end

function M.terminal_windows()
	local hl = ""
	if vim.g.colors_name == "thiran" then
		hl = "Normal:ThiranTerminal,NormalNC:ThiranTerminal,SignColumn:ThiranTerminal,EndOfBuffer:ThiranTerminal"
	end
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		if vim.bo[buf].buftype == "terminal" then
			vim.wo[win].winhighlight = hl
		end
	end
end

function M.avante()
	if vim.g.colors_name ~= "thiran" then
		return
	end
	if not package.loaded["avante"] then
		return
	end

	local p = palette
	local function chip(bg)
		return { fg = p.ink, bg = bg }
	end

	hi("AvanteTitle", chip(p.accent))
	hi("AvanteReversedTitle", { fg = p.accent, bg = p.float })
	hi("AvanteSubtitle", chip(p.muted))
	hi("AvanteReversedSubtitle", { fg = p.muted, bg = p.float })
	hi("AvanteThirdTitle", { fg = p.text, bg = p.hover })
	hi("AvanteReversedThirdTitle", { fg = p.text, bg = p.float })
	link("AvanteSuggestion", "Comment")
	link("AvanteAnnotation", "Comment")
	link("AvantePopupHint", "NormalFloat")
	hi("AvanteInlineHint", { fg = p.faint })
	hi("AvanteToBeDeleted", { fg = p.rose, bg = p.diff_delete, strikethrough = true })
	hi("AvanteToBeDeletedWOStrikethrough", { bg = p.diff_delete })
	hi("AvanteConfirmTitle", { fg = p.rose, bg = p.bg })
	hi("AvanteButtonDefault", chip(p.muted))
	hi("AvanteButtonDefaultHover", { fg = p.bright, bg = p.hover })
	hi("AvanteButtonPrimary", chip(p.accent))
	hi("AvanteButtonPrimaryHover", chip(p.accent_hover))
	hi("AvanteButtonDanger", { fg = p.rose, bg = p.bg })
	hi("AvanteButtonDangerHover", { fg = p.rose_bright, bg = p.diff_delete })
	hi("AvantePromptInput", { fg = p.text, bg = p.bg_raised })
	hi("AvantePromptInputBorder", { fg = p.accent_line, bg = p.bg_raised })
	hi("AvanteSidebarWinSeparator", { fg = p.float, bg = p.float })
	hi("AvanteSidebarWinHorizontalSeparator", { fg = p.border, bg = p.float })
	link("AvanteSidebarNormal", "NormalFloat")
	hi("AvanteCommentFg", { fg = p.comment })
	hi("AvanteReversedNormal", { fg = p.bg, bg = p.text })
	hi("AvanteStateSpinnerGenerating", chip(p.accent))
	hi("AvanteStateSpinnerToolCalling", chip(p.teal))
	hi("AvanteStateSpinnerFailed", { fg = p.rose, bg = p.bg })
	hi("AvanteStateSpinnerSucceeded", { fg = p.success, bg = p.bg })
	hi("AvanteStateSpinnerSearching", chip(p.mauve))
	hi("AvanteStateSpinnerThinking", { fg = p.mauve, bg = p.bg })
	hi("AvanteStateSpinnerCompacting", { fg = p.muted, bg = p.bg })
	hi("AvanteTaskRunning", { fg = p.accent })
	hi("AvanteTaskCompleted", { fg = p.success })
	hi("AvanteTaskFailed", { fg = p.rose })
	hi("AvanteThinking", { fg = p.mauve })
	hi("AvanteConflictCurrent", { bg = p.diff_delete })
	hi("AvanteConflictCurrentLabel", { fg = p.rose, bg = p.diff_delete, bold = true })
	hi("AvanteConflictIncoming", { bg = p.diff_add })
	hi("AvanteConflictIncomingLabel", { fg = p.success, bg = p.diff_add, bold = true })

	local logo = {
		p.bright,
		p.text,
		p.text,
		p.path,
		p.path,
		p.muted,
		p.muted,
		p.faint,
		p.faint,
		p.comment,
		p.comment,
		p.recessed,
		p.recessed,
		p.border_strong,
	}
	for index, color in ipairs(logo) do
		hi("AvanteLogoLine" .. index, { fg = color })
	end
end

function M.icons()
	local ok, devicons = pcall(require, "nvim-web-devicons")
	if not ok then
		return
	end
	-- setup() applies only once. Later theme changes repaint the highlight groups.
	if not saved_icon then
		saved_icon = vim.deepcopy(devicons.get_default_icon())
	end
	if vim.g.colors_name == "thiran" then
		devicons.set_default_icon(saved_icon.icon, palette.path, saved_icon.cterm_color)
		for name in pairs(vim.api.nvim_get_hl(0, {})) do
			if type(name) == "string" and name:sub(1, 7) == "DevIcon" then
				vim.api.nvim_set_hl(0, name, { fg = palette.path })
			end
		end
	else
		devicons.set_default_icon(saved_icon.icon, saved_icon.color, saved_icon.cterm_color)
		devicons.set_up_highlights(true)
	end
end

function M.lualine_section(section)
	local name = vim.g.colors_name
	if name and name ~= "" then
		local ok, theme = pcall(require, "lualine.themes." .. name)
		if ok and type(theme) == "table" and theme.normal and theme.normal[section] then
			return theme.normal[section]
		end
	end
	local hl = vim.api.nvim_get_hl(0, { name = "StatusLine", link = true })
	local function hex(n)
		if not n then
			return nil
		end
		return string.format("#%06x", n)
	end
	return { fg = hex(hl.fg), bg = hex(hl.bg) }
end

function M.git_status_color()
	if vim.g.colors_name ~= "thiran" then
		return M.lualine_section("b")
	end
	local dict = vim.b.gitsigns_status_dict
	if type(dict) ~= "table" or type(dict.head) ~= "string" or dict.head == "" then
		local head = vim.b.gitsigns_head
		if type(head) ~= "string" or head == "" then
			local ok, fugitive = pcall(vim.fn.FugitiveHead)
			head = ok and fugitive or ""
		end
		if type(head) ~= "string" or head == "" then
			return { fg = palette.faint, bg = palette.float }
		end
		-- Branch is known before gitsigns reports a diff. Treat that as clean
		-- so the chip still ends in a point.
		return { fg = palette.ink, bg = palette.git_clean }
	end
	-- Same chips as the prompt: clean and untracked are the git green,
	-- a dirty tree is the deeper orange.
	local dirty = (dict.added or 0) + (dict.changed or 0) + (dict.removed or 0) > 0
	if dirty then
		return { fg = palette.ink, bg = palette.prompt_chip }
	end
	return { fg = palette.ink, bg = palette.git_clean }
end

-- Editor ground only. Chips, floats, and the statusline keep their colors.
-- A cleared background lets Ghostty's opacity show through.
local transparent_groups = {
	"Normal",
	"NormalNC",
	"SignColumn",
	"LineNr",
	"CursorLine",
	"CursorLineNr",
	"FoldColumn",
	"EndOfBuffer",
	"WinBar",
	"WinBarNC",
	"TabLineFill",
	"NeoTreeNormal",
	"NeoTreeNormalNC",
	"NeoTreeEndOfBuffer",
	"NeoTreeSignColumn",
	"NeoTreeWinSeparator",
	"NeoTreeVertSplit",
	"ThiranTerminal",
	"WinSeparator",
	"VertSplit",
}

local function clear_background(name)
	local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
	if not ok or type(hl) ~= "table" then
		return
	end
	hl.bg = "NONE"
	hl.ctermbg = nil
	vim.api.nvim_set_hl(0, name, hl)
end

function M.apply_transparency()
	if not vim.g.thiran_transparent then
		return
	end
	for _, name in ipairs(transparent_groups) do
		clear_background(name)
	end
end

function M.toggle_transparency()
	vim.g.thiran_transparent = not vim.g.thiran_transparent
	if vim.g.thiran_transparent then
		M.apply_transparency()
		vim.notify("Transparency on. The background follows the terminal.")
		return
	end
	if vim.g.colors_name == "thiran" then
		vim.cmd.colorscheme("thiran")
	end
	vim.notify("Transparency off.")
end

function M.after_plugins()
	M.icons()
	M.avante()
	M.terminal_windows()
	if vim.g.colors_name ~= "thiran" and package.loaded["render-markdown.core.colors"] then
		pcall(function()
			require("render-markdown.core.colors").init()
		end)
	end
end

function M.install_hooks()
	vim.api.nvim_create_autocmd("TermOpen", {
		group = vim.api.nvim_create_augroup("thiran_terminal_ground", { clear = true }),
		callback = function()
			if vim.g.colors_name ~= "thiran" then
				return
			end
			vim.wo.winhighlight =
				"Normal:ThiranTerminal,NormalNC:ThiranTerminal,SignColumn:ThiranTerminal,EndOfBuffer:ThiranTerminal"
		end,
	})

	vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
		group = vim.api.nvim_create_augroup("thiran_transparency", { clear = true }),
		callback = function()
			if vim.g.thiran_transparent then
				M.apply_transparency()
			end
		end,
	})

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("thiran_theme_follow", { clear = true }),
		callback = function()
			-- Other plugins repaint on this event. Run after them.
			vim.schedule(function()
				vim.schedule(function()
					M.after_plugins()
					M.apply_transparency()
				end)
			end)
		end,
	})
end

return M
