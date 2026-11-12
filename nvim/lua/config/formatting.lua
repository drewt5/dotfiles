local M = {}
local conform = require("conform")

local prettier = { "prettier" }
M.formatters_by_ft = {
  javascript = prettier,
  javascriptreact = prettier,
  typescript = prettier,
  typescriptreact = prettier,
  css = prettier,
  scss = prettier,
  less = prettier,
  json = prettier,
  jsonc = prettier,
  json5 = prettier,
  html = prettier,
  htmlangular = prettier,
  vue = prettier,
  yaml = prettier,
  markdown = prettier,
  ["markdown.mdx"] = prettier,
  graphql = prettier,
  handlebars = prettier,
  xml = { "xmlformatter" },
  lua = { "stylua" },
  python = { "ruff_format" },
  c = { "clang-format" },
  cpp = { "clang-format" },
  objc = { "clang-format" },
  objcpp = { "clang-format" },
  go = { "gofmt" },
  rust = { "rustfmt" },
  sh = { "shfmt" },
  bash = { "shfmt" },
  toml = { "taplo" },
  swift = { "swiftformat" },
  elixir = { "mix" },
  heex = { "mix" },
  ocaml = { "ocamlformat" },
  ocamlinterface = { "ocamlformat" },
  java = { "google-java-format" },
  kotlin = { "ktfmt" },
  haskell = { "fourmolu" },
}

M.tools = {
  "prettier",
  "stylua",
  "ruff",
  "clang-format",
  "shfmt",
  "taplo",
  "swiftformat",
  "google-java-format",
  "ktfmt",
  "xmlformatter",
}

conform.setup({
  formatters_by_ft = M.formatters_by_ft,
  formatters = {
    taplo = {
      cwd = require("conform.util").root_file({ ".taplo.toml", "taplo.toml" }),
    },
  },
  default_format_opts = { lsp_format = "fallback", timeout_ms = 2000 },
  format_on_save = function(bufnr)
    if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat or vim.bo[bufnr].buftype ~= "" then
      return
    end
    return { lsp_format = "fallback", timeout_ms = 2000 }
  end,
})

vim.api.nvim_create_user_command("Format", function(opts)
  local range
  if opts.range > 0 then
    range = { start = { opts.line1, 0 }, ["end"] = { opts.line2, 0 } }
  end
  conform.format({ async = true, range = range })
end, { range = true, desc = "Format buffer or selected lines" })

vim.api.nvim_create_user_command("FormatDisable", function(opts)
  if opts.bang then
    vim.g.disable_autoformat = true
  else
    vim.b.disable_autoformat = true
  end
end, { bang = true, desc = "Disable format on save for this buffer, or globally with !" })

vim.api.nvim_create_user_command("FormatEnable", function(opts)
  if opts.bang then
    vim.g.disable_autoformat = false
  end
  vim.b.disable_autoformat = false
end, { bang = true, desc = "Enable format on save for this buffer, or globally with !" })

function M.install_tools()
  local registry = require("mason-registry")
  registry.refresh(function()
    for _, name in ipairs(M.tools) do
      local package = registry.get_package(name)
      if not package:is_installed() and not package:is_installing() then
        package:install()
      end
    end
  end)
end

vim.api.nvim_create_user_command("NvimInstallTools", M.install_tools, {
  desc = "Install missing formatters through Mason",
})

return M
