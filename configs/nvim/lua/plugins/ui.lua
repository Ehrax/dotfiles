-- UI customizations: disable animations, indent guides, etc.
return {
  -- Disable indent-blankline (indent guides)
  { "lukas-reineke/indent-blankline.nvim", enabled = false },

  -- Disable mini.indentscope (animated indent guides)
  { "nvim-mini/mini.indentscope", enabled = false },

  -- Configure snacks.nvim (LazyVim's utility plugin)
  {
    "folke/snacks.nvim",
    opts = {
      animate = { enabled = false },
      scroll = { enabled = false },
      indent = { enabled = false },
    },
  },

  -- Configure noice.nvim (command line UI)
  {
    "folke/noice.nvim",
    opts = {
      presets = {
        bottom_search = true,
        command_palette = true,
        long_message_to_split = true,
        lsp_doc_border = true,
      },
      -- Disable animations
      views = {
        cmdline_popup = {
          position = {
            row = 5,
            col = "50%",
          },
        },
      },
    },
  },

  -- Configure lualine (status line)
  {
    "nvim-lualine/lualine.nvim",
    opts = {
      options = {
        theme = "onedark",
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
      },
    },
  },

  -- Disable buffer line animations
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        always_show_bufferline = false,
      },
    },
  },
}
