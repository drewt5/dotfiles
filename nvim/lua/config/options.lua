vim.o.number = true
vim.o.relativenumber = true
vim.o.wrap = false
vim.o.tabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true
vim.o.signcolumn = "yes"
vim.o.colorcolumn = "80"
vim.o.swapfile = false
vim.o.undofile = true
vim.g.mapleader = " "
vim.o.winborder = "rounded"
vim.g.maplocalleader = " "
vim.filetype.add({ extension = { mdx = "markdown.mdx", mli = "ocamlinterface" } })
if vim.fn.has("mac") == 1 then
  local result = vim.system({ "defaults", "read", "-g", "AppleInterfaceStyle" }, { text = true }):wait()
  vim.o.background = result.code == 0 and result.stdout:match("Dark") and "dark" or "light"
end

vim.opt.diffopt:append({
  "internal",
  "filler",
  "closeoff",
  "indent-heuristic",
  "algorithm:histogram",
  "inline:char",
})

local diagnostic_signs = {
  [vim.diagnostic.severity.ERROR] = "E",
  [vim.diagnostic.severity.WARN] = "W",
  [vim.diagnostic.severity.INFO] = "I",
  [vim.diagnostic.severity.HINT] = "H",
}

vim.diagnostic.config({
  severity_sort = true,
  underline = true,
  update_in_insert = false,
  virtual_text = false,
  signs = { text = diagnostic_signs },
  float = {
    border = "rounded",
    source = "if_many",
    focusable = false,
  },
})

-- Keep an explicitly selected JDK; use SDKMAN only when one is available.
local sdkman_java = vim.fn.expand("~/.sdkman/candidates/java/current")
if not vim.env.JAVA_HOME and vim.fn.executable(sdkman_java .. "/bin/java") == 1 then
  vim.env.JAVA_HOME = sdkman_java
end
if vim.env.JAVA_HOME then
  local java_bin = vim.env.JAVA_HOME .. "/bin"
  if not vim.tbl_contains(vim.split(vim.env.PATH or "", ":", { plain = true }), java_bin) then
    vim.env.PATH = java_bin .. ":" .. (vim.env.PATH or "")
  end
end
