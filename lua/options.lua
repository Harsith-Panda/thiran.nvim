-- Remote plugin hosts.
-- LSP, formatters, and debuggers for a language are separate and stay available.
-- Molten is the exception: it is a Python remote plugin. The notebook switch
-- in lua/thiran/config/notebooks.lua turns that host on and off.
-- Perl and Ruby stay off.
local notebooks = require("thiran.config.notebooks")
if not notebooks.enabled then
	vim.g.loaded_python3_provider = 0
end
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
