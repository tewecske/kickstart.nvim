-- https://github.com/luals/lua-language-server
-- Adapted from nvim-lspconfig's lsp/lua_ls.lua, plus the callSnippet setting
-- carried over from the old init.lua.
--
-- Neovim runtime types are NOT configured here: lazydev.nvim handles the
-- library paths lazily, which is much faster than pulling all of
-- 'runtimepath' into workspace.library.

---@type vim.lsp.Config
return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = {
    { '.emmyrc.json', '.luarc.json', '.luarc.jsonc' },
    { '.luacheckrc', '.stylua.toml', 'stylua.toml', 'selene.toml', 'selene.yml' },
    { '.git' },
  },
  settings = {
    Lua = {
      codeLens = { enable = true },
      hint = { enable = true, semicolon = 'Disable' },
      completion = { callSnippet = 'Replace' },
    },
  },
}
