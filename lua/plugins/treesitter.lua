-- nvim-treesitter, `main` branch.
--
-- The old config used the `master` branch API (`nvim-treesitter.configs`.setup
-- with highlight/indent/incremental_selection module tables). That branch is
-- frozen; `main` is the only one supporting 0.12 and it does none of that for
-- you: it installs parsers, and you turn features on yourself.
--
-- There is no `auto_install` any more, so this list is authoritative. Add a
-- language here and run `:TSInstall <lang>` (or restart).

local ts = require 'nvim-treesitter'

ts.setup {
  install_dir = vim.fn.stdpath 'data' .. '/site',
}

local wanted = {
  'bash',
  'c',
  'css',
  'diff',
  'go',
  'gomod',
  'gotmpl',
  'gowork',
  'html',
  'javascript',
  'json',
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'nix',
  'query',
  'scala',
  'sql',
  'templ',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'yaml',
}

-- Install only what is missing. `install()` unconditionally hits the network
-- for every language it is given, so passing the whole list every startup
-- would mean 26 downloads checked on every launch.
local ok, installed = pcall(ts.get_installed, 'parsers')
local missing = ok and vim.tbl_filter(function(lang)
  return not vim.tbl_contains(installed, lang)
end, wanted) or wanted

if #missing > 0 then
  ts.install(missing)
end

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('my-treesitter', { clear = true }),
  callback = function(event)
    -- No parser for this filetype: leave the buffer on regex syntax.
    if not pcall(vim.treesitter.start, event.buf) then
      return
    end

    -- Ruby's indent rules depend on the regex engine, matching what the old
    -- `indent = { disable = { 'ruby' } }` did.
    if event.match ~= 'ruby' then
      vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

require('treesitter-context').setup {
  multiline_threshold = 5,
}

-- Incremental selection, replacing nvim-treesitter's node_incremental /
-- node_decremental = v/V.
--
-- 0.12 exposes this as the `an` / `in` visual-mode textobjects, but those keys
-- are unusable here: mini.ai owns the a/i prefixes and reads `an` as "around
-- next" (that is what makes `yinq` work). So call the API directly instead of
-- mapping to keys that mini.ai intercepts.
vim.keymap.set('x', 'v', function()
  vim.treesitter.select('parent', vim.v.count1)
end, { desc = 'Expand selection to parent node' })

vim.keymap.set('x', 'V', function()
  vim.treesitter.select('child', vim.v.count1)
end, { desc = 'Shrink selection to child node' })
