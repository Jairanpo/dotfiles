require("mason-lspconfig").setup({
  ensure_installed = { "lua_ls", "tsserver", "gopls", "pyright" }
})

local lspconfig = require('lspconfig')

local lsp_defaults = lspconfig.util.default_config

lsp_defaults.capabilities = vim.tbl_deep_extend(
  'force',
  lsp_defaults.capabilities,
  require('cmp_nvim_lsp').default_capabilities()
)

require("lspconfig").lua_ls.setup {
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        library = {
          [vim.fn.expand "$VIMRUNTIME/lua"] = true,
          [vim.fn.stdpath "config" .. "/lua"] = true,
        },
      },
    },
  }
}

local on_attach = function(_, _)
  vim.keymap.set('n', '<leader>rn', vim.slp.buf.rename, {})
  vim.keymap.set('n', '<leader>ca', vim.slp.buf.code_action, {})

  vim.keymap.set('n', '<leader>gd', vim.slp.buf.definition, {})
  vim.keymap.set('n', '<leader>gi', vim.slp.buf.implementation, {})
  vim.keymap.set('n', '<leader>gr', require('telescope.builtin').lsp_references, {})
  vim.keymap.set('n', '<leader>K', vim.slp.buf.hover, {})
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()

require("lspconfig").rust_analyzer.setup({
  on_attach = on_attach,
  capabilities = capabilities
})

require("lspconfig").lua_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities
})

require("lspconfig").tsserver.setup({
  on_attach = on_attach,
  capabilities = capabilities
})
require("lspconfig").gopls.setup({
  on_attach = on_attach,
  capabilities = capabilities
})
require("lspconfig").pyright.setup({
  on_attach = on_attach,
  capabilities = capabilities
})


vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('UserLspConfig', {}),
  callback = function(ev)
    -- Enable completion triggered by <c-x><c-o>
    vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

    -- Buffer local mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    local opts = { buffer = ev.buf }
    vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
    vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
    vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
    vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
    vim.keymap.set('n', '<space>wl', function()
      print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
    end, opts)
    vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
    vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
    vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
    vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
    vim.keymap.set('n', '<space>f', function()
      vim.lsp.buf.format { async = true }
    end, opts)
  end,
})
