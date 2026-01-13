-- Simple treesitter setup for nvim 0.9.5+ compatibility
local status, treesitter = pcall(require, 'nvim-treesitter')
if not status then
  return
end

treesitter.setup {
  highlight = { enable = true },
  indent = { enable = true },
}

-- Install parsers manually for better compatibility
local parsers = {
  'c', 'lua', 'vim', 'vimdoc', 'query', 
  'python', 'java', 'javascript', 'go', 'rust', 'typescript', 'ruby'
}

for _, parser in ipairs(parsers) do
  vim.defer_fn(function()
    pcall(vim.cmd, 'TSInstall ' .. parser)
  end, 100)
end
