local mason = require("mason")
if not mason.has_setup then
  mason.setup()
end

local function file_contains(path, needle)
  local ok, lines = pcall(vim.fn.readfile, path)
  return ok and table.concat(lines, "\n"):find(needle, 1, true) ~= nil
end

vim.lsp.config("angularls", {
  filetypes = { "typescript", "html", "htmlangular" },
  root_dir = function(bufnr, on_dir)
    local fname = vim.api.nvim_buf_get_name(bufnr)
    local angular_root = vim.fs.root(fname, { "angular.json" })
    if angular_root then
      on_dir(angular_root)
      return
    end

    local project_json = vim.fs.find("project.json", { path = vim.fs.dirname(fname), upward = true })[1]
    if project_json then
      if file_contains(project_json, "@nx/angular") or file_contains(project_json, "@angular-devkit/build-angular") then
        on_dir(vim.fs.root(vim.fs.dirname(project_json), { "nx.json" }) or vim.fs.dirname(project_json))
      end
      return
    end

    local package_json = vim.fs.find("package.json", { path = vim.fs.dirname(fname), upward = true })[1]
    if package_json and file_contains(package_json, '"@angular/core"') then
      on_dir(vim.fs.dirname(package_json))
    end
  end,
})

vim.lsp.config("eslint", {
  settings = {
    workingDirectory = { mode = "auto" },
    format = false,
    codeActionOnSave = { enable = false, mode = "all" },
  },
})

vim.lsp.config("kotlin_language_server", {
  root_markers = { "settings.gradle", "settings.gradle.kts", "build.gradle", "build.gradle.kts", "pom.xml" },
  before_init = function(params)
    -- The server requires an object here, including for standalone files.
    params.initializationOptions = { storagePath = params.rootPath or vim.fn.stdpath("cache") .. "/kotlin" }
  end,
  settings = { kotlin = { compiler = { jvm = { target = "21" } } } },
})

-- nvim-jdtls owns Java startup and its project-specific workspace.
vim.lsp.enable({ "ts_ls", "jdtls" }, false)
require("mason-lspconfig").setup({
  ensure_installed = {
    "lua_ls",
    "vtsls",
    "angularls",
    "eslint",
    "elixirls",
    "rust_analyzer",
    "gopls",
    "pyright",
    "jdtls",
    "kotlin_language_server",
    "clangd",
  },
  automatic_enable = { exclude = { "ts_ls", "jdtls" } },
})

-- Keep lspconfig's filetype and project discovery rules.
vim.lsp.config("sourcekit", { filetypes = { "swift", "objc", "objcpp" } })
if vim.fn.executable("sourcekit-lsp") == 1 then
  vim.lsp.enable("sourcekit")
elseif vim.fn.executable("xcrun") == 1 then
  local result = vim.system({ "xcrun", "--find", "sourcekit-lsp" }, { text = true }):wait()
  if result.code == 0 then
    vim.lsp.config("sourcekit", { cmd = { vim.trim(result.stdout) } })
    vim.lsp.enable("sourcekit")
  end
end
if vim.fn.executable("ocamllsp") == 1 then
  vim.lsp.enable("ocamllsp")
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dotfiles.java", { clear = true }),
  pattern = "java",
  callback = function(event)
    if vim.fn.executable("jdtls") ~= 1 then
      return
    end
    local root = vim.fs.root(event.buf, {
      { "mvnw", "gradlew", "settings.gradle", "settings.gradle.kts", ".git" },
      { "pom.xml", "build.gradle", "build.gradle.kts" },
    }) or vim.fs.dirname(vim.api.nvim_buf_get_name(event.buf))
    -- Hash the full root so identically named projects never share a workspace.
    local workspace = vim.fn.stdpath("cache") .. "/jdtls/" .. vim.fn.sha256(root):sub(1, 16)
    require("jdtls").start_or_attach({
      cmd = { "jdtls", "-data", workspace },
      root_dir = root,
      settings = {
        java = {
          signatureHelp = { enabled = true },
          completion = {
            favoriteStaticMembers = {
              "org.junit.Assert.*",
              "org.junit.jupiter.api.Assertions.*",
              "java.util.Objects.requireNonNull",
              "java.util.Objects.requireNonNullElse",
            },
          },
          sources = { organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 } },
        },
      },
    })
  end,
})
