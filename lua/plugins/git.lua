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

-- Every hunk in the repo into the quickfix list. From there core's bracket
-- defaults do the walking: ]q / [q step hunk by hunk, and ]<C-Q> / [<C-Q>
-- (:cnfile / :cpfile) jump straight to the next/previous *file* with changes.
vim.keymap.set('n', '<leader>gq', function()
  gitsigns.setqflist 'all'
end, { desc = '[G]it hunks to [q]uickfix (whole repo)' })

vim.keymap.set('n', '<leader>gQ', function()
  gitsigns.setqflist(0)
end, { desc = '[G]it hunks to [Q]uickfix (this buffer)' })

vim.keymap.set('n', '<leader>gs', vim.cmd.Git, { desc = '[G]it [s]tatus (fugitive)' })
