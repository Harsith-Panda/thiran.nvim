-- Canonical colors. Do not add hues. Blends are the same colors at low opacity
-- on the editor ground, so a wash stays inside the palette.

local bg = "#08090A"

local function channel(hex, index)
	return tonumber(hex:sub(index, index + 1), 16)
end

local function blend(fg, onto, alpha)
	local function mix(a, b)
		return math.floor(a * alpha + b * (1 - alpha) + 0.5)
	end
	return string.format(
		"#%02X%02X%02X",
		mix(channel(fg, 2), channel(onto, 2)),
		mix(channel(fg, 4), channel(onto, 4)),
		mix(channel(fg, 6), channel(onto, 6))
	)
end

local accent = "#E89250"
local success = "#A8C4A0"
local rose = "#D09A9C"

local M = {
	bg = bg,
	bg_alt = "#0B0C0D",
	bg_raised = "#0E0F10",
	float = "#121314",
	hover = "#1A1C1E",
	term_bg = "#151719",

	text = "#D4D6D8",
	bright = "#E6E8E9",
	selected_text = "#E4E6E7",
	muted = "#969EA4",
	faint = "#868E96",
	recessed = "#7D858D",
	comment = "#8E969E",
	path = "#B3BAC0",
	punct = "#A7AEB6",
	ink = "#202225",

	cursor = "#B4BCC2",
	selection = "#505860",

	accent = accent,
	accent_hover = "#F0A868",
	-- Prompt dirty-git and command-time chips. The branch segment uses this orange.
	prompt_chip = "#D48450",

	git_clean = "#6BB476",
	success = success,
	func = "#B7D4B0",
	green_bright = "#B6D4AE",

	teal = "#A8D4D2",
	teal_ansi = "#8FBDBB",
	teal_bright = "#A4D0CE",

	sand = "#E2B48A",
	mauve = "#D0B8D4",
	mauve_ansi = "#C4A8C6",
	mauve_bright = "#D4B8D6",

	rose = rose,
	rose_bright = "#E0AAAC",

	border = blend("#D4D6D8", bg, 0.07),
	border_strong = blend("#D4D6D8", bg, 0.12),
	focus = blend(accent, bg, 0.12),
	accent_line = blend(accent, bg, 0.55),
	search = blend(accent, bg, 0.22),
	search_current = blend(accent, bg, 0.45),
	diff_add = blend(success, bg, 0.16),
	diff_change = blend(accent, bg, 0.16),
	diff_delete = blend(rose, bg, 0.16),
	diff_text = blend(accent, bg, 0.28),

	ansi = {
		"#202225",
		"#D09A9C",
		"#A8C4A0",
		"#E89250",
		"#969EA4",
		"#C4A8C6",
		"#8FBDBB",
		"#D0D3D4",
		"#868E96",
		"#E0AAAC",
		"#B6D4AE",
		"#F0A868",
		"#B3BAC0",
		"#D4B8D6",
		"#A4D0CE",
		"#E6E8E9",
	},
}

M.blend = blend

return M
