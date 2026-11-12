vim.api.nvim_create_autocmd("PackChanged", {
  group = vim.api.nvim_create_augroup("dotfiles.pack", { clear = true }),
  callback = function(event)
    if event.data.spec.name == "nvim-treesitter" and event.data.kind == "update" then
      vim.schedule(function()
        require("nvim-treesitter").update()
      end)
    end
  end,
})

vim.pack.add({
  { src = "https://github.com/ribru17/bamboo.nvim" },
  { src = "https://github.com/dgrco/deepwater.nvim" },
  { src = "https://github.com/craftzdog/solarized-osaka.nvim" },
  { src = "https://github.com/ellisonleao/gruvbox.nvim" },
  { src = "https://github.com/projekt0n/github-nvim-theme" },
  { src = "https://github.com/rose-pine/neovim" },
  { src = "https://github.com/nvim-mini/mini.pick" },
  { src = "https://github.com/nvim-mini/mini.visits" },
  { src = "https://github.com/nvim-mini/mini.completion" },
  { src = "https://github.com/nvim-mini/mini.snippets" },
  { src = "https://github.com/nvim-mini/mini.extra" },
  { src = "https://github.com/nvim-mini/mini.pairs" },
  { src = "https://github.com/nvim-mini/mini.surround" },
  { src = "https://github.com/nvim-mini/mini.statusline" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/stevearc/oil.nvim" },
  { src = "https://github.com/mason-org/mason-lspconfig.nvim" },
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/lewis6991/gitsigns.nvim" },
  { src = "https://github.com/tpope/vim-fugitive" },
  { src = "https://github.com/akinsho/toggleterm.nvim" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "main" },
  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/folke/which-key.nvim" },
  { src = "https://github.com/folke/lazydev.nvim" },
  { src = "https://github.com/dmmulroy/ts-error-translator.nvim" },
  { src = "https://github.com/mbbill/undotree" },
  { src = "https://github.com/mfussenegger/nvim-jdtls" },
  { src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects", version = "main" },
})

require("oil").setup({
  view_options = {
    show_hidden = true,
  },
})
require("toggleterm").setup({
  open_mapping = "<leader>tt",
  insert_mappings = false,
  direction = "float",
})
require("mini.pick").setup()
require("mini.visits").setup()
require("mini.extra").setup()
require("mini.snippets").setup()
require("mini.completion").setup()
require("mini.pairs").setup()
require("mini.surround").setup()
require("mini.statusline").setup()
require("gitsigns").setup({
  signcolumn = true,
  numhl = false,
  linehl = false,
  word_diff = false,
})
require("lazydev").setup()
require("ts-error-translator").setup()
require("which-key").setup()
