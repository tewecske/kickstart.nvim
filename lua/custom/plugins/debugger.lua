return {
  {
    'mfussenegger/nvim-dap',
    init = function()
      -- Breakpoint and continue
      vim.keymap.set('n', '<Leader>db', ':DapToggleBreakpoint<CR>', { noremap = true, silent = true })
      vim.keymap.set('n', '<Leader>dc', ':DapContinue<CR>', { noremap = true, silent = true })
      vim.keymap.set('n', '<leader>dus', function()
        local widgets = require 'dap.ui.widgets'
        local sidebar = widgets.sidebar(widgets.scopes)
        sidebar.open()
      end)
    end,
  },
  {
    'leoluz/nvim-dap-go',
    ft = 'go',
    dependencies = 'mfussenegger/nvim-dap',
    config = function(_, opts)
      require('dap-go').setup(opts)
      vim.keymap.set('n', '<leader>dgt', function()
        require('dap-go').debug_test()
      end)
      vim.keymap.set('n', '<leader>dgl', function()
        require('dap-go').debug_last()
      end)
    end,
  },
}
