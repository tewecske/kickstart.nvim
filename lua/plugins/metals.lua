-- Scala. nvim-metals drives Metals itself rather than going through
-- vim.lsp.enable, because it also owns the Metals-specific commands
-- (:MetalsInstall, BSP switching, doctor) that plain LSP has no notion of.
--
-- The `metals` binary comes from home-manager, not :MetalsInstall.

local metals_config = require('metals').bare_config()

metals_config.settings = {
  defaultBspToBuildTool = true,
  showImplicitArguments = true,
  showImplicitConversionsAndClasses = true,
  showInferredType = true,
  scalafmtConfigPath = '.scalafmt.conf',
  excludedPackages = { 'akka.actor.typed.javadsl', 'com.github.swagger.akka.javadsl' },
}

metals_config.init_options.statusBarProvider = 'off'

-- No `capabilities` override: it used to broadcast cmp-nvim-lsp's extras.
-- Core already advertises what the builtin completion needs, including
-- completionItem.snippetSupport.

vim.api.nvim_create_autocmd('FileType', {
  group = vim.api.nvim_create_augroup('my-metals', { clear = true }),
  pattern = { 'scala', 'sc', 'sbt', 'java' },
  callback = function()
    require('metals').initialize_or_attach(metals_config)
  end,
})
