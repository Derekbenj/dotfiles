local function normalize_start_path(path)
  if type(path) == "number" then
    path = vim.api.nvim_buf_get_name(path)
  end

  if path == nil or path == "" then
    return vim.fn.getcwd()
  end

  if type(path) ~= "string" then
    return vim.fn.getcwd()
  end

  local stat = (vim.uv or vim.loop).fs_stat(path)
  if stat and stat.type == "file" then
    return vim.fs.dirname(path)
  end

  return path
end

local function find_venv_root(path)
  local dir = normalize_start_path(path)

  while dir and dir ~= "" and dir ~= vim.env.HOME do
    for _, python_name in ipairs({ "python", "python3" }) do
      local python = dir .. "/.venv/bin/" .. python_name
      if vim.fn.executable(python) == 1 then
        return dir, python
      end
    end

    local parent = vim.fs.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end

  return nil, nil
end

local function find_python_root(path)
  local venv_root = find_venv_root(path)
  if venv_root then
    return venv_root
  end

  local start_path = normalize_start_path(path)

  local uv_lock = vim.fs.find("uv.lock", {
    path = start_path,
    upward = true,
    stop = vim.env.HOME,
  })[1]
  if uv_lock then
    return vim.fs.dirname(uv_lock)
  end

  local pyproject = vim.fs.find("pyproject.toml", {
    path = start_path,
    upward = true,
    stop = vim.env.HOME,
  })[1]
  if pyproject then
    return vim.fs.dirname(pyproject)
  end

  return vim.fn.getcwd()
end

local function apply_python_settings(config, root_dir)
  local _, python = find_venv_root(root_dir)
  if not python then
    return
  end

  config.settings = config.settings or {}
  config.settings.python = vim.tbl_deep_extend("force", config.settings.python or {}, {
    pythonPath = python,
    venvPath = root_dir,
    venv = ".venv",
  })
end

local function apply_python_settings_for_config(config)
  local root_dir = config.root_dir or find_python_root(vim.api.nvim_get_current_buf())
  apply_python_settings(config, root_dir)
end

return {
  -- Diagnostic display + Pyright config.
  -- LazyVim defaults already set underline=true, signs with icons, severity_sort.
  -- We only override virtual_text (disable inline text, use floating windows
  -- instead via the CursorHold autocmd in autocmds.lua).
  {
    "neovim/nvim-lspconfig",
    opts = {
      diagnostics = {
        virtual_text = false,
        update_in_insert = false,
        float = {
          focusable = false,
          border = "rounded",
          source = true,
          header = "",
          prefix = " ",
          max_width = 80,
        },
      },
      servers = {
        ruff = {
          capabilities = {
            general = {
              positionEncodings = { "utf-16" },
            },
          },
        },
        pyright = {
          root_dir = function(bufnr_or_fname, on_dir)
            local root = find_python_root(bufnr_or_fname)
            if type(on_dir) == "function" then
              on_dir(root)
              return
            end
            return root
          end,
          on_new_config = function(config, root_dir)
            apply_python_settings(config, root_dir)
          end,
          before_init = function(_, config)
            apply_python_settings_for_config(config)
          end,
          on_init = function(client)
            apply_python_settings_for_config(client.config)
            client.notify("workspace/didChangeConfiguration", {
              settings = client.config.settings,
            })
          end,
          settings = {
            python = {
              analysis = {
                diagnosticMode = "openFilesOnly",
                typeCheckingMode = "basic",
                diagnosticSeverityOverrides = {
                  reportUnusedImport = "none",
                  reportUnusedClass = "none",
                  reportUnusedFunction = "none",
                  reportUnusedVariable = "none",
                  reportDuplicateImport = "none",
                },
              },
            },
          },
        },
      },
    },
  },

  -- Python debug adapter for nvim-dap.
  -- Lets you set breakpoints and step through Python code.
  -- Keymaps: <leader>db (breakpoint), <leader>dc (continue),
  --          <leader>di (step into), <leader>do (step over), <leader>dO (step out)
  --
  -- Finds the project .venv automatically (uv/poetry/plain venv).
  -- Requires: `uv pip install debugpy` (or `pip install debugpy` in your venv).
  {
    "mfussenegger/nvim-dap-python",
    dependencies = { "mfussenegger/nvim-dap" },
    ft = "python",
    config = function()
      -- Walk up from the current file to find the nearest .venv Python.
      local function find_python()
        local _, python = find_venv_root(vim.api.nvim_buf_get_name(0))
        if python then
          return python
        end
        return "python3"
      end
      require("dap-python").setup(find_python())
    end,
  },

  -- venv-selector: switch between Python virtual environments on the fly.
  -- The LSP restarts automatically so pyright picks up the right venv.
  -- Use <leader>cv to open the picker.
  {
    "linux-cultist/venv-selector.nvim",
    cmd = "VenvSelect",
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>", desc = "Select Python venv" },
    },
    opts = {
      name = { ".venv", "venv", ".env", "env" },
    },
  },
}
