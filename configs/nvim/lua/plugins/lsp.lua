-- LSP configuration: disable inlay hints
return {
  -- Disable inlay hints globally
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = {
        enabled = false,
      },
    },
  },
}
