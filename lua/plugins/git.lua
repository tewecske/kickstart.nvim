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

local function open_floating_git_diff()
  local path = vim.fn.expand '%:p'

  -- Get the git diff for the current file
  local handle = io.popen('git diff -- ' .. vim.fn.shellescape(path))
  local result = ''
  if handle ~= nil then
    result = handle:read '*a'
    handle:close()
  end

  if result == '' then
    print 'No changes found'
    return
  end

  -- Split result into lines
  local lines = vim.split(result, '\n')

  -- Create scratch buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('filetype', 'diff', { buf = buf })

  -- Calculate dimensions
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  -- Window configuration
  local opts = {
    relative = 'editor',
    width = width,
    height = height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'rounded',
    title = ' ' .. vim.fn.fnamemodify(path, ':t') .. ' ',
    title_pos = 'center',
  }

  -- Open floating window
  vim.api.nvim_open_win(buf, true, opts)
end

vim.api.nvim_create_user_command('GFloatDiff', open_floating_git_diff, {})
vim.keymap.set('n', '<leader>gd', vim.cmd.GFloatDiff, { desc = '[G]it [D]iff (float)' })
