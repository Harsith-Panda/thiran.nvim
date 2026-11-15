-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Molten needs its Python host before plugins load.
require("thiran.config.notebooks").prepare()

-- Avante's config registers the compiled library when that plugin loads.

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    -- import your plugins
    { import = "thiran.plugins" },
  },
  -- Checking GitHub on every launch waits on the network. :Lazy check still works.
  checker = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin", "netrwPlugin" },
    },
  },
})

-- Off removes the Obsidian and render-markdown install folders.
-- On again installs them during the setup above, when those folders are missing.
require("thiran.config.markdown").sync()

-- Off removes the notebook plugins and their Python host.
-- On again installs them during the setup above, when those folders are missing.
require("thiran.config.notebooks").sync()
