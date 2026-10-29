local theme_path = vim.fn.stdpath("cache") .. "/lazygit-theme.yml"

return {
  {
    "folke/snacks.nvim",
    opts = {
      lazygit = {
        theme_path = theme_path,
        -- Load the renderer YAML directly; Snacks generates the theme YAML.
        args = {
          "--use-config-file",
          vim.fn.stdpath("config") .. "/lazygit.yml," .. theme_path,
        },
      },
    },
  },
}
