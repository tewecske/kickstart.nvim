-- Snacks.nvim: picker, explorer, terminal and misc utilities.
-- Adapted from ornicar's dotfiles (picker.lua + snacks.lua) for a
-- vim.pack-based config with no LazyVim.

local snacks = require 'snacks'

-- Neovim 0.12 builtin autocomplete (`vim.o.autocomplete`) opens a completion
-- popup in the picker input and suppresses its TextChangedI filter handler,
-- breaking live filtering. Disable it for the picker input buffer.
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'snacks_picker_input',
  callback = function()
    vim.bo.autocomplete = false
  end,
})

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('snacks-lsp-attach', { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then
      return
    end

    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('gd', snacks.picker.lsp_definitions, '[G]oto [D]efinition')
    map('gr', snacks.picker.lsp_references, '[G]oto [R]eferences')
    map('gI', snacks.picker.lsp_implementations, '[G]oto [I]mplementation')
    map('<leader>D', snacks.picker.lsp_type_definitions, 'Type [D]efinition')
  end,
})

-- Custom picker layouts. Registered on the shared layouts table before setup.
local layouts = require 'snacks.picker.config.layouts'
layouts.full_horiz = {
  reverse = true,
  layout = {
    box = 'horizontal',
    width = 0.95,
    height = 0.9,
    border = 'none',
    {
      box = 'vertical',
      { win = 'list', title = ' Results ', title_pos = 'center', border = 'none' },
      { win = 'input', height = 1, border = 'none', title = '{title} {live} {flags}', title_pos = 'center' },
    },
    {
      win = 'preview',
      title = '{preview:Preview}',
      width = 0.6,
      border = 'none',
      title_pos = 'center',
    },
  },
}
layouts.full_vert = {
  layout = {
    backdrop = false,
    fullscreen = true,
    box = 'vertical',
    border = 'rounded',
    title = '{title} {live} {flags}',
    title_pos = 'center',
    { win = 'input', height = 1, border = 'bottom' },
    { win = 'list', border = 'none' },
    { win = 'preview', title = '{preview}', height = 0.4, border = 'top' },
  },
}

local large = { width = 0.95, height = 0.9 }

snacks.setup {
  styles = {
    lazygit = large,
    blame_line = large,
    notification_history = large,
  },
  picker = {
    sources = {
      explorer = {
        layout = {
          layout = {
            position = 'left',
          },
        },
      },
    },
    layout = {
      -- Use the default layout or vertical if the window is too narrow
      preset = function()
        return vim.o.columns >= 120 and 'full_horiz' or 'full_vert'
      end,
    },
    win = {
      -- input window
      input = {
        keys = {
          ['<Esc>'] = { 'close', mode = 'i' },
          ['<C-k>'] = { 'preview_scroll_up', mode = { 'i', 'n' } },
          ['<C-j>'] = { 'preview_scroll_down', mode = { 'i', 'n' } },
        },
      },
    },
  },
  terminal = {
    wo = {
      winhighlight = 'Normal:Normal',
    },
  },
  image = {},
  lazygit = {
    configure = true,
    config = {
      os = { editPreset = 'nvim-remote' },
    },
  },
  gh = {
    wo = {
      winhighlight = 'Normal:Normal',
    },
  },
  bigfile = {},
}

-- Project root: nearest ancestor with a project marker, else cwd. Replaces
-- LazyVim.root(), which also consults LSP workspace folders first.
local function root()
  local markers = { '.git', 'go.mod', 'package.json', 'Cargo.toml', 'pyproject.toml', 'pom.xml', 'build.gradle', 'lua' }
  return vim.fs.root(0, markers) or vim.uv.cwd()
end

-- Replaces LazyVim.pick(): returns a lazy function that, like the original,
-- resolves the project root unless root=false.
local function pick(command, opts)
  opts = opts or {}
  return function()
    opts = vim.deepcopy(opts)
    if not opts.cwd and opts.root ~= false then
      opts.cwd = root()
    end
    snacks.picker.pick(command, opts)
  end
end

local function buffer_dir()
  return vim.fn.expand '%:p:h'
end

local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { desc = desc })
end

-- files
map('n', '<leader>sf', pick('files', { root = false }), 'Find Files (cwd)')
map('n', '<leader>sF', pick 'files', 'Find Files (Root Dir)')
-- map('n', '<leader>mt', function()
-- pick('files', { cwd = buffer_dir() })()
-- end, 'Find Files (Buffer dir)')

-- grep
map('n', '<leader>sg', pick('live_grep', { root = false }), 'Grep (cwd)')
map('n', '<leader>sG', pick 'live_grep', 'Grep (Root Dir)')
-- map('n', '<leader><space>t', function()
-- pick('live_grep', { cwd = buffer_dir() })()
-- end, 'Grep (Buffer dir)')

-- word / selection
map('n', '<leader>sw', pick('grep_word', { root = false }), 'Word under cursor (cwd)')
map('x', '<leader>*', pick('grep_word', { root = false }), 'Search visual selection')
map({ 'n', 'x' }, '<leader>sW', pick 'grep_word', 'Word or selection (Root Dir)')
map('n', '<leader>T', function()
  pick('grep_word', { cwd = buffer_dir() })()
end, 'Word (Buffer dir)')

map('n', '<leader>sh', function()
  snacks.picker.help()
end, 'Help Pages')
map('n', '<leader>sk', function()
  snacks.picker.keymaps()
end, 'Keymaps')
map('n', '<leader>sd', function()
  snacks.picker.diagnostics()
end, 'Diagnostics')
map('n', '<leader>sr', function()
  snacks.picker.resume()
end, 'Resume')
map('n', '<leader>s.', function()
  snacks.picker.recent()
end, 'Recent Files')
map('n', '<leader><leader>', function()
  snacks.picker.buffers()
end, 'Buffers')

-- other pickers
map('n', '<leader>ss', function()
  snacks.picker.smart()
end, 'Smart picker')
map('n', '<leader>sc', function()
  snacks.picker.commands()
end, 'Commands')
map('n', '<leader>sn', function()
  snacks.picker.notifications()
end, 'Notification History')
map('n', '<leader>sy', function()
  snacks.picker.jumps()
end, 'Jumps')
map('n', '<leader>su', function()
  snacks.picker.undo()
end, 'Undo tree')
map('n', '<leader>sl', function()
  snacks.picker.loclist()
end, 'Location List')
map('n', '<leader>qf', function()
  snacks.picker.qflist()
end, 'Quickfix List')
map('n', '<leader>sI', function()
  snacks.picker.icons()
end, 'Icons')
map('n', '<leader>sp', function()
  snacks.picker.projects()
end, 'Projects')
map('n', '<leader>sH', function()
  snacks.picker.highlights()
end, 'Highlights')

-- lsp
map('n', '<leader>o', function()
  snacks.picker.lsp_symbols()
end, 'LSP Symbols')
map('n', '<leader>O', function()
  snacks.picker.lsp_workspace_symbols()
end, 'LSP Workspace Symbols')

-- git
map('n', '<leader>gc', function()
  snacks.picker.git_log()
end, 'Git Log')
map('n', '<leader>gd', function()
  snacks.picker.git_diff()
end, 'Git Diff (hunks)')
map('n', '<leader>gs', function()
  snacks.picker.git_status()
end, 'Git Status')

-- explorer
map('n', '<leader>e', function()
  snacks.explorer.open { cwd = root() }
end, 'Explorer Snacks (root dir)')
map('n', '<leader>E', function()
  snacks.explorer()
end, 'Explorer Snacks (cwd)')

require('which-key').add {
  { '<leader>s', group = 'Picker' },
}
