return {
  -- Prevent nvim-lint from running extra linters on Rust files.
  -- rust-analyzer (via rustaceanvim) already handles diagnostics and clippy.
  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        rust = {},
      },
    },
  },

  -- probe-rs: embedded Rust debugging via Raspberry Pi Debug Probe.
  -- Adds a "probe-rs" DAP adapter alongside the default codelldb one.
  -- Use <leader>dc to start debugging; select "probe-rs" config when prompted.
  {
    "mfussenegger/nvim-dap",
    opts = function()
      local dap = require("dap")

      dap.adapters.probe_rs = {
        type = "server",
        port = "${port}",
        executable = {
          command = "probe-rs",
          args = { "dap-server", "--port", "${port}" },
        },
      }

      -- Default embedded debug config — update chip and target as needed.
      dap.configurations.rust = dap.configurations.rust or {}
      table.insert(dap.configurations.rust, {
        name = "probe-rs: embedded debug",
        type = "probe_rs",
        request = "launch",
        chip = "RP2350",
        cwd = "${workspaceFolder}",
        flashingConfig = { enabled = true },
        coreConfigs = {
          {
            programBinary = "${workspaceFolder}/target/thumbv8m.main-none-eabihf/debug/${workspaceFolderBasename}",
          },
        },
      })
    end,
  },
}
