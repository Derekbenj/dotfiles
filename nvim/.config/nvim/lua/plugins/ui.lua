-- lua/plugins/ui.lua
return {
  -- Smooth scroll animation for page/half-page jumps.
  {
    "folke/snacks.nvim",
    opts = {
      scroll = {
        enabled = true,
        animate = { duration = { step = 5, total = 100 }, easing = "linear" },
      },
      terminal = {
        win = { position = "bottom" },
      },
      dashboard = {
        preset = {
          header = [[
   
      ██╗  ██╗██╗███╗   ██╗ ██████╗ 
      ██║ ██╔╝██║████╗  ██║██╔════╝ 
      █████╔╝ ██║██╔██╗ ██║██║  ███╗
      ██╔═██╗ ██║██║╚██╗██║██║   ██║
      ██║  ██╗██║██║ ╚████║╚██████╔╝
      ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 
                                    
      ██╗    ██╗ █████╗ ██████╗ ██████╗ 
      ██║    ██║██╔══██╗██╔══██╗██╔══██╗
      ██║ █╗ ██║███████║██████╔╝██║  ██║
      ██║███╗██║██╔══██║██╔══██╗██║  ██║
      ╚███╔███╔╝██║  ██║██║  ██║██████╔╝
       ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ 
                                        
          ]],
        },
      },
    },
    keys = {
      {
        "<C-_>",
        function()
          Snacks.terminal()
        end,
        desc = "Toggle terminal",
        mode = { "n", "t" },
      },
      {
        "<C-/>",
        function()
          Snacks.terminal()
        end,
        desc = "Toggle terminal",
        mode = { "n", "t" },
      },
    },
  },

  -- Smear cursor: Neovide-like cursor trail that works in Ghostty.
  -- The cursor leaves a fading "ghost" as it moves, making jumps
  -- feel fluid instead of teleporting between lines.
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      stiffness = 0.8, -- higher = snappier, lower = floatier
      trailing_stiffness = 0.5,
      trailing_exponent = 0, -- uniform fade (no acceleration)
      distance_stop_animating = 0.5,
      hide_target_hack = false, -- Ghostty handles cursor rendering well
    },
  },

  -- Minimal lualine: mode, branch, filepath, diagnostics, filetype, progress.
  -- Drops: time, noice, dap, lazy updates, encoding, git diff, profiler, etc.
  {
    "nvim-lualine/lualine.nvim",
    opts = function()
      return {
        options = {
          theme = "auto",
          globalstatus = true,
          disabled_filetypes = {
            statusline = { "dashboard", "alpha", "ministarter", "snacks_dashboard" },
          },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch" },
          lualine_c = { { LazyVim.lualine.pretty_path() } },
          lualine_x = { "diagnostics" },
          lualine_y = { "filetype" },
          lualine_z = { "progress", "location" },
        },
      }
    end,
  },
}
