-- LSP configuration: disable inlay hints
return {
  -- Disable inlay hints globally + disable marksman for markdown
  {
    "neovim/nvim-lspconfig",
    opts = {
      inlay_hints = {
        enabled = false,
      },
      servers = {
        marksman = {
          enabled = false,
        },
      },
    },
  },

  -- Disable markdownlint (MD013 line-length etc.)
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        markdown = {},
      },
    },
  },
}
