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

local function git(cmd)
  local handle = io.popen(cmd)
  if handle == nil then
    return ''
  end
  local result = handle:read '*a'
  handle:close()
  return result
end

-- Absolute paths of every file with unstaged changes, in git's own order.
local function changed_files()
  local root = vim.trim(git 'git rev-parse --show-toplevel')
  local files = {}
  for _, rel in ipairs(vim.split(git 'git diff --name-only', '\n')) do
    if rel ~= '' then
      table.insert(files, vim.fs.normalize(root .. '/' .. rel))
    end
  end
  return files
end

-- Show files[idx] in the float, refreshing the title with the position.
local function show_diff(win, buf, files, idx)
  local path = files[idx]
  local lines = vim.split(git('git diff -- ' .. vim.fn.shellescape(path)), '\n')

  vim.api.nvim_set_option_value('modifiable', true, { buf = buf })
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

  local config = vim.api.nvim_win_get_config(win)
  config.title = string.format(' %s (%d/%d) ', vim.fn.fnamemodify(path, ':t'), idx, #files)
  vim.api.nvim_win_set_config(win, config)
  vim.api.nvim_win_set_cursor(win, { 1, 0 })
end

local function open_floating_git_diff()
  local path = vim.fs.normalize(vim.fn.expand '%:p')

  local files = changed_files()
  local current = nil
  for i, file in ipairs(files) do
    if file == path then
      current = i
    end
  end

  if current == nil then
    print 'No changes found'
    return
  end

  -- Create scratch buffer; show_diff fills it in once the window exists
  local buf = vim.api.nvim_create_buf(false, true)
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
    title = '',
    title_pos = 'center',
  }

  -- Open floating window
  local win = vim.api.nvim_open_win(buf, true, opts)

  -- ]f / [f walk the other changed files, wrapping around at either end.
  local function nav_file(step)
    return function()
      current = (current - 1 + step * vim.v.count1) % #files + 1
      show_diff(win, buf, files, current)
    end
  end

  vim.keymap.set('n', ']f', nav_file(1), { buffer = buf, desc = 'Next changed file' })
  vim.keymap.set('n', '[f', nav_file(-1), { buffer = buf, desc = 'Previous changed file' })

  show_diff(win, buf, files, current)
end

vim.api.nvim_create_user_command('GFloatDiff', open_floating_git_diff, {})
vim.keymap.set('n', '<leader>gd', vim.cmd.GFloatDiff, { desc = '[G]it [D]iff (float)' })
