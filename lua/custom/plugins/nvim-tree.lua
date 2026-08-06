return {
  'nvim-tree/nvim-tree.lua',
  -- lazy = true,
  keys = {
    {
      '<leader>n',
      function()
        require('nvim-tree.api').tree.open {
          focus = true,
          find_file = true,
        }
      end,
      mode = 'n',
      silent = true,
      desc = 'toggle tree',
    },
  },
  config = function()
    require('nvim-tree').setup {
      view = {
        width = 40,
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
  end,
  init = function()
    local function open_nvim_tree()
      require('nvim-tree.api').tree.open()
    end

    vim.api.nvim_create_autocmd({ 'VimEnter' }, { callback = open_nvim_tree })
  end,
}
