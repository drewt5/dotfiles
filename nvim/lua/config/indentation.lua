local conform = require("conform")

-- Defaults belong to the formatter, including its choice of tabs versus spaces.
local defaults = {
  prettier = { width = 2 },
  stylua = { width = 4, tabs = true },
  ruff_format = { width = 4 },
  ["clang-format"] = { width = 4, tab_width = 8 },
  gofmt = { width = 8, tabs = true },
  rustfmt = { width = 4 },
  shfmt = { width = 4 },
  taplo = { width = 2 },
  swiftformat = { width = 4 },
  mix = { width = 2 },
  ocamlformat = { width = 2 },
  ["google-java-format"] = { width = 2 },
  ktfmt = { width = 2 },
  xmlformatter = { width = 2 },
}

local function apply(bufnr, style)
  vim.bo[bufnr].shiftwidth = style.width
  vim.bo[bufnr].softtabstop = -1
  vim.bo[bufnr].tabstop = style.tab_width or style.width
  vim.bo[bufnr].expandtab = not style.tabs
end

local function nearest(filename, names)
  return vim.fs.find(names, { path = vim.fs.dirname(filename), upward = true })[1]
end

local function stylua_style(filename)
  local path = nearest(filename, { "stylua.toml", ".stylua.toml" })
  if not path then
    local config = vim.env.XDG_CONFIG_HOME or vim.fn.expand("~/.config")
    for _, directory in ipairs({ config, config .. "/stylua" }) do
      for _, name in ipairs({ "stylua.toml", ".stylua.toml" }) do
        local candidate = directory .. "/" .. name
        if vim.uv.fs_stat(candidate) then
          path = candidate
          break
        end
      end
      if path then
        break
      end
    end
  end
  if not path then
    return
  end
  local style = vim.deepcopy(defaults.stylua)
  for _, line in ipairs(vim.fn.readfile(path)) do
    if line:match("^%s*%[") then
      break
    end
    local width = line:match("^%s*indent_width%s*=%s*(%d+)")
    local kind = line:match([=[^%s*indent_type%s*=%s*["'](%a+)["']]=])
    if width then
      style.width = tonumber(width)
    end
    if kind then
      style.tabs = kind == "Tabs"
    end
  end
  return style
end

local function configure(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) or vim.bo[bufnr].buftype ~= "" then
    return
  end
  local ft = vim.bo[bufnr].filetype
  local request = (vim.b[bufnr].dotfiles_indent_request or 0) + 1
  vim.b[bufnr].dotfiles_indent_request = request
  local names = conform.list_formatters_for_buffer(bufnr)
  local name = names[1]
  local style = defaults[name]
  if not style then
    return
  end
  apply(bufnr, style)
  local editorconfig = vim.b[bufnr].editorconfig
  if type(editorconfig) == "table" and (name == "prettier" or name == "stylua" or name == "shfmt") then
    for _, property in ipairs({ "indent_style", "indent_size", "tab_width" }) do
      if editorconfig[property] then
        require("editorconfig").properties[property](bufnr, editorconfig[property], editorconfig)
      end
    end
  end

  local filename = vim.api.nvim_buf_get_name(bufnr)
  if filename == "" then
    return
  end
  if name == "stylua" then
    local configured = stylua_style(filename)
    if configured then
      apply(bufnr, configured)
    end
    return
  end

  local info = conform.get_formatter_info(name, bufnr)
  if not info.available then
    return
  end
  local command = vim.fn.exepath(info.command)
  local args, parse, stdin
  local probe
  if name == "clang-format" then
    args = { command, "--assume-filename=" .. filename, "--dump-config" }
    parse = function(output)
      return {
        width = tonumber(output:match("\nIndentWidth:%s*(%d+)")),
        tab_width = tonumber(output:match("\nTabWidth:%s*(%d+)")),
        tabs = output:match("\nUseTab:%s*(%S+)") ~= "Never",
      }
    end
  elseif name == "prettier" then
    local script = vim.fs.dirname(vim.g.dotfiles_nvim_init) .. "/lua/config/prettier-indent.cjs"
    args = { "node", script, command, filename }
    parse = vim.json.decode
  elseif name == "ruff_format" then
    if vim.uv.fs_stat(filename) then
      args = { command, "check", "--show-settings", filename }
    else
      local config = nearest(filename, { "ruff.toml", ".ruff.toml", "pyproject.toml" })
      if not config then
        return
      end
      args = { command, "check", "--show-settings", "--config=" .. config, "--extension=toml:python", config }
    end
    parse = function(output)
      return {
        width = tonumber(output:match("formatter%.indent_width = (%d+)")),
        tabs = output:match("formatter%.indent_style = (%a+)") == "tab",
      }
    end
  elseif name == "rustfmt" then
    args = { command, "--print-config", "current", filename }
    stdin = ""
    parse = function(output)
      return {
        width = tonumber(output:match("tab_spaces%s*=%s*(%d+)")),
        tabs = output:match("hard_tabs%s*=%s*(%a+)") == "true",
      }
    end
  elseif name == "swiftformat" or name == "taplo" or name == "shfmt" then
    local config = nearest(
      filename,
      ({
        swiftformat = { ".swiftformat" },
        taplo = { ".taplo.toml", "taplo.toml" },
        shfmt = { ".editorconfig" },
      })[name]
    )
    if not config then
      return
    end
    probe = name == "shfmt" and {
      "if true; then",
      "echo first",
      "echo second",
      "fi",
    } or name == "swiftformat" and {
      "func example() {",
      "print(1)",
      "print(2)",
      "}",
    } or {
      "values = [",
      '"' .. string.rep("a", 80) .. '",',
      '"' .. string.rep("b", 80) .. '",',
      "]",
    }
    local tab_width = name == "swiftformat"
        and tonumber(table.concat(vim.fn.readfile(config), "\n"):match("%-%-tab%-?width%s+(%d+)"))
      or vim.bo[bufnr].tabstop
    parse = function(output)
      local prefix
      for line in output:gmatch("[^\n]+") do
        local candidate = line:match("^([ \t]+)%S")
        if candidate and (not prefix or #candidate < #prefix) then
          prefix = candidate
        end
      end
      if not prefix then
        return
      end
      local tabs = prefix:find("\t", 1, true) ~= nil
      return { width = tabs and (tab_width or style.width) or #prefix, tabs = tabs }
    end
  end
  if not args and not probe then
    return
  end

  local finish = vim.schedule_wrap(function(result)
    if
      not vim.api.nvim_buf_is_valid(bufnr)
      or vim.b[bufnr].dotfiles_indent_request ~= request
      or vim.api.nvim_buf_get_name(bufnr) ~= filename
      or vim.bo[bufnr].filetype ~= ft
    then
      return
    end
    if result.code ~= 0 then
      return
    end
    local ok, configured = pcall(parse, result.stdout)
    if ok and configured and configured.width and configured.width > 0 then
      apply(bufnr, configured)
    end
  end)
  if probe then
    conform.format_lines({ name }, probe, { bufnr = bufnr, async = true, quiet = true }, function(err, lines)
      finish({ code = err and 1 or 0, stderr = err and err.message, stdout = lines and table.concat(lines, "\n") or "" })
    end)
  else
    vim.system(args, { text = true, stdin = stdin, cwd = vim.fs.dirname(filename), timeout = 3000 }, finish)
  end
end

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("dotfiles.indentation", { clear = true }),
  callback = function(event)
    vim.schedule(function()
      configure(event.buf)
    end)
  end,
})

for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
  if vim.api.nvim_buf_is_loaded(bufnr) then
    configure(bufnr)
  end
end
