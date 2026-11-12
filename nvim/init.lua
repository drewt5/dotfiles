-- Resolve the dotfiles directory even when only init.lua is symlinked.
local source = debug.getinfo(1, "S").source:sub(2)
local config_dir = vim.fs.dirname(vim.uv.fs_realpath(source) or source)
vim.opt.runtimepath:prepend(config_dir)
vim.g.dotfiles_nvim_init = config_dir .. "/init.lua"

for _, name in ipairs({ "options", "plugins", "formatting", "lsp", "indentation", "treesitter", "theme", "keymaps" }) do
  local module = "config." .. name
  package.loaded[module] = nil
  require(module)
end
