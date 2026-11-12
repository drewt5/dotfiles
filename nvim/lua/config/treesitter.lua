local M = {}
M.parsers = {
  "angular",
  "bash",
  "c",
  "cpp",
  "css",
  "elixir",
  "go",
  "heex",
  "html",
  "java",
  "javascript",
  "json",
  "json5",
  "kotlin",
  "lua",
  "markdown",
  "markdown_inline",
  "ocaml",
  "ocaml_interface",
  "python",
  "rust",
  "scss",
  "swift",
  "toml",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
}

require("nvim-treesitter").setup()
vim.api.nvim_create_user_command("NvimInstallParsers", function()
  require("nvim-treesitter").install(M.parsers)
end, { desc = "Install missing parsers for configured languages" })

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dotfiles.treesitter", { clear = true }),
  callback = function(event)
    if vim.bo[event.buf].buftype ~= "" then
      return
    end
    local lang = vim.treesitter.language.get_lang(vim.bo[event.buf].filetype)
    if not lang or not vim.treesitter.language.add(lang) then
      return
    end
    vim.treesitter.start(event.buf, lang)
    if vim.treesitter.query.get(lang, "indents") then
      vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

require("nvim-treesitter-textobjects").setup({
  select = { lookahead = true },
  move = { set_jumps = true },
})

for key, query in pairs({
  af = "@function.outer",
  ["if"] = "@function.inner",
  ac = "@class.outer",
  ic = "@class.inner",
  aa = "@parameter.outer",
  ia = "@parameter.inner",
}) do
  vim.keymap.set({ "x", "o" }, key, function()
    require("nvim-treesitter-textobjects.select").select_textobject(query, "textobjects")
  end, { desc = "Select " .. query })
end

vim.keymap.set({ "n", "x", "o" }, "]m", function()
  require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
end, { desc = "Next function" })
vim.keymap.set({ "n", "x", "o" }, "[m", function()
  require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
end, { desc = "Previous function" })

return M
