-- Scala. nvim-metals drives Metals itself rather than going through
-- vim.lsp.enable, because it also owns the Metals-specific commands
-- (:MetalsInstall, BSP switching, doctor) that plain LSP has no notion of.
--
-- The `metals` binary comes from home-manager, not :MetalsInstall.

local metals_config = require('metals').bare_config()

-- Build server: Bloop (Metals' default), NOT sbt.
--
-- `defaultBspToBuildTool = true` used to be set here, which routes Metals
-- through sbt's own BSP server. sbt serves one BSP client at a time over a
-- single socket (project/target/active.json), so a long-running `~fastLinkJS`
-- or `~reStart` watch task blocks Metals indefinitely — an import hangs on
-- buildTarget/dependencySources and eventually fails with MetalsBspException.
--
-- Bloop is a separate daemon, so watch tasks and the IDE stop contending. The
-- cost is compiling twice (Bloop for the IDE, sbt for the watch) and Metals
-- running `sbt bloopInstall` to export the build whenever build.sbt changes.
--
-- To go back, or if Metals remembers the wrong server: `:MetalsBspSwitch`.
metals_config.settings = {
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
