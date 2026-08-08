# nvim

Personal Neovim config. **Requires Neovim 0.12+.**

Originally kickstart.nvim, since stripped down: the plugin count went from 43 to
23 by deleting everything Neovim 0.12 now does in core.

## Install

```sh
git clone <this repo> ~/.config/nvim
nvim
```

There is no bootstrap step. `:h vim.pack` is builtin, so the first launch clones
every plugin listed in `init.lua` and writes `nvim-pack-lock.json`.

Language servers and formatters are **not** installed by Neovim — Mason is gone.
They come from home-manager, in `~/linstalls/home/common.nix`. If a server does
not start, check it is on `PATH` first.

## Layout

| | |
|---|---|
| `init.lua` | options, keymaps, autocmds, the `vim.pack.add` list |
| `lsp/*.lua` | one file per language server, read natively by Neovim (`:h lsp-config`) |
| `lua/plugins/*.lua` | plain setup modules, one `require` each from `init.lua` |

`lua/plugins/*.lua` are **not** plugin specs — they run `require('x').setup{}`
against plugins `vim.pack` has already put on the runtimepath.

## Managing plugins

```vim
:lua vim.pack.update()    " update all; review the diff, :w confirms / :q discards
:lua =vim.pack.get()      " what is installed
:lua vim.pack.del({'x'})  " remove, after deleting it from init.lua
```

`nvim-pack-lock.json` is tracked in git — commit it after updating.

## What core does now, that plugins used to

| Was | Now |
|---|---|
| lazy.nvim | `vim.pack` |
| mason, mason-lspconfig, mason-tool-installer, mason-nvim-dap | home-manager |
| nvim-lspconfig | `lsp/*.lua` + `vim.lsp.enable()` |
| nvim-cmp + 4 cmp sources | `'autocomplete'`, `'complete'`, `vim.lsp.completion` |
| LuaSnip, friendly-snippets | `vim.snippet` |
| conform.nvim | a `BufWritePre` autocmd in `lua/plugins/lsp.lua` |
| fidget.nvim | `vim.lsp.status()` in the lualine section |
| vim-sleuth | builtin EditorConfig (`:h editorconfig`) |
| treesitter `incremental_selection` | `:h v_an` / `v_in` |
| `<leader>rn` `<leader>ca` `<leader>cr` `<leader>ck` | `grn` `gra` `grx` `K` (`:h lsp-defaults`) |

Also removed outright: todo-comments, key-analyzer, code_runner, vim-obsession.
