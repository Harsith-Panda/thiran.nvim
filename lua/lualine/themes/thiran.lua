local p = require("thiran.theme.palette")

local bar = p.float
local mid = p.hover
local body = { fg = p.text, bg = bar }
local dim = { fg = p.muted, bg = bar }
local branch = { fg = p.text, bg = mid }
local place = { fg = p.text, bg = mid }
-- Dark ink on the orange chip, matching the prompt's git segment.
local logo = { fg = p.ink, bg = p.accent, gui = "bold" }

local function mode_theme(mode)
	return {
		a = mode,
		b = branch,
		c = body,
		x = dim,
		y = place,
		z = logo,
	}
end

return {
	normal = mode_theme({ fg = p.bright, bg = p.ink }),
	insert = mode_theme({ fg = p.ink, bg = p.accent, gui = "bold" }),
	visual = mode_theme({ fg = p.ink, bg = p.muted }),
	replace = mode_theme({ fg = p.bright, bg = p.rose, gui = "bold" }),
	command = mode_theme({ fg = p.ink, bg = p.teal }),
	inactive = mode_theme({ fg = p.bright, bg = p.ink }),
}
