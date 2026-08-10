-- LSP, completion and formatting.
--
-- No nvim-lspconfig: server configs live in `lsp/*.lua` at the root of this
-- repo, which is a runtime directory Neovim reads natively (`:h lsp-config`).
-- No mason: every server below must be on PATH, installed by home-manager
-- from ~/linstalls/home/common.nix.

require('lazydev').setup {
  library = {
    -- Load luvit types when the `vim.uv` word is found
    { path = 'luvit-meta/library', words = { 'vim%.uv' } },
  },
}

vim.lsp.enable {
  'gopls',
  'lua_ls',
  'html',
  'htmx',
  'cssls',
  'tailwindcss',
  'emmet_language_server',
}

vim.diagnostic.config { virtual_text = true }
vim.cmd 'set completeopt+=noselect'

-- Metals attaches itself for scala/sbt/java, see lua/plugins/metals.lua.

vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('my-lsp-attach', { clear = true }),
  callback = function(event)
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if not client then
      return
    end

    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- Only the pickers are mapped here. These are already global defaults in
    -- 0.12 and were deleted from this config: grn rename, gra code action,
    -- grx codelens run, gri implementation, grt type definition, gO document
    -- symbol, K hover, i_CTRL-S signature help. See `:h lsp-defaults`.
    local builtin = require 'telescope.builtin'
    map('gd', builtin.lsp_definitions, '[G]oto [D]efinition')
    map('gr', builtin.lsp_references, '[G]oto [R]eferences')
    map('gI', builtin.lsp_implementations, '[G]oto [I]mplementation')
    map('<leader>D', builtin.lsp_type_definitions, 'Type [D]efinition')
    map('<leader>ds', builtin.lsp_document_symbols, '[D]ocument [S]ymbols')
    map('<leader>ws', builtin.lsp_dynamic_workspace_symbols, '[W]orkspace [S]ymbols')

    -- Insert-mode completion driven by the server, through Nvim's builtin
    -- completion machinery. Replaces nvim-cmp + cmp-nvim-lsp.
    if client:supports_method(vim.lsp.protocol.Methods.textDocument_completion) then
      vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
    end

    -- Highlight other references to the symbol under the cursor.
    if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
      local highlight_augroup = vim.api.nvim_create_augroup('my-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })
      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('my-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'my-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
      map('<leader>th', function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
      end, '[T]oggle Inlay [H]ints')
    end
  end,
})

-- [[ Formatting ]] replaces conform.nvim.
--
-- Everything formats over LSP except the two filetypes whose servers cannot
-- format: lua (lua_ls has no formatter, stylua reads .stylua.toml from the
-- file's directory upward) and templ.

---Run an external formatter over the buffer, keeping cursor position.
---@param bufnr integer
---@param cmd string[]
local function format_with(bufnr, cmd)
  if vim.fn.executable(cmd[1]) == 0 then
    vim.notify(('%s not found on PATH, skipping format'):format(cmd[1]), vim.log.levels.WARN)
    return
  end

  local input = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n') .. '\n'
  local result = vim.system(cmd, { stdin = input, text = true }):wait(3000)

  if result.code ~= 0 then
    vim.notify(('%s failed: %s'):format(cmd[1], result.stderr or ''), vim.log.levels.ERROR)
    return
  end

  local formatted = vim.split((result.stdout or ''):gsub('\n$', ''), '\n')
  if #formatted == 1 and formatted[1] == '' then
    return -- never blank the buffer on an empty result
  end

  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, formatted)
  vim.fn.winrestview(view)
end

---@param bufnr integer?
local function format(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ft = vim.bo[bufnr].filetype

  -- Languages without a well standardized coding style.
  if ft == 'c' or ft == 'cpp' then
    return
  end

  if ft == 'lua' then
    -- `-` reads stdin; `--stdin-filepath` is what makes stylua find .stylua.toml
    return format_with(bufnr, {
      'stylua',
      '--stdin-filepath',
      vim.api.nvim_buf_get_name(bufnr),
      '-',
    })
  end

  if ft == 'templ' then
    return format_with(bufnr, { 'templ', 'fmt' })
  end

  -- vim.lsp.buf.format() reports "no matching language servers" on every save
  -- of a buffer without one, which is most scratch buffers, so ask first.
  local can_format = vim.lsp.get_clients {
    bufnr = bufnr,
    method = vim.lsp.protocol.Methods.textDocument_formatting,
  }
  if #can_format == 0 then
    return
  end

  -- These are upper bounds, not waits: format returns as soon as the server
  -- answers. 2s covers a server that is still warming up on the first save
  -- after opening a project — the old conform setting of 500ms did not.
  --
  -- Scala/sbt are formatted by Metals, which hosts scalafmt and reads the
  -- workspace .scalafmt.conf. The first format of a workspace downloads the
  -- scalafmt version pinned there, so give it much more headroom.
  local timeout_ms = (ft == 'scala' or ft == 'sbt') and 10000 or 2000
  vim.lsp.buf.format { bufnr = bufnr, timeout_ms = timeout_ms }
end

vim.api.nvim_create_autocmd('BufWritePre', {
  group = vim.api.nvim_create_augroup('my-format-on-save', { clear = true }),
  callback = function(event)
    format(event.buf)
  end,
})

vim.keymap.set('n', '<leader>f', function()
  format()
end, { desc = '[F]ormat buffer' })
