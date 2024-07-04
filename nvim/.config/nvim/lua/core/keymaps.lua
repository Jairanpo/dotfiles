vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.opt.backspace = '2'
vim.opt.showcmd = true
vim.opt.laststatus = 2
vim.opt.autowrite = true
vim.opt.cursorline = true
vim.opt.autoread = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.shiftround = true
vim.opt.expandtab = true

function SourceInitLua()
	vim.cmd('source $MYVIMRC')
end

vim.keymap.set('n', '<leader>r', function() SourceInitLua() end, {noremap = true, silent = true})

vim.api.nvim_set_keymap('n', '<leader><leader><leader>l', '<Plug>NetrwRefresh', {noremap = true, silent = true})

vim.keymap.set('n', '<leader>a', ':Ex<CR>')
vim.keymap.set('n', '<leader>0', '<C-w>0')
vim.keymap.set('n', '<C-h>', '<C-w>h', {noremap=true})
vim.keymap.set('n', '<C-j>', '<C-w>j', {noremap=true})
vim.keymap.set('n', '<C-k>', '<C-w>k', {noremap=true})
vim.keymap.set('n', '<C-l>', '<C-w>l', {noremap=true})

function EasySplit(key)
	if (key == 'h') then
		vim.opt.splitright = false
		vim.cmd('vsplit')
	end
	if (key == 'k') then
		vim.opt.splitbelow = false
		vim.cmd('split')
	end
	if (key == 'l') then
		vim.opt.splitright = true
		vim.cmd('vsplit')
	end
	if (key == 'j') then
		vim.opt.splitbelow = true
		vim.cmd('split')
	end
end

vim.keymap.set('n', '<leader>h', function() EasySplit("h") end, {noremap=true})
vim.keymap.set('n', '<leader>j', function() EasySplit("j") end, {noremap=true})
vim.keymap.set('n', '<leader>k', function() EasySplit("k") end, {noremap=true})
vim.keymap.set('n', '<leader>l', function() EasySplit("l") end, {noremap=true})
		
function ToggleLineNumbers()
	local number = vim.wo.number
	if (number == true) then
		vim.wo.number = false
	else
		vim.wo.number = true
	end
end

vim.keymap.set('n', '<leader>nu', function() ToggleLineNumbers() end, {noremap=true})
