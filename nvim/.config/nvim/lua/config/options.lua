-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- How quickly CursorHold fires (ms). Controls the delay before the
-- floating diagnostic window appears. LazyVim defaults to 200 but
-- that can feel jumpy — 300 is a comfortable middle ground.
vim.opt.updatetime = 300

-- Disable inlay hints by default. They add visual noise and cause
-- noticeable lag in Rust (rust-analyzer renders them for every binding).
-- Toggle on/off anytime with <leader>uh.
vim.g.lazyvim_no_inlay_hints = true

