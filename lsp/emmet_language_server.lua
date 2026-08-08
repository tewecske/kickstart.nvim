-- https://github.com/olrtg/emmet-language-server
-- Adapted from nvim-lspconfig's lsp/emmet_language_server.lua.
-- `filetypes` is the list carried over from the old init.lua rather than
-- upstream's: it adds javascript/pug/templ and drops the frameworks not in use.

---@type vim.lsp.Config
return {
  cmd = { 'emmet-language-server', '--stdio' },
  filetypes = {
    'css',
    'eruby',
    'html',
    'javascript',
    'javascriptreact',
    'less',
    'sass',
    'scss',
    'pug',
    'typescriptreact',
    'templ',
  },
  root_markers = { '.git' },
}
