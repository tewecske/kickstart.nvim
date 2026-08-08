-- https://github.com/tailwindlabs/tailwindcss-intellisense
-- Adapted from nvim-lspconfig's lsp/tailwindcss.lua.
--
-- Upstream's root_dir calls require('lspconfig.util') for insert_package_json
-- and root_markers_with_field, which we no longer have. Replaced with tiered
-- root_markers in the same priority order. The dropped part was the mix.lock /
-- Gemfile.lock probing for Elixir and Ruby projects.
--
-- The settings block below is not optional: the server errors out if
-- settings.tailwindCSS is absent.

---@type vim.lsp.Config
return {
  cmd = function(dispatchers, config)
    local cmd = 'tailwindcss-language-server'
    if (config or {}).root_dir then
      local local_cmd = vim.fs.joinpath(config.root_dir, 'node_modules/.bin', cmd)
      if vim.fn.executable(local_cmd) == 1 then
        cmd = local_cmd
      end
    end
    return vim.lsp.rpc.start({ cmd, '--stdio' }, dispatchers)
  end,
  -- filetypes copied and adjusted from tailwindcss-intellisense
  filetypes = {
    -- html
    'aspnetcorerazor',
    'astro',
    'astro-markdown',
    'blade',
    'clojure',
    'django-html',
    'htmldjango',
    'edge',
    'eelixir', -- vim ft
    'elixir',
    'ejs',
    'erb',
    'eruby', -- vim ft
    'gohtml',
    'gohtmltmpl',
    'haml',
    'handlebars',
    'hbs',
    'html',
    'htmlangular',
    'html-eex',
    'heex',
    'jade',
    'leaf',
    'liquid',
    'markdown',
    'mdx',
    'mustache',
    'njk',
    'nunjucks',
    'php',
    'razor',
    'slim',
    'twig',
    -- css
    'css',
    'less',
    'postcss',
    'sass',
    'scss',
    'stylus',
    'sugarss',
    -- js
    'javascript',
    'javascriptreact',
    'reason',
    'rescript',
    'typescript',
    'typescriptreact',
    -- mixed
    'vue',
    'svelte',
    'templ',
  },
  workspace_required = true,
  root_markers = {
    {
      'tailwind.config.js',
      'tailwind.config.cjs',
      'tailwind.config.mjs',
      'tailwind.config.ts',
    },
    {
      'postcss.config.js',
      'postcss.config.cjs',
      'postcss.config.mjs',
      'postcss.config.ts',
    },
    { 'package.json' },
    -- Fallback for tailwind v4, where tailwind.config.* is no longer required
    { '.git' },
  },
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
  },
  settings = {
    tailwindCSS = {
      validate = true,
      lint = {
        cssConflict = 'warning',
        invalidApply = 'error',
        invalidScreen = 'error',
        invalidVariant = 'error',
        invalidConfigPath = 'error',
        invalidTailwindDirective = 'error',
        recommendedVariantOrder = 'warning',
      },
      classAttributes = {
        'class',
        'className',
        'class:list',
        'classList',
        'ngClass',
      },
      includeLanguages = {
        eelixir = 'html-eex',
        elixir = 'phoenix-heex',
        eruby = 'erb',
        heex = 'phoenix-heex',
        htmlangular = 'html',
        templ = 'html',
      },
    },
  },
  before_init = function(_, config)
    config.settings = vim.tbl_deep_extend('keep', config.settings, {
      editor = { tabSize = vim.lsp.util.get_effective_tabstop() },
    })
  end,
}
