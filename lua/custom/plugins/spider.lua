return {
  'chrisgrieser/nvim-spider',
  -- lazy = true,
  config = function()
    local spider = require 'spider'

    spider.setup {
      skipInsignificantPunctuation = false,
      consistentOperatorPending = false, -- see "Consistent Operator-pending Mode" in the README
      subwordMovement = true,
      customPatterns = {}, -- check "Custom Movement Patterns" in the README for details
    }

    -- "<cmd>lua require('spider').motion('w')<CR>"
    vim.keymap.set({ 'n', 'o', 'x' }, 'w', function()
      spider.motion 'w'
    end, { desc = 'Spider-w' })

    -- "<cmd>lua require('spider').motion('e')<CR>"
    vim.keymap.set({ 'n', 'o', 'x' }, 'e', function()
      spider.motion 'e'
    end, { desc = 'Spider-e' })

    -- "<cmd>lua require('spider').motion('b')<CR>"
    vim.keymap.set({ 'n', 'o', 'x' }, 'b', function()
      spider.motion 'b'
    end, { desc = 'Spider-b' })
  end,
}
