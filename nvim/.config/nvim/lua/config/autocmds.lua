-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Show diagnostics in a floating window on CursorHold.
-- Non-focusable auto-popup that closes when you move.
-- For a focusable float you can jump into, use "gl" (see keymaps.lua).
vim.api.nvim_create_autocmd("CursorHold", {
  group = vim.api.nvim_create_augroup("float_diagnostics", { clear = true }),
  callback = function()
    local mode = vim.api.nvim_get_mode().mode
    if mode ~= "n" then
      return
    end
    -- Skip if any focusable float is open (hover docs, completion, etc.)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local config = vim.api.nvim_win_get_config(win)
      if config.relative ~= "" and config.focusable and vim.api.nvim_win_is_valid(win)
        and vim.api.nvim_buf_line_count(vim.api.nvim_win_get_buf(win)) > 0 then
        return
      end
    end
    vim.diagnostic.open_float({
      focusable = false,
      close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
      border = "rounded",
      source = true,
      prefix = " ",
      scope = "line",
      max_width = 80,
    })
  end,
})
