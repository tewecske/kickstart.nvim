-- Colorscheme, statusline, file tree, keybind hints, editing textobjects.

vim.cmd.colorscheme 'catppuccin'
vim.cmd.hi 'Comment gui=none'

require('which-key').setup()
require('which-key').add {
  { '<leader>c', group = '[C]ode' },
  { '<leader>d', group = '[D]ocument' },
  { '<leader>r', group = '[R]ename' },
  { '<leader>s', group = '[S]earch' },
  { '<leader>u', group = 'S[u]rround' },
  { '<leader>w', group = '[W]orkspace' },
  { '<leader>t', group = '[T]oggle' },
  { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } },
}

require('lualine').setup {
  options = {
    icons_enabled = true,
    component_separators = '|',
    section_separators = '',
  },
  sections = {
    -- vim.lsp.status() replaces fidget.nvim: it aggregates the $/progress
    -- messages every attached server sends. `:h vim.lsp.status()`
    lualine_x = { vim.lsp.status },
    lualine_a = {
      {
        'buffers',
      },
    },
    lualine_c = {
      {
        'filename',
        path = 1,
      },
    },
  },
}

require('nvim-tree').setup {
  view = {
    width = 35,
    side = 'left',
    number = false,
    relativenumber = false,
  },
  renderer = {
    group_empty = true,
  },
  filters = {
    dotfiles = true,
  },
}

vim.keymap.set('n', '<leader>n', function()
  require('nvim-tree.api').tree.open { focus = true, find_file = true }
end, { silent = true, desc = 'Toggle tree' })

vim.api.nvim_create_autocmd('VimEnter', {
  group = vim.api.nvim_create_augroup('my-nvim-tree', { clear = true }),
  callback = function()
    require('nvim-tree.api').tree.open()
  end,
})

-- Better Around/Inside textobjects
--  - va)  - [V]isually select [A]round [)]paren
--  - yinq - [Y]ank [I]nside [N]ext [Q]uote
--  - ci'  - [C]hange [I]nside [']quote
require('mini.ai').setup { n_lines = 500 }

-- Add/delete/replace surroundings (brackets, quotes, etc.)
--  - <leader>uaiw) - S[u]rround [A]dd [I]nner [W]ord [)]Paren
--  - <leader>ud'   - S[u]rround [D]elete [']quotes
--  - <leader>ur)'  - S[u]rround [R]eplace [)] [']
require('mini.surround').setup {
  mappings = {
    add = '<leader>ua', -- Add surrounding in Normal and Visual modes
    delete = '<leader>ud', -- Delete surrounding
    find = '<leader>uf', -- Find surrounding (to the right)
    find_left = '<leader>uF', -- Find surrounding (to the left)
    highlight = '<leader>uh', -- Highlight surrounding
    replace = '<leader>ur', -- Replace surrounding

    suffix_last = 'l', -- Suffix to search with "prev" method
    suffix_next = 'n', -- Suffix to search with "next" method
  },
}
