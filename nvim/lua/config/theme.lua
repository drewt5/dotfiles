require("solarized-osaka").setup({
  transparent = false,
  styles = {
    comments = { italic = false },
    keywords = { italic = false },
  },
})
require("gruvbox").setup({
  transparent_mode = false,
  italic = {
    comments = false,
    strings = false,
    operators = false,
    folds = false,
    emphasis = false,
  },
})
require("github-theme").setup({
  options = {
    transparent = false,
    styles = {
      comments = "NONE",
      keywords = "NONE",
    },
  },
})
require("deepwater").setup({
  styles = {
    comments = {},
    conditionals = {},
  },
})
require("bamboo").setup({
  transparent = false,
  code_style = {
    comments = { italic = false },
    conditionals = { italic = false },
    keywords = {},
    functions = {},
    namespaces = { italic = false },
    parameters = { italic = false },
    strings = {},
    variables = {},
  },
})
require("rose-pine").setup({
  variant = "auto",
  dark_variant = "moon",
  styles = {
    italic = false,
    transparency = true,
  },
})

local themes = {
  "rose-pine",
  "github_dark",
  "gruvbox",
  "solarized-osaka",
  "bamboo",
  "deepwater",
}

local theme_state_path = vim.fn.stdpath("state") .. "/colorscheme.txt"

local function save_theme(name)
  vim.fn.mkdir(vim.fs.dirname(theme_state_path), "p")
  vim.fn.writefile({ name }, theme_state_path)
end

local function load_theme()
  local ok, lines = pcall(vim.fn.readfile, theme_state_path)
  if ok and lines[1] and lines[1] ~= "" then
    return vim.tbl_contains(themes, lines[1]) and lines[1] or "rose-pine"
  end
  return "rose-pine"
end

local function apply_theme(name, opts)
  opts = opts or {}
  local silent = opts.silent == true

  if not vim.tbl_contains(themes, name) then
    vim.notify("Unknown colorscheme: " .. name, vim.log.levels.ERROR)
    return
  end

  local ok, err = pcall(vim.cmd.colorscheme, name)
  if not ok then
    vim.notify("Failed to load colorscheme " .. name .. ": " .. err, vim.log.levels.ERROR)
    return
  end

  save_theme(name)
  if not silent then
    vim.notify("Theme: " .. name)
  end
end

local function cycle_theme(step)
  local current = vim.g.colors_name or load_theme()
  local index = vim.fn.index(themes, current)
  if index < 0 then
    index = 0
  end
  apply_theme(themes[(index + step) % #themes + 1])
end

apply_theme(load_theme(), { silent = true })

return {
  themes = themes,
  apply = apply_theme,
  cycle = cycle_theme,
}
