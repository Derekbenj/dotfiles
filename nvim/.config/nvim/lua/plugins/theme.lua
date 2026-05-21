return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "frappe",
      color_overrides = {
        frappe = {
          red = "#f04868",
          green = "#b8c840",
          yellow = "#d6bf6a",
          blue = "#6aaef0",
          base = "#353845",
          mauve = "#e08ab2",
          peach = "#d4a06a",
          teal = "#60c486",
          sky = "#60b8b0",
          lavender = "#9a8ad2",
          surface2 = "#585c6b",
          overlay0 = "#585c6b",
          overlay1 = "#585c6b",
          overlay2 = "#6c7086",
        },
      },
      custom_highlights = function(colors)
        return {
          ["@string.documentation"] = { fg = colors.overlay1, style = { "italic" } },
          ["@variable.parameter"] = { fg = colors.peach },
          ["@constant"] = { fg = colors.teal },
          ["@lsp.type.enumMember"] = { fg = colors.teal },
        }
      end,
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
