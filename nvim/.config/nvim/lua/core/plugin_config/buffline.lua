vim.opt.termguicolors = true

require("bufferline").setup{}

vim.keymap.set('n', '<leader>1', ':BufferLineGoToBuffer 1<CR>')
vim.keymap.set('n', '<leader>2', ':BufferLineGoToBuffer 2<CR>')
vim.keymap.set('n', '<leader>3', ':BufferLineGoToBuffer 3<CR>')
vim.keymap.set('n', '<leader>4', ':BufferLineGoToBuffer 4<CR>')
vim.keymap.set('n', '<leader>5', ':BufferLineGoToBuffer 5<CR>')
vim.keymap.set('n', '<leader>6', ':BufferLineGoToBuffer 6<CR>')
vim.keymap.set('n', '<leader>7', ':BufferLineGoToBuffer 7<CR>')
vim.keymap.set('n', '<leader>9', ':BufferLineGoToBuffer 8<CR>')
vim.keymap.set('n', '<leader>9', ':BufferLineGoToBuffer 9<CR>')
vim.keymap.set('n', '<leader>$', ':BufferLineGoToBuffer -1<CR>')

vim.keymap.set('n', '<leader>p', ':BufferLineCyclePrev <CR>')
vim.keymap.set('n', '<leader>n', ':BufferLineCycleNext <CR>')

vim.keymap.set('n', 'gD', ':BufferLinePickClose <CR>')
vim.keymap.set('n', '<leader>i', ':BufferLineCloseOthers <CR>')

