vim.pack.add {
  GH 'nvim-tree/nvim-tree.lua',
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
