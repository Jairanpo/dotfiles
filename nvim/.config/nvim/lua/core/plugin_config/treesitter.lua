-- Setup nvim-treesitter with the new API
require'nvim-treesitter'.setup {
  install_dir = vim.fn.stdpath('data') .. '/site'
}

-- Install parsers asynchronously
require'nvim-treesitter'.install {
  'c',
  'lua',
  'vim',
  'vimdoc',
  'query',
  'python',
  'java',
  'javascript',
  'go',
  'rust',
  'typescript',
  'ruby'
}

-- Enable treesitter highlighting for all filetypes
vim.api.nvim_create_autocmd('FileType', {
  pattern = '*',
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local ft = vim.bo[buf].filetype

    -- Skip highlighting for c and rust as specified in original config
    if ft ~= 'c' and ft ~= 'rust' then
      -- Disable for large files (> 100KB)
      local max_filesize = 100 * 1024
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
      if not (ok and stats and stats.size > max_filesize) then
        pcall(vim.treesitter.start)
      end
    end
  end,
})
