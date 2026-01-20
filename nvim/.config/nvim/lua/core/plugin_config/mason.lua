-- run :h mason-introduction
require("mason").setup({
  -- we can add more registries where 
  -- mason will find packages the order
  -- matters, first registries added 
  -- will have precedence:
  registries = {
    "github:mason-org/mason-registry"
  }
})

-- require("mason-lspconfig").setup {
--     automatic_enable = {
--         "ts_ls",
--         "prettier",
--         "eslint_lsp"
--     }
-- }

