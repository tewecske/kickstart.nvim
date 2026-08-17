-- Neovim config. Requires 0.12+ (vim.pack, vim.lsp.config, 'autocomplete').
--
-- Plugins are managed by the builtin plugin manager, `:h vim.pack`. There is no
-- bootstrap step: clone this repo to ~/.config/nvim and start nvim.
--   :lua vim.pack.update()   update all, review in the tabpage, :w to confirm
--   :lua =vim.pack.get()     what is installed
-- Revisions are pinned in nvim-pack-lock.json, which is tracked in git.
--
-- Language servers and formatters are NOT installed from here. They come from
-- home-manager, ~/linstalls/home/common.nix.

-- netrw is replaced by nvim-tree
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Must happen before plugins are loaded
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

vim.g.have_nerd_font = false

-- [[ Options ]] see `:help option-list`

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = 'a'
vim.opt.showmode = false -- already in the statusline
vim.opt.clipboard = 'unnamedplus'
vim.opt.breakindent = true
vim.opt.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.signcolumn = 'yes'
vim.opt.updatetime = 150
vim.opt.timeoutlen = 300 -- also how soon which-key pops up
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = 'split' -- live substitution preview
vim.opt.cursorline = true
vim.opt.scrolloff = 10
vim.opt.hlsearch = true

vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.colorcolumn = '120'

-- [[ Completion ]] builtin, replaces the nvim-cmp stack. `:h ins-autocompletion`
--
-- 'complete' sources in priority order: o = 'omnifunc', which LSP sets per
-- buffer; then current buffer, other windows, other loaded buffers. The ^N
-- suffix caps how many candidates each source contributes.
vim.o.autocomplete = true
vim.o.complete = 'o^10,.^5,w^5,b^5'
vim.o.completeopt = 'menuone,noselect,popup,fuzzy'
vim.o.autocompletedelay = 100
vim.o.pummaxwidth = 60

-- [[ Keymaps ]]

vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

vim.keymap.set('n', '<leader>qq', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Completion menu navigation. <C-n>/<C-p> and <C-y> are builtin; these keep the
-- <C-j>/<C-k> and <CR> habits from nvim-cmp. Guarded on pumvisible() so they
-- fall through to a literal newline when no menu is open.
vim.keymap.set('i', '<C-j>', function()
  return vim.fn.pumvisible() == 1 and '<C-n>' or '<C-j>'
end, { expr = true })
vim.keymap.set('i', '<C-k>', function()
  return vim.fn.pumvisible() == 1 and '<C-p>' or '<C-k>'
end, { expr = true })
vim.keymap.set('i', '<CR>', function()
  return vim.fn.pumvisible() == 1 and '<C-y>' or '<CR>'
end, { expr = true })

vim.keymap.set('n', '<leader>,m', function()
  vim.cmd ':%s/\r//g'
end, { desc = 'Strip carriage returns' })

vim.keymap.set('n', '<C-Tab>', '<cmd>bn<CR>', { desc = 'Next buffer' })
vim.keymap.set('n', '<S-Tab>', '<cmd>bp<CR>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<C-q>', '<cmd>bd<CR>', { desc = 'Close buffer' })

-- Add empty lines before and after cursor line
vim.keymap.set('n', '[<space>', "<Cmd>call append(line('.') - 1, repeat([''], v:count1))<CR>", { desc = 'Put empty line above' })
vim.keymap.set('n', ']<space>', "<Cmd>call append(line('.'),     repeat([''], v:count1))<CR>", { desc = 'Put empty line below' })

vim.keymap.set('v', '*', '"sy/<C-R>s<CR>', { desc = 'Search for visually selected' })

-- Replaces code_runner.nvim
vim.keymap.set('n', '<leader>x', function()
  local runners = {
    go = 'go run .',
    lua = 'lua %',
    python = 'python3 %',
    sh = 'sh %',
  }
  local cmd = runners[vim.bo.filetype]
  if not cmd then
    return vim.notify('No runner for filetype ' .. vim.bo.filetype, vim.log.levels.WARN)
  end
  vim.cmd('split | terminal ' .. vim.fn.expandcmd(cmd))
end, { desc = 'e[x]ecute code' })

-- [[ Autocommands ]]

vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('my-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

-- [[ Plugins ]] `:h vim.pack`
--
-- Unlike lazy.nvim there is no dependency resolution and no lazy loading:
-- every plugin below is cloned and sourced at startup, in this order, so
-- shared dependencies have to come first.

GH = function(repo)
  return 'https://github.com/' .. repo
end

vim.pack.add {
  -- shared dependencies, first
  GH 'nvim-lua/plenary.nvim',
  GH 'nvim-neotest/nvim-nio',

  -- ui
  -- The repo is literally named "nvim", so without an explicit name it lands
  -- in a directory called "nvim" among the plugins. Same reason lazy-lock.json
  -- used to have a bare "nvim" entry.
  { src = GH 'catppuccin/nvim', name = 'catppuccin' },
  GH 'folke/which-key.nvim',
  GH 'lewis6991/gitsigns.nvim',
  GH 'nvim-lualine/lualine.nvim',
  GH 'echasnovski/mini.nvim',

  -- finding things
  { src = GH 'ThePrimeagen/harpoon', version = 'harpoon2' },

  -- syntax. `main` is the only branch supporting 0.12; `master` is frozen and
  -- its nvim-treesitter.configs API does not exist here.
  { src = GH 'nvim-treesitter/nvim-treesitter', version = 'main' },
  GH 'nvim-treesitter/nvim-treesitter-context',

  -- lsp. No nvim-lspconfig: server configs are in lsp/ in this repo.
  GH 'folke/lazydev.nvim',
  GH 'Bilal2453/luvit-meta',
  GH 'scalameta/nvim-metals',

  -- debugging
  GH 'mfussenegger/nvim-dap',
  GH 'rcarriga/nvim-dap-ui',
  GH 'leoluz/nvim-dap-go',

  -- misc
  GH 'tpope/vim-fugitive',
  { src = GH 'github/copilot.vim', version = 'release' },

  -- picker / explorer / terminal / misc utilities
  GH 'folke/snacks.nvim',
}

require 'plugins.ui'
-- require 'plugins.telescope'
-- require 'plugins.nvimtree'
require 'plugins.treesitter'
require 'plugins.lsp'
require 'plugins.metals'
require 'plugins.dap'
require 'plugins.git'
require 'plugins.harpoon'
require 'plugins.snacks'
-- copilot.vim needs no setup call, being on the runtimepath is enough.

-- [[ Commands ]]

vim.api.nvim_create_user_command('DiffClip', function()
  vim.cmd [[
    let ft=&ft
    leftabove vnew [Clipboard]
    setlocal bufhidden=wipe buftype=nofile noswapfile
    put +
    0d_
    " remove CR for Windows
    silent %s/\r$//e
    execute "set ft=" . ft
    diffthis
    wincmd p
    diffthis
  ]]
end, { desc = 'Compare Active File with Clipboard' })

-- vim: ts=2 sts=2 sw=2 et
