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
  {
    'nvim-treesitter/nvim-treesitter',
    lazy = false,
    build = ':TSUpdate'
  },
  { "nvim-tree/nvim-web-devicons", opts = {} },
	{'nvim-lualine/lualine.nvim', dependencies = { 'nvim-tree/nvim-web-devicons' }},
  {'nvim-telescope/telescope.nvim', version = '0.2.1', dependencies = { 'nvim-lua/plenary.nvim' }},
  "github/copilot.vim",
  "christoomey/vim-tmux-navigator",
  "hrsh7th/nvim-cmp",
  "hrsh7th/cmp-nvim-lsp",
  "hrsh7th/cmp-path",
  "L3MON4D3/LuaSnip",
  "saadparwaiz1/cmp_luasnip",
  "rafamadriz/friendly-snippets",
  "windwp/nvim-autopairs",
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
    version = "v1.9.0",
    dependencies = {
      "williamboman/mason.nvim",
      "nvimtools/none-ls.nvim",
    }
  },
  {
    'zadirion/Unreal.nvim',
    dependencies = {
      'tpope/vim-dispatch',
    }
  },
  --  ==========================================
  -- Mason untuk mengelola LSP servers, DAP servers, linters, dan formatters
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup({
        ui = {
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
    end
  },
  --  =============================================
  -- Mason LSP config
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "html",           -- HTML language server
          "cssls",          -- CSS language server
          "tailwindcss",    -- Tailwind CSS language server
          "eslint",         -- ESLint language server
          "jsonls",         -- JSON language server
          "pyright",        -- Python language server
        },
        automatic_installation = true,
      })
    end
  },
  --  ============================================
  -- Snippet collections (must be loaded first)
  {
    "rafamadriz/friendly-snippets",
    lazy = false,
    priority = 1000,
  },
  --  =============================================
  -- Autocompletion + snippet setup
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-nvim-lsp-signature-help",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "saadparwaiz1/cmp_luasnip",
      {
        "L3MON4D3/LuaSnip",
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
          -- Load friendly-snippets
          require("luasnip.loaders.from_vscode").lazy_load({ 
            paths = { vim.fn.stdpath("data") .. "/lazy/friendly-snippets" } 
          })
        end,
      },
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = {
          ["<C-j>"] = cmp.mapping.select_next_item(),
          ["<C-k>"] = cmp.mapping.select_prev_item(),
          ["<C-d>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<Tab>"] = cmp.mapping.select_next_item(),
          ["<S-Tab>"] = cmp.mapping.select_prev_item(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
        },
        sources = {
          { name = "nvim_lsp" },
          { name = "nvim_lsp_signature_help" },
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        },
      })
    end,
  },
  --  ============================================
  -- Enhanced TypeScript/React/Next.js support
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      require("typescript-tools").setup({
        capabilities = capabilities,
        settings = {
          -- TypeScript settings
          typescript = {
            inlayHints = {
              includeInlayParameterNameHints = "all",
              includeInlayParameterNameHintsWhenArgumentMatchesName = false,
              includeInlayFunctionParameterTypeHints = true,
              includeInlayVariableTypeHints = true,
              includeInlayPropertyDeclarationTypeHints = true,
              includeInlayFunctionLikeReturnTypeHints = true,
            },
          },
          -- React/JSX settings
          jsx_close_tag = {
            enable = true,
            filetypes = { "javascriptreact", "typescriptreact" },
          },
        },
        filetypes = {
          "javascript",
          "javascriptreact", 
          "typescript",
          "typescriptreact",
          "vue",
        },
      })
    end,
  },
}

local opts = {}

require("lazy").setup(plugins, opts)
