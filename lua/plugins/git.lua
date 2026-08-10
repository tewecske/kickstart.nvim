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

-- Command output as buffer lines, without the trailing newline's empty line.
local function lines_of(output)
  local lines = vim.split(output, '\n')
  if lines[#lines] == '' then
    table.remove(lines)
  end
  return lines
end

local function repo_root()
  return vim.fs.normalize(vim.trim(git 'git rev-parse --show-toplevel'))
end

-- Absolute paths of every file with unstaged changes, in git's own order.
local function changed_files()
  local root = repo_root()
  local files = {}
  for _, rel in ipairs(lines_of(git 'git diff --name-only')) do
    table.insert(files, vim.fs.normalize(root .. '/' .. rel))
  end
  return files
end

-- A floating view of `git diff`, in one of two shapes: a unified diff in a
-- single float, or index and working tree in two floats sharing that span,
-- driven by Vim's own diff mode. ]f / [f walk the changed files in either
-- shape, s switches between them, q closes the whole thing.
local function open_floating_git_diff()
  local path = vim.fs.normalize(vim.fn.expand '%:p')

  local root = repo_root()
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

  -- Calculate dimensions
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local side_by_side = false
  local wins = {}
  local closing = false

  local function close()
    closing = true
    for _, win in ipairs(wins) do
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end
    wins = {}
    closing = false
  end

  local show -- redraws the view for files[current]; defined below

  local function scratch(lines, filetype)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value('filetype', filetype, { buf = buf })
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })

    -- Wrap around at either end of the file list.
    local function nav(step)
      return function()
        current = (current - 1 + step * vim.v.count1) % #files + 1
        show()
      end
    end

    vim.keymap.set('n', '<C-j>', nav(1), { buffer = buf, desc = 'Next changed file' })
    vim.keymap.set('n', '<C-k>', nav(-1), { buffer = buf, desc = 'Previous changed file' })
    vim.keymap.set('n', 's', function()
      side_by_side = not side_by_side
      show()
    end, { buffer = buf, desc = 'Toggle side-by-side diff' })
    vim.keymap.set('n', 'q', close, { buffer = buf, desc = 'Close diff' })

    return buf
  end

  local function float(buf, opts)
    local win = vim.api.nvim_open_win(
      buf,
      true,
      vim.tbl_extend('force', {
        relative = 'editor',
        row = row,
        height = height,
        style = 'minimal',
        border = 'rounded',
        title_pos = 'center',
      }, opts)
    )
    table.insert(wins, win)

    -- Closing one half of the side-by-side view takes the other half with it.
    vim.api.nvim_create_autocmd('WinClosed', {
      pattern = tostring(win),
      once = true,
      callback = function()
        if not closing then
          close()
        end
      end,
    })

    return win
  end

  function show()
    close()

    local file = files[current]
    local title = string.format(' %s (%d/%d) ', vim.fn.fnamemodify(file, ':t'), current, #files)

    if not side_by_side then
      local diff = lines_of(git('git diff -- ' .. vim.fn.shellescape(file)))
      float(scratch(diff, 'diff'), { width = width, col = col, title = title })
      return
    end

    -- Two floats fit in the single float's span once each border's two
    -- columns are paid for.
    local left_width = math.floor((width - 2) / 2)
    local filetype = vim.filetype.match { filename = file } or ''
    local relative = file:sub(#root + 2)

    local index = lines_of(git('git show ' .. vim.fn.shellescape(':' .. relative)))
    local worktree = vim.fn.filereadable(file) == 1 and vim.fn.readfile(file) or {}

    float(scratch(index, filetype), { width = left_width, col = col, title = ' index ' })
    vim.cmd.diffthis()
    float(scratch(worktree, filetype), {
      width = width - 2 - left_width,
      col = col + left_width + 2,
      title = title,
    })
    vim.cmd.diffthis()
  end

  show()
end

vim.api.nvim_create_user_command('GFloatDiff', open_floating_git_diff, {})
vim.keymap.set('n', '<leader>gd', vim.cmd.GFloatDiff, { desc = '[G]it [D]iff (float)' })
