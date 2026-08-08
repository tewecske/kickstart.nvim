-- https://github.com/hrsh7th/vscode-langservers-extracted (vscode-html-language-server)
-- Adapted from nvim-lspconfig's lsp/html.lua. `filetypes` adds 'templ',
-- carried over from the old init.lua.
--
-- The server only returns completions when the client advertises
-- snippetSupport. Core sets that by default since it ships `vim.snippet`
-- (runtime/lua/vim/lsp/protocol.lua), so no capabilities override is needed.

---@type vim.lsp.Config
return {
  cmd = function(dispatchers, config)
    local cmd = 'vscode-html-language-server'
    if (config or {}).root_dir then
      local local_cmd = vim.fs.joinpath(config.root_dir, 'node_modules/.bin', cmd)
      if vim.fn.executable(local_cmd) == 1 then
        cmd = local_cmd
      end
    end
    return vim.lsp.rpc.start({ cmd, '--stdio' }, dispatchers)
  end,
  filetypes = { 'html', 'templ' },
  root_markers = { 'package.json', '.git' },
  settings = {},
  init_options = {
    provideFormatter = true,
    embeddedLanguages = { css = true, javascript = true },
    configurationSection = { 'html', 'css', 'javascript' },
  },
}
