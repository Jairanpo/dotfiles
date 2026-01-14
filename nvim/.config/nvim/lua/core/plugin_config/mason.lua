local mason = require("mason")
local mason_lspconfig = require("mason-lspconfig")
local mason_null_ls = require("mason-null-ls")

-- Setup Mason
mason.setup({
  ui = {
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗"
    }
  }
})

-- Automatically install LSP servers
mason_lspconfig.setup({
  ensure_installed = {
    "ts_ls",             -- TypeScript language server (new name)
    "lua_ls",            -- Lua language server (for Neovim config)
    "html",              -- HTML language server
    "cssls",             -- CSS language server
    "jsonls",            -- JSON language server
  },
  automatic_installation = true,
  handlers = {
    -- Default handler for all servers
    function(server_name)
      require("lspconfig")[server_name].setup({
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
        on_attach = function(client, bufnr)
          -- Basic keymaps
          local opts = { noremap = true, silent = true, buffer = bufnr }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
        end
      })
    end,
    
    -- Custom handler for ts_ls (TypeScript)
    ["ts_ls"] = function()
      require("lspconfig").ts_ls.setup({
        capabilities = require("cmp_nvim_lsp").default_capabilities(),
        on_attach = function(client, bufnr)
          -- Basic keymaps
          local opts = { noremap = true, silent = true, buffer = bufnr }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
          vim.keymap.set('n', '<space>ca', vim.lsp.buf.code_action, opts)
          vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
        end,
        filetypes = { "typescript", "typescriptreact", "typescript.tsx", "javascript", "javascriptreact", "javascript.jsx" },
        settings = {
          typescript = {
            preferences = {
              includeCompletionsForModuleExports = true,
              includeCompletionsWithInsertText = true,
            }
          },
          javascript = {
            preferences = {
              includeCompletionsForModuleExports = true,
              includeCompletionsWithInsertText = true,
            }
          }
        }
      })
    end
  }
})

-- Setup null-ls tools
mason_null_ls.setup({
  ensure_installed = {
    "prettier",           -- Prettier formatter
    "eslint_d",           -- ESLint daemon (faster ESLint)
  },
  automatic_installation = true,
})