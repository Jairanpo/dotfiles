local cmp = require("cmp")

require("luasnip.loaders.from_vscode").lazy_load()

-- Setup autopairs for completion if available
local ok, autopairs = pcall(require, 'nvim-autopairs')
if ok then
  local cmp_autopairs = require('nvim-autopairs.completion.cmp')
  cmp.event:on('confirm_done', cmp_autopairs.on_confirm_done())
end

cmp.setup({
  -- Enable LSP snippets
  snippet = {
    expand = function(args)
      require('luasnip').lsp_expand(args.body)
    end,
  },
  
  -- Configure completion mapping
  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-o>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_next_item()
      elseif require('luasnip').expand_or_jumpable() then
        require('luasnip').expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif require('luasnip').jumpable(-1) then
        require('luasnip').jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  }),
  
  -- Configure completion sources with priority
  sources = cmp.config.sources({
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'luasnip', priority = 750 },
    { name = 'path', priority = 500 },
  }, {
    { name = 'buffer', priority = 250 },
  }),
  
  -- Configure formatting for TypeScript/JavaScript
  formatting = {
    format = function(entry, vim_item)
      -- Add kind icons and menu
      local kind_icons = {
        Text = "",
        Method = "",
        Function = "",
        Constructor = "",
        Field = "",
        Variable = "",
        Class = "",
        Interface = "",
        Module = "",
        Property = "",
        Unit = "",
        Value = "",
        Enum = "",
        Keyword = "",
        Snippet = "",
        Color = "",
        File = "",
        Reference = "",
        Folder = "",
        EnumMember = "",
        Constant = "",
        Struct = "",
        Event = "",
        Operator = "",
        TypeParameter = "",
      }
      
      vim_item.kind = string.format('%s %s', kind_icons[vim_item.kind], vim_item.kind)
      
      -- Add source information for better context
      vim_item.menu = ({
        buffer = "[Buffer]",
        nvim_lsp = "[LSP]",
        luasnip = "[Snippet]",
        path = "[Path]",
      })[entry.source.name]
      
      return vim_item
    end
  },
  
  -- Configure completion behavior
  window = {
    completion = cmp.config.window.bordered(),
    documentation = cmp.config.window.bordered(),
  },
  
  -- Configure experimental features
  experimental = {
    ghost_text = true,
  },
})

-- Setup completion for specific file types
cmp.setup.filetype({ 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' }, {
  sources = cmp.config.sources({
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'luasnip', priority = 750 },
    { name = 'path', priority = 500 },
    { name = 'npm', priority = 400 }, -- If you want npm package completion
  }, {
    { name = 'buffer', priority = 250 },
  }),
})
