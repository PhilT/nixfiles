require'lspconfig'.purescriptls.setup {
  --on_attach = on_attach,
  cmd = { "npx", "purescript-language-server", "--stdio" },
  settings = {
    purescript = {
      addSpagoSources = true -- e.g. any purescript language-server config here
    }
  },
  flags = {
    debounce_text_changes = 150,
  }
}
