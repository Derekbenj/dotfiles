return {
  {
    "nvim-neotest/neotest",
    opts = {
      adapters = {
        ["neotest-python"] = {
          runner = "pytest",
          -- Automatically find the .venv in the project root.
          python = function()
            local current_dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
            local root_file = vim.fs.find({ "pyproject.toml" }, {
              path = current_dir,
              upward = true,
              stop = vim.env.HOME,
              type = "file",
            })[1]
            if root_file then
              return vim.fs.dirname(root_file) .. "/.venv/bin/python"
            end
            return "python3"
          end,
        },
      },
    },
  },
}
