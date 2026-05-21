-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Make <C-c> behave like <Esc> in insert mode.
-- <C-c> doesn't fire InsertLeave, which breaks diagnostics
-- (update_in_insert=false suppresses them in insert mode and
-- relies on InsertLeave to re-enable them).
vim.keymap.set("i", "<C-c>", "<Esc>")

-- Open a focusable diagnostic float and jump cursor into it.
-- Useful for copying error text or scrolling long messages.
-- The CursorHold auto-float is non-focusable (just a preview);
-- press "gl" when you actually want to interact with the diagnostic.
vim.keymap.set("n", "gl", function()
  -- Close any existing non-focusable floats (the CursorHold auto-popup)
  -- before opening the focusable one, so they don't stack/glitch.
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local config = vim.api.nvim_win_get_config(win)
    if config.relative ~= "" and not config.focusable then
      vim.api.nvim_win_close(win, true)
    end
  end
  local _, win = vim.diagnostic.open_float({
    focusable = true,
    border = "rounded",
    source = true,
    scope = "line",
    max_width = 80,
  })
  if win then
    vim.api.nvim_set_current_win(win)
  end
end, { desc = "Open line diagnostics (focusable)" })
