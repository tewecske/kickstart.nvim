local gitsigns = require 'gitsigns'

gitsigns.setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },

  -- gitsigns defines no keymaps of its own; this is the documented hook.
  on_attach = function(bufnr)
    -- ]c / [c are builtin diff-mode motions. In a diff (fugitive's :Gdiffsplit,
    -- nvim -d) keep the real thing; everywhere else jump between git hunks.
    local function nav(dir, builtin)
      return function()
        if vim.wo.diff then
          vim.cmd('normal! ' .. vim.v.count1 .. builtin)
        else
          gitsigns.nav_hunk(dir)
        end
      end
    end

    vim.keymap.set('n', ']c', nav('next', ']c'), { buffer = bufnr, desc = 'Next git hunk' })
    vim.keymap.set('n', '[c', nav('prev', '[c'), { buffer = bufnr, desc = 'Previous git hunk' })
  end,
}
