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

local plugins = {
  { 
    'olivercederborg/poimandres.nvim',
    lazy = false,
    priority = 1000,
    init = function()
      vim.cmd("colorscheme poimandres")
    end 
  },
  {"nvim-treesitter/nvim-treesitter", build = ":TSUpdate"},
  { "nvim-tree/nvim-web-devicons", opts = {} },
	{'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }},
  {'nvim-telescope/telescope.nvim', version = '0.1.5', dependencies = { 'nvim-lua/plenary.nvim' }},
  "github/copilot.vim",
  {
  "mason-org/mason.nvim",
  opts = {}
  },
  "christoomey/vim-tmux-navigator",
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-path",
  "L3MON4D3/LuaSnip",
  "saadparwaiz1/cmp_luasnip",
  "rafamadriz/friendly-snippets",
  "windwp/nvim-autopairs",
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason-lspconfig.nvim",
      "nvimtools/none-ls.nvim",
      "nvim-lua/plenary.nvim"
    }
  },
  {
    'stevearc/oil.nvim',
    opts = {},
    dependencies = { "nvim-tree/nvim-web-devicons" }
  },
  {'akinsho/bufferline.nvim', version = "*", dependencies = 'nvim-tree/nvim-web-devicons'},
  'mhartington/formatter.nvim',
  'terryma/vim-multiple-cursors',
  'buoto/gotests-vim',
  {
    "jay-babu/mason-null-ls.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "nvimtools/none-ls.nvim",
    }
  },
  {
  'zadirion/Unreal.nvim',
  dependencies = {
    'tpope/vim-dispatch',
  },
}
}

local opts = {}

require("lazy").setup(plugins, opts)
