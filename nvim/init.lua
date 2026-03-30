-- Neovim Configuration for Competitive Programming
-- Windows-aware (and Unix-compatible)
-- =====================================================

-- Central configuration table to hold shared state and helpers
local M = {}

--- Checks if the current OS is Windows.
M.is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1

--- Joins path components with the correct separator for the OS.
--- @param ... string varargs: Path components to join.
--- @return string The joined path.
M.path_join = function(...)
  local parts = { ... }
  local sep = M.is_windows and "\\" or "/"
  return table.concat(parts, sep)
end

--- Returns the standard C++ competitive programming template.
--- @return table An array of strings representing the template lines.
M.get_cp_template = function()
  return {
    "#include <bits/stdc++.h>",
    "using namespace std;",
    "",
    "int main() {",
    "    ios_base::sync_with_stdio(false);",
    "    cin.tie(NULL);",
    "    ",
    "    ",
    "    return 0;",
    "}",
  }
end

-- =====================================================
-- Basic Settings
-- =====================================================

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- GUI settings (Neovide, gVim, etc.)
vim.opt.guifont = "FiraCode Nerd Font:h14"
vim.opt.guicursor = "n-v-c:block-blinkon500-blinkoff500,i-ci-ve:ver25-blinkon500-blinkoff500,r-cr:hor20,o:hor50"
vim.opt.termguicolors = true
vim.o.background = "dark"

-- Set encoding
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- Platform-aware shell settings
if M.is_windows then
  if vim.fn.executable("pwsh") == 1 then
    vim.opt.shell = "pwsh"
  else
    vim.opt.shell = "powershell.exe"
  end
  -- PowerShell-friendly flags
  vim.opt.shellcmdflag = "-NoProfile -ExecutionPolicy RemoteSigned -Command"
  vim.opt.shellredir = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
  vim.opt.shellpipe = "2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
else
  vim.opt.shell = "/bin/bash"
end

-- Line numbers
vim.opt.number = true
vim.opt.relativenumber = true

-- Indentation
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.cindent = true -- Better for C-like languages
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

-- Search settings
vim.opt.hlsearch = false
vim.opt.incsearch = true -- Enable incremental search highlighting
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- UI settings
vim.opt.cmdheight = 0 -- hides command line unless needed
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")
vim.opt.updatetime = 300 -- Safer update time for plugins
vim.opt.cursorline = true
vim.opt.wrap = false

-- Split settings
vim.opt.splitbelow = true
vim.opt.splitright = true

-- =====================================================
-- Color Scheme (custom highlights)
-- =====================================================
pcall(require, "color_gvim")

-- =====================================================
-- File Handling & Clipboard
-- =====================================================

-- File handling (use stdpath for cross-platform)
local undodir = M.path_join(vim.fn.stdpath("state"), "undo")
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
vim.opt.backup = false
vim.opt.swapfile = false
vim.opt.undodir = undodir
vim.opt.undofile = true

-- Clipboard
vim.opt.clipboard = "unnamedplus"

-- Ensure clipboard works with external applications
if M.is_windows then
  if vim.fn.executable("win32yank.exe") == 1 then
    vim.g.clipboard = {
      name = "win32yank",
      copy = { ["+"] = "win32yank.exe -i", ["*"] = "win32yank.exe -i" },
      paste = { ["+"] = "win32yank.exe -o", ["*"] = "win32yank.exe -o" },
      cache_enabled = 1,
    }
  else
    -- fallback to clip.exe / PowerShell Get-Clipboard
    vim.g.clipboard = {
      name = "powershell",
      copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
      paste = {
        ["+"] = 'powershell -NoProfile -Command "Get-Clipboard -Raw"',
        ["*"] = 'powershell -NoProfile -Command "Get-Clipboard -Raw"',
      },
      cache_enabled = 1,
    }
  end
else
  if vim.fn.executable("xclip") == 1 then
    vim.g.clipboard = {
      name = "xclip",
      copy = {
        ['+'] = 'xclip -selection clipboard',
        ['*'] = 'xclip -selection primary',
      },
      paste = {
        ['+'] = 'xclip -selection clipboard -o',
        ['*'] = 'xclip -selection primary -o',
      },
      cache_enabled = 1,
    }
  end
end

-- =====================================================
-- Plugin Manager (Lazy.nvim)
-- =====================================================

local lazypath = M.path_join(vim.fn.stdpath("data"), "lazy", "lazy.nvim")
if not vim.loop.fs_stat(lazypath) then
  print("Installing Lazy.nvim plugin manager...")
  local result = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    print("ERROR: Failed to install Lazy.nvim:")
    print(result)
    print("Please run this command manually:")
    print("git clone https://github.com/folke/lazy.nvim.git " .. lazypath)
    return
  end

  print("SUCCESS: Lazy.nvim installed successfully!")
  print("RESTART: Please restart Neovim to complete the setup.")
end

vim.opt.rtp:prepend(lazypath)

-- Check if lazy is available
local lazy_available, lazy = pcall(require, "lazy")
if not lazy_available then
  print("ERROR: Could not load Lazy.nvim.")
  print("TROUBLESHOOTING steps:")
  print("1. Restart Neovim")
  print("2. If the problem persists, delete and reinstall:")
  print("   rm -rf " .. lazypath)
  print("   git clone https://github.com/folke/lazy.nvim.git " .. lazypath)
  print("3. Check if git is installed and you have internet connection")
  return
end

-- =====================================================
-- Plugins Configuration
-- =====================================================

lazy.setup({
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {},
    config = function()
      vim.cmd[[colorscheme tokyonight-night]]
    end,
  },

  -- Treesitter for syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      local ts_ok, treesitter = pcall(require, "nvim-treesitter.configs")
      if not ts_ok then
        vim.notify("Treesitter not available", vim.log.levels.WARN)
        return
      end

      treesitter.setup({
        ensure_installed = { "c", "cpp", "lua", "vim", "vimdoc", "query", "python" },
        sync_install = false,
        auto_install = true,
        ignore_install = {}, -- List of parsers to ignore installing
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false,
        },
        indent = {
          enable = true,
        },
      })
    end,
  },

  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "hrsh7th/nvim-cmp",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "j-hui/fidget.nvim",
    },
    config = function()
      -- Safe require with error handling
      local fidget_ok, fidget = pcall(require, "fidget")
      if fidget_ok then
        fidget.setup({})
      end

      local mason_ok, mason = pcall(require, "mason")
      if mason_ok then
        mason.setup()
      end

      local cmp_ok, cmp = pcall(require, "cmp")
      local cmp_lsp_ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")

      if not (cmp_ok and cmp_lsp_ok) then
        vim.notify("CMP or CMP LSP not available", vim.log.levels.WARN)
        return
      end

      local capabilities = vim.tbl_deep_extend(
        "force",
        {},
        vim.lsp.protocol.make_client_capabilities(),
        cmp_lsp.default_capabilities()
      )

      -- LSP handlers
      -- Disable LSP word highlighting (documentHighlight)
      local function lsp_highlight_document(client, bufnr)
        -- Intentionally left blank to disable word highlighting
      end

      local function lsp_keymaps(bufnr)
        local opts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "Go to declaration" }))
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Go to definition" }))
        vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover documentation" }))
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "Go to implementation" }))
        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "Signature help" }))
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename symbol" }))
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
        vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "Go to references" }))
        vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "Open diagnostic float" }))
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "Previous diagnostic" }))
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))
        vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, vim.tbl_extend("force", opts, { desc = "Set location list" }))
        vim.keymap.set("n", "<leader>lf", function() vim.lsp.buf.format { async = true } end, vim.tbl_extend("force", opts, { desc = "Format code" }))
      end

      -- Extract lspconfig capabilities
      local lsp_ok = pcall(require, "lspconfig")
      
      -- Set up clangd using vim.lsp.config (v0.11+)
      vim.lsp.config.clangd = {
        cmd = {
          "clangd",
          "--offset-encoding=utf-16",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders",
          "--fallback-style=llvm",
        },
        filetypes = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
        root_markers = {
          '.clangd',
          '.clang-tidy',
          '.clang-format',
          'compile_commands.json',
          'compile_flags.txt',
          'configure.ac',
          '.git',
        },
        capabilities = capabilities,
      }
      vim.lsp.enable("clangd")

      -- Set up lua_ls using vim.lsp.config (v0.11+)
      vim.lsp.config.lua_ls = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = {
          ".luarc.json",
          ".luarc.jsonc",
          ".luacheckrc",
          ".stylua.toml",
          "stylua.toml",
          "selene.toml",
          "selene.yml",
          ".git",
        },
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = { library = vim.api.nvim_get_runtime_file("", true) },
          },
        },
        capabilities = capabilities,
      }
      vim.lsp.enable("lua_ls")

      -- Apply our keymaps via LspAttach autocmd
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          lsp_keymaps(ev.buf)
        end,
      })

      -- Completion setup
      if cmp_ok then
        local luasnip_ok, luasnip = pcall(require, "luasnip")

        cmp.setup({
          snippet = {
            expand = function(args)
              if luasnip_ok then
                luasnip.lsp_expand(args.body)
              end
            end,
          },
          completion = {
            autocomplete = false, -- Disable automatic popup by default
          },
          mapping = cmp.mapping.preset.insert({
            ["<C-b>"] = cmp.mapping.scroll_docs(-4),
            ["<C-f>"] = cmp.mapping.scroll_docs(4),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.abort(),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip_ok and luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { "i", "s" }),
            ["<S-Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip_ok and luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { "i", "s" }),
          }),
          sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "luasnip" },
          }, {
            { name = "buffer" },
          }),
        })
      end

      -- Diagnostic configuration
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = false,
      })

      -- Diagnostic signs
      local signs = { Error = "E", Warn = "W", Hint = "H", Info = "I" }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end
    end,
  },

  -- File explorer
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("nvim-tree").setup({
        view = {
          width = 30,
        },
        renderer = {
          group_empty = true,
        },
        filters = {
          dotfiles = true,
        },
      })
    end,
  },

  -- Fuzzy finder
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Help tags" })
    end,
  },

  -- Status line
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "auto",
        },
      })
    end,
  },

  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  -- Comment plugin
  {
    "numToStr/Comment.nvim",
    lazy = false,
    config = function()
      require("Comment").setup()
    end,
  },

  -- Debugger
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      dapui.setup()
      require("nvim-dap-virtual-text").setup()

      -- C++ debugger setup: platform-aware adapter detection
      local lldb_cmd = nil
      if vim.fn.executable("lldb-vscode") == 1 then
        lldb_cmd = "lldb-vscode"
      elseif vim.fn.executable("lldb-vscode.exe") == 1 then
        lldb_cmd = "lldb-vscode.exe"
      elseif vim.fn.executable("codelldb") == 1 then
        lldb_cmd = "codelldb"
      elseif vim.fn.executable("lldb") == 1 then
        lldb_cmd = "lldb"
      else
        -- common Windows paths
        local candidates = {
          "C:\\Program Files\\LLVM\\bin\\lldb-vscode.exe",
          "C:\\Program Files (x86)\\LLVM\\bin\\lldb-vscode.exe",
        }
        for _, p in ipairs(candidates) do
          if vim.loop.fs_stat(p) then
            lldb_cmd = p
            break
          end
        end
      end

      if lldb_cmd then
        dap.adapters.lldb = {
          type = "executable",
          command = lldb_cmd,
          name = "lldb",
        }
      else
        vim.notify("LLDB adapter not found. Install CodeLLDB or LLVM's lldb for debugging.", vim.log.levels.WARN)
      end

      dap.configurations.cpp = {
        {
          name = "Launch",
          type = "lldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. (M.is_windows and "\\" or "/"), "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          args = {},
        },
      }

      -- Copy C++ config to C
      dap.configurations.c = dap.configurations.cpp

      -- Keymaps for debugging
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
      vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step into" })
      vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Step over" })
      vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "Step out" })
      vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })

      -- Auto open/close DAP UI
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end
    end,
  },

  -- Competitive programming specific
  {
    "xeluxee/competitest.nvim",
    dependencies = "MunifTanjim/nui.nvim",
    config = function()
      require("competitest").setup({
        local_config_file_name = ".competitest.lua",
        floating_border = "rounded",
        split_direction = "horizontal",
        split_size = 12,
        save_current_file = true,
        save_all_files = false,
        compile_directory = ".",
        compile_command = {
          cpp = { exec = "g++", args = { "-Wall", "-Wextra", "-std=c++17", "-O2", "$(FNAME)", "-o", "$(FNOEXT)" } },
          c = { exec = "gcc", args = { "-Wall", "-Wextra", "-std=c99", "-O2", "$(FNAME)", "-o", "$(FNOEXT)" } },
        },
        running_directory = ".",
        run_command = {
          cpp = { exec = M.is_windows and ".\\$(FNOEXT).exe" or "./$(FNOEXT)" },
          c = { exec = M.is_windows and ".\\$(FNOEXT).exe" or "./$(FNOEXT)" },
        },
        multiple_testing = -1,
        maximum_time = 5000,
        output_compare_method = "squish",
        view_output = true,
        view_input = true,
        view_expected = true,
        view_stdout = true,
        view_stderr = true,
        testcases_directory = ".",
        testcases_use_single_file = false,
        testcases_auto_detect_storage = true,
        testcases_single_file_format = "$(FNOEXT).testcases",
        testcases_input_file_format = "$(FNOEXT)_input$(TCNUM).txt",
        testcases_output_file_format = "$(FNOEXT)_output$(TCNUM).txt",
        companion_port = 27121,
        receive_print_message = true,
        template_file = false,
        evaluate_template_modifiers = false,
        date_format = "%c",
        received_files_extension = "cpp",
        received_problems_path = "$(CWD)/$(PROBLEM).$(FEXT)",
        received_problems_prompt_path = true,
        received_contests_directory = "$(CWD)",
        received_contests_problems_path = "$(PROBLEM).$(FEXT)",
        received_contests_prompt_directory = true,
        received_contests_prompt_extension = true,
        open_received_problems = true,
        open_received_contests = true,
        replace_received_testcases = false,
      })
    end,
  },

  -- Snippets for competitive programming
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load()

      -- Load custom competitive programming snippets
      local ls = require("luasnip")
      local snippet_path = M.path_join(vim.fn.stdpath("config"), "snippets")

      -- Check if snippets directory exists
      if vim.fn.isdirectory(snippet_path) == 1 then
        -- Load custom snippets from snippets folder
        local cpp_snippets_path = M.path_join(snippet_path, "cpp.lua")
        if vim.fn.filereadable(cpp_snippets_path) == 1 then
          local success, snippets = pcall(dofile, cpp_snippets_path)
          if success and snippets then
            ls.add_snippets("cpp", snippets)
            vim.notify("Custom C++ snippets loaded successfully!", vim.log.levels.INFO)
          else
            vim.notify("Error loading custom C++ snippets", vim.log.levels.WARN)
          end
        end
      end

      -- Basic fallback snippets if custom ones don't load
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node

      ls.add_snippets("cpp", {
        s("cp", {
          t(M.get_cp_template()),
          i(1, "    "), -- Placeholder inside main
          t({ "", "}" }), -- Closing brace
        }),
        s("fastio", {
          t({ "ios_base::sync_with_stdio(false);", "cin.tie(NULL);" }),
        }),
        s("debug", {
          t("#define debug(x) cout << #x << \" = \" << x << endl;"),
        }),
      })
    end,
  },

  -- Better terminal
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          winblend = 0,
          highlights = {
            border = "Normal",
            background = "Normal",
          },
        },
      })
    end,
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    opts = {},
    config = function()
      local hooks = require("ibl.hooks")
      local highlight = {
        "IndentBlanklineChar",
      }

      require("ibl").setup({
        indent = {
          char = "│",
          highlight = highlight,
        },
      })

      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        vim.api.nvim_set_hl(0, "IndentBlanklineChar", { fg = "#404040", nocombine = true })
      end)
    end,
  },

  -- Which key for keybind help
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {},
  },
})

-- =====================================================
-- Custom Keybindings
-- =====================================================

-- General keybindings
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex, { desc = "Open file explorer" })
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "Save file" })
vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "Quit" })
vim.keymap.set("n", "<leader>x", ":x<CR>", { desc = "Save and quit" })

-- Move lines up and down
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- Keep cursor in place during operations
vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Better paste
vim.keymap.set("x", "<leader>p", [["_dP]])

-- System clipboard
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]], { desc = "Copy to system clipboard" })
vim.keymap.set("n", "<leader>Y", [["+Y]], { desc = "Copy line to system clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete to black hole register" })

-- Quick fix navigation
vim.keymap.set("n", "<C-k>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-j>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lnext<CR>zz", { desc = "Next location list item" })
vim.keymap.set("n", "<leader>j", "<cmd>lprev<CR>zz", { desc = "Previous location list item" })

-- Replace word under cursor
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word under cursor" })

-- Make file executable (Unix only)
vim.keymap.set("n", "<leader>mx", function()
  if M.is_windows then
    vim.notify("Making a file executable is usually unnecessary on Windows.", vim.log.levels.INFO)
  else
    vim.cmd("silent !chmod +x %")
    vim.notify("Made current file executable", vim.log.levels.INFO)
  end
end, { noremap = true, silent = true, desc = "Make file executable (Unix only)" })

-- NvimTree
vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle file tree" })

-- Window split navigation with Shift + Arrow keys
vim.keymap.set("n", "<S-Right>", "<C-w>l", { desc = "Move to right split" })
vim.keymap.set("n", "<S-Left>", "<C-w>h", { desc = "Move to left split" })
vim.keymap.set("n", "<S-Up>", "<C-w>k", { desc = "Move to upper split" })
vim.keymap.set("n", "<S-Down>", "<C-w>j", { desc = "Move to lower split" })

-- Buffer navigation with Ctrl + Shift + Arrow keys
vim.keymap.set("n", "<C-S-Right>", ":bnext<CR>", { desc = "Next buffer" })
vim.keymap.set("n", "<C-S-Left>", ":bprevious<CR>", { desc = "Previous buffer" })
vim.keymap.set("n", "<C-S-Up>", ":bfirst<CR>", { desc = "First buffer" })
vim.keymap.set("n", "<C-S-Down>", ":blast<CR>", { desc = "Last buffer" })

-- =====================================================
-- CUA Mode - Common User Access shortcuts
-- =====================================================
vim.keymap.set("n", "<C-n>", ":enew<CR>", { desc = "New file" })
vim.keymap.set("n", "<C-o>", ":Telescope find_files<CR>", { desc = "Open file" })
vim.keymap.set("n", "<C-s>", ":w<CR>", { desc = "Save file" })
vim.keymap.set("i", "<C-s>", "<Esc>:w<CR>a", { desc = "Save file (insert mode)" })
vim.keymap.set("n", "<C-S-s>", ":wa<CR>", { desc = "Save all files" })
vim.keymap.set("i", "<C-S-s>", "<Esc>:wa<CR>a", { desc = "Save all files (insert mode)" })

-- Edit operations
vim.keymap.set("n", "<C-z>", ":undo<CR>", { desc = "Undo" })
vim.keymap.set("i", "<C-z>", "<C-o>:undo<CR>", { desc = "Undo (insert mode)" })
vim.keymap.set("n", "<C-y>", ":redo<CR>", { desc = "Redo" })
vim.keymap.set("i", "<C-y>", "<C-o>:redo<CR>", { desc = "Redo (insert mode)" })

-- Selection and clipboard
vim.keymap.set("n", "<C-a>", "ggVG", { desc = "Select all" })
vim.keymap.set("i", "<C-a>", "<Esc>ggVG", { desc = "Select all (insert mode)" })
vim.keymap.set("v", "<C-c>", '"+y<Esc>', { desc = "Copy to clipboard" })
vim.keymap.set("n", "<C-c>", '"+yy', { desc = "Copy line to clipboard" })
vim.keymap.set("v", "<C-x>", '"+x', { desc = "Cut to clipboard" })
vim.keymap.set("n", "<C-x>", '"+dd', { desc = "Cut line to clipboard" })
vim.keymap.set("n", "<C-v>", '"+p', { desc = "Paste from clipboard" })
vim.keymap.set("i", "<C-v>", '<C-r>+', { desc = "Paste from clipboard (insert mode)" })
vim.keymap.set("v", "<C-v>", '"+p', { desc = "Paste from clipboard (visual mode)" })
vim.keymap.set("c", "<C-v>", '<C-r>+', { desc = "Paste from clipboard (command mode)" })

-- Find and replace
vim.keymap.set("n", "<C-f>", "/", { desc = "Find" })
vim.keymap.set("n", "<C-h>", ":%s/", { desc = "Find and replace" })
vim.keymap.set("v", "<C-h>", ":s/", { desc = "Find and replace in selection" })

-- Window and tab operations
-- WARNING: <C-w> overrides the default window command prefix (e.g., <C-w>v, <C-w>s)
vim.keymap.set("n", "<C-w>", ":bd<CR>", { desc = "Close buffer" })
vim.keymap.set("n", "<C-t>", ":tabnew<CR>", { desc = "New tab" })
vim.keymap.set("n", "<C-Tab>", ":tabnext<CR>", { desc = "Next tab" })
vim.keymap.set("n", "<C-S-Tab>", ":tabprevious<CR>", { desc = "Previous tab" })

-- Text navigation with Ctrl+Arrow keys
vim.keymap.set("n", "<C-Right>", "w", { desc = "Move word right" })
vim.keymap.set("n", "<C-Left>", "b", { desc = "Move word left" })
vim.keymap.set("i", "<C-Right>", "<Esc>wa", { desc = "Move word right (insert mode)" })
vim.keymap.set("i", "<C-Left>", "<Esc>ba", { desc = "Move word left (insert mode)" })
vim.keymap.set("n", "<C-Up>", "{", { desc = "Move paragraph up" })
vim.keymap.set("n", "<C-Down>", "}", { desc = "Move paragraph down" })
vim.keymap.set("i", "<C-Up>", "<Esc>{a", { desc = "Move paragraph up (insert mode)" })
vim.keymap.set("i", "<C-Down>", "<Esc>}a", { desc = "Move paragraph down (insert mode)" })

-- Home and End keys
vim.keymap.set("n", "<Home>", "^", { desc = "Go to line start" })
vim.keymap.set("n", "<End>", "$", { desc = "Go to line end" })
vim.keymap.set("i", "<Home>", "<C-o>^", { desc = "Go to line start (insert mode)" })
vim.keymap.set("i", "<End>", "<C-o>$", { desc = "Go to line end (insert mode)" })
vim.keymap.set("n", "<C-Home>", "gg", { desc = "Go to file start" })
vim.keymap.set("n", "<C-End>", "G", { desc = "Go to file end" })
vim.keymap.set("i", "<C-Home>", "<Esc>gg", { desc = "Go to file start (insert mode)" })
vim.keymap.set("i", "<C-End>", "<Esc>G", { desc = "Go to file end (insert mode)" })

-- Delete operations
vim.keymap.set("n", "<Delete>", "x", { desc = "Delete character" })
vim.keymap.set("i", "<C-Delete>", "<Esc>dwa", { desc = "Delete word (insert mode)" })
vim.keymap.set("i", "<C-Backspace>", "<C-o>db", { desc = "Delete word backward (insert mode)" })

-- =====================================================
-- Plugin-specific Keybindings
-- =====================================================

-- Competitive programming
vim.keymap.set("n", "<leader>ct", ":CompetiTest run<CR>", { desc = "Run CompetiTest" })
vim.keymap.set("n", "<leader>cr", ":CompetiTest receive problem<CR>", { desc = "Receive problem" })
vim.keymap.set("n", "<leader>ca", ":CompetiTest add_testcase<CR>", { desc = "Add test case" })
vim.keymap.set("n", "<leader>ce", ":CompetiTest edit_testcase<CR>", { desc = "Edit test case" })
vim.keymap.set("n", "<leader>cc", ":Contest<CR>", { desc = "Create contest files A-H" })

-- Manual test case creation
vim.keymap.set("n", "<leader>cm", ":CPManualTest<CR>", { desc = "Create manual test case (CompetiTest format)" })
vim.keymap.set("n", "<leader>cq", ":CPQuickTest<CR>", { desc = "Create quick test case (standard format)" })
vim.keymap.set("n", "<leader>cl", ":CPListTests<CR>", { desc = "List all test cases" })

-- Toggle autocompletion
vim.keymap.set("n", "<leader>ac", function()
  local cmp_status, cmp = pcall(require, "cmp")
  if not cmp_status then
    vim.notify("nvim-cmp is not loaded", vim.log.levels.ERROR)
    return
  end

  if cmp.get_config().completion.autocomplete then
    cmp.setup({ completion = { autocomplete = false } })
    vim.notify("Autocompletion disabled", vim.log.levels.INFO)
  else
    cmp.setup({ completion = { autocomplete = { require("cmp.types").cmp.TriggerEvent.TextChanged } } })
    vim.notify("Autocompletion enabled", vim.log.levels.INFO)
  end
end, { desc = "Toggle autocompletion" })

-- Quick compile and run for C++
vim.keymap.set("n", "<F5>", ":CPRun<CR>", { desc = "Compile and run current file" })
vim.keymap.set("n", "<F7>", ":CPInputTest<CR>", { desc = "Run test with input.txt in popup" })

-- =====================================================
-- Auto Commands
-- =====================================================

local cpgroup = vim.api.nvim_create_augroup("CPConfig", { clear = true })

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Remove trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  group = cpgroup,
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

-- Set up competitive programming template
vim.api.nvim_create_autocmd("BufNewFile", {
  pattern = "*.cpp",
  group = cpgroup,
  callback = function()
    -- Only insert template if the buffer is completely empty
    if vim.api.nvim_buf_line_count(0) == 1 and vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "" then
      local template = M.get_cp_template()
      vim.api.nvim_buf_set_lines(0, 0, 0, false, template)
      -- Move cursor to the line above return 0
      vim.api.nvim_win_set_cursor(0, { #template - 2, #template[#template - 2] })
    end
  end,
})

-- =====================================================
-- Competitive Programming Utilities
-- =====================================================

-- Function to create a new competitive programming file
local function create_cp_file(name)
  local filename = name .. ".cpp"
  vim.cmd("edit " .. filename)
end

-- Command to create new CP file
vim.api.nvim_create_user_command("CPNew", function(opts)
  create_cp_file(opts.args)
end, { nargs = 1 })

-- Function to compile and run current file (Windows-aware)
local function compile_and_run()
  local filename = vim.fn.expand("%:p")
  local basename = vim.fn.expand("%:r")
  local directory = vim.fn.expand("%:p:h")

  -- Check if file exists and is a C++ file
  if vim.fn.filereadable(filename) == 0 then
    vim.notify("File not found: " .. filename, vim.log.levels.ERROR)
    return
  end

  if not (filename:match("%.cpp$") or filename:match("%.c$")) then
    vim.notify("Not a C/C++ file. File must end with .cpp or .c", vim.log.levels.WARN)
    return
  end

  -- Save current file
  vim.cmd("w")

  -- Build platform-aware executable name
  local exe_name = vim.fn.fnamemodify(basename, ":t") .. (M.is_windows and ".exe" or "")
  local exe_path = M.path_join(directory, exe_name)
  local prev_cwd = vim.fn.getcwd()
  vim.api.nvim_set_current_dir(directory)

  -- Ensure we restore CWD on exit
  local function cleanup()
    vim.api.nvim_set_current_dir(prev_cwd)
  end

  -- Compile using argument list to avoid shell quoting issues
  local compile_cmd = { "g++", "-Wall", "-Wextra", "-std=c++17", "-O2", "-o", exe_name, filename }
  local compile_result = vim.fn.systemlist(compile_cmd)

  -- Send compiler output to quickfix
  vim.fn.setqflist({}, ' ', { title = 'Compiler', lines = compile_result, efm = '%f:%l:%c: %t%*[^:]: %m' })
  if #compile_result > 0 then
    vim.cmd('copen')
  else
    vim.cmd('cclose')
  end

  if vim.v.shell_error ~= 0 then
    vim.notify("Compilation failed. See errors tab (quickfix list).", vim.log.levels.ERROR)
    cleanup()
    return
  end

  -- Check if executable was created
  if vim.fn.filereadable(exe_path) == 0 then
    vim.notify("Executable not created: " .. exe_path, vim.log.levels.ERROR)
    cleanup()
    return
  end

  -- Run the program in a below split terminal
  local sep = M.is_windows and ";" or "&&"
  local del_cmd = M.is_windows and "del" or "rm"
  local run_path = M.is_windows and (".\\" .. exe_name) or ("./" .. exe_name)

  -- Command to run, then delete the executable
  local term_cmd = string.format(
    "cd %s %s %s %s %s %s",
    vim.fn.shellescape(directory),
    sep,
    run_path,
    sep,
    del_cmd,
    vim.fn.shellescape(exe_name)
  )

  vim.cmd("below split")
  vim.cmd("resize 10")
  vim.cmd("terminal " .. term_cmd)

  -- Restore previous cwd
  cleanup()
end

-- Command to compile and run
vim.api.nvim_create_user_command("CPRun", compile_and_run, {})

-- Simple test runner - shows input and output in popup (job-based, cross-platform)
local function run_input_test()
  local filename = vim.fn.expand("%:p")
  local basename = vim.fn.expand("%:t:r")
  local directory = vim.fn.expand("%:p:h")

  -- Check if file exists and is a C++ file
  if vim.fn.filereadable(filename) == 0 then
    vim.notify("File not found: " .. filename, vim.log.levels.ERROR)
    return
  end

  if not (filename:match("%.cpp$") or filename:match("%.c$")) then
    vim.notify("Not a C/C++ file. File must end with .cpp or .c", vim.log.levels.WARN)
    return
  end

  -- Save current file
  vim.cmd("w")

  -- Compile the program
  local exe_name = basename .. (M.is_windows and ".exe" or "")
  local exe_path = M.path_join(directory, exe_name)
  local prev_cwd = vim.fn.getcwd()
  vim.api.nvim_set_current_dir(directory)

  -- Ensure we restore CWD and delete exe
  local function cleanup()
    if vim.fn.filereadable(exe_path) == 1 then
      pcall(vim.fn.delete, exe_path)
    end
    vim.api.nvim_set_current_dir(prev_cwd)
  end

  local compile_cmd = { "g++", "-Wall", "-Wextra", "-std=c++17", "-O2", "-o", exe_name, filename }
  local compile_result = vim.fn.systemlist(compile_cmd)

  -- Send compiler output to quickfix
  vim.fn.setqflist({}, ' ', { title = 'Compiler', lines = compile_result, efm = '%f:%l:%c: %t%*[^:]: %m' })
  if #compile_result > 0 then
    vim.cmd('copen')
  else
    vim.cmd('cclose')
  end

  if vim.v.shell_error ~= 0 then
    vim.notify("Compilation failed. See errors tab (quickfix list).", vim.log.levels.ERROR)
    cleanup()
    return
  end

  -- Check if executable was created
  if vim.fn.filereadable(exe_path) == 0 then
    vim.notify("Executable not created: " .. exe_path, vim.log.levels.ERROR)
    cleanup()
    return
  end

  -- Look for input.txt
  local input_file = M.path_join(directory, "input.txt")
  if vim.fn.filereadable(input_file) == 0 then
    vim.notify("input.txt not found. Create an input.txt file with your test input.", vim.log.levels.WARN)
    cleanup()
    return
  end

  -- Read input file
  local input_content = {}
  local file_handle = io.open(input_file, "r")
  if file_handle then
    for line in file_handle:lines() do
      table.insert(input_content, line)
    end
    file_handle:close()
  else
    vim.notify("Error reading input.txt", vim.log.levels.ERROR)
    cleanup()
    return
  end

  -- Run the program using jobstart and capture output
  local stdout_lines = {}
  local stderr_lines = {}
  local jid = vim.fn.jobstart({ exe_path }, {
    stdout_buffered = true,
    stderr_buffered = true,
    cwd = directory,
    on_stdout = function(_, data, _)
      if data then
        for _, ln in ipairs(data) do
          if ln ~= "" then table.insert(stdout_lines, ln) end
        end
      end
    end,
    on_stderr = function(_, data, _)
      if data then
        for _, ln in ipairs(data) do
          if ln ~= "" then table.insert(stderr_lines, ln) end
        end
      end
    end,
  })

  if jid <= 0 then
    vim.notify("Failed to start the executable as a job.", vim.log.levels.ERROR)
    cleanup()
    return
  end

  -- Send stdin and close
  if #input_content > 0 then
    vim.fn.chansend(jid, table.concat(input_content, "\n") .. "\n")
  end
  pcall(vim.fn.chanclose, jid, "stdin")

  -- Wait for job to finish (timeout in ms)
  local timeout_ms = 10000
  local wait_result = vim.fn.jobwait({ jid }, timeout_ms)
  local exit_code = wait_result[1]

  -- Prepare output lines for popup
  local output_lines = {}
  table.insert(output_lines, "Input:")
  for _, line in ipairs(input_content) do
    table.insert(output_lines, "  " .. line)
  end
  table.insert(output_lines, "")
  table.insert(output_lines, "Output:")

  if exit_code == -1 then
    table.insert(output_lines, "  [TIMEOUT - Program took longer than " .. (timeout_ms / 1000) .. " seconds]")
    pcall(vim.fn.jobstop, jid)
  elseif exit_code ~= 0 then
    if #stderr_lines > 0 then
      for _, line in ipairs(stderr_lines) do table.insert(output_lines, "  " .. line) end
    else
      for _, line in ipairs(stdout_lines) do table.insert(output_lines, "  " .. line) end
    end
    table.insert(output_lines, "")
    table.insert(output_lines, "  [RUNTIME ERROR - Exit code: " .. tostring(exit_code) .. "]")
  else
    for _, line in ipairs(stdout_lines) do table.insert(output_lines, "  " .. line) end
  end

  -- Auto-delete binary after running
  cleanup()

  -- Create popup window and set buffer name so CPCloseTest can find it
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "Test Output")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output_lines)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)


  -- Calculate popup size
  local width = math.max(60, math.min(120, vim.o.columns - 10))
  local height = math.max(10, math.min(30, #output_lines + 4))

  -- Create popup
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
    title = " Test Result ",
    title_pos = "center",
  })

  -- Set popup keymap to close with 'q' or Escape
  local function close_popup()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  vim.keymap.set("n", "q", close_popup, { buffer = buf, noremap = true, silent = true })
  vim.keymap.set("n", "<Esc>", close_popup, { buffer = buf, noremap = true, silent = true })

  vim.notify("Test completed - Press 'q' or Esc to close popup", vim.log.levels.INFO)
end

-- Simple commands
vim.api.nvim_create_user_command("CPInputTest", run_input_test, {})

-- Command to close test window
vim.api.nvim_create_user_command("CPCloseTest", function()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_get_name(buf):match("Test Output$") then
      vim.api.nvim_win_close(win, false)
      vim.api.nvim_buf_delete(buf, { force = true })
      break
    end
  end
end, {})

-- =====================================================
-- Manual Test Case Creation for CompetiTest
-- =====================================================

-- Function to create manual test cases for CompetiTest
local function create_manual_testcase()
  local filename = vim.fn.expand("%:p")
  local basename = vim.fn.expand("%:t:r")
  local directory = vim.fn.expand("%:p:h")

  -- Check if file exists and is a C++ file
  if vim.fn.filereadable(filename) == 0 then
    vim.notify("File not found: " .. filename, vim.log.levels.ERROR)
    return
  end

  if not (filename:match("%.cpp$") or filename:match("%.c$")) then
    vim.notify("Not a C/C++ file. File must end with .cpp or .c", vim.log.levels.WARN)
    return
  end

  -- Get test case number from user
  local test_num = vim.fn.input("Test case number: ")
  if test_num == "" then
    vim.notify("No test case number provided", vim.log.levels.WARN)
    return
  end

  -- Create input and output files for CompetiTest format
  local input_file = M.path_join(directory, basename .. "_input" .. test_num .. ".txt")
  local output_file = M.path_join(directory, basename .. "_output" .. test_num .. ".txt")

  -- Create input file
  vim.cmd("tabnew " .. input_file)
  vim.notify("Created " .. basename .. "_input" .. test_num .. ".txt - Add your test input here", vim.log.levels.INFO)

  -- Create output file in vertical split
  vim.cmd("vsplit " .. output_file)
  vim.notify("Created " .. basename .. "_output" .. test_num .. ".txt - Add expected output here", vim.log.levels.INFO)
end

-- Function to quickly create test cases in standard format (input1.txt, input2.txt, etc.)
local function create_quick_testcase()
  local directory = vim.fn.expand("%:p:h")

  -- Find next available test case number
  local test_num = 1
  while vim.fn.filereadable(M.path_join(directory, "input" .. test_num .. ".txt")) == 1 do
    test_num = test_num + 1
  end

  -- Create input and output files
  local input_file = M.path_join(directory, "input" .. test_num .. ".txt")
  local output_file = M.path_join(directory, "output" .. test_num .. ".txt")

  -- Create input file
  vim.cmd("tabnew " .. input_file)
  vim.notify("Created input" .. test_num .. ".txt - Add your test input here", vim.log.levels.INFO)

  -- Create output file in vertical split
  vim.cmd("vsplit " .. output_file)
  vim.notify("Created output" .. test_num .. ".txt - Add expected output here", vim.log.levels.INFO)
end

-- Function to list all test cases for current file
local function list_testcases()
  local filename = vim.fn.expand("%:p")
  local basename = vim.fn.expand("%:t:r")
  local directory = vim.fn.expand("%:p:h")

  if not (filename:match("%.cpp$") or filename:match("%.c$")) then
    vim.notify("Not a C/C++ file. File must end with .cpp or .c", vim.log.levels.WARN)
    return
  end

  -- Find CompetiTest format test cases using glob (cross-platform)
  local competitest_cases = {}
  local standard_cases = {}

  local comp_files = vim.fn.glob(M.path_join(directory, basename .. "_input*.txt"), false, true)
  for _, f in ipairs(comp_files) do
    local num = f:match("_input(%d+)%.txt$")
    if num then table.insert(competitest_cases, num) end
  end

  local std_files = vim.fn.glob(M.path_join(directory, "input*.txt"), false, true)
  for _, f in ipairs(std_files) do
    local num = f:match("input(%d+)%.txt$")
    if num then table.insert(standard_cases, num) end
  end

  -- Display results
  local output_lines = {}
  table.insert(output_lines, "Test Cases for " .. basename)
  table.insert(output_lines, "==========================================")

  if #competitest_cases > 0 then
    table.insert(output_lines, "")
    table.insert(output_lines, "CompetiTest Format:")
    table.sort(competitest_cases, function(a, b) return tonumber(a) < tonumber(b) end)
    for _, num in ipairs(competitest_cases) do
      local input_exists = vim.fn.filereadable(M.path_join(directory, basename .. "_input" .. num .. ".txt")) == 1
      local output_exists = vim.fn.filereadable(M.path_join(directory, basename .. "_output" .. num .. ".txt")) == 1
      local status = ""
      if input_exists and output_exists then
        status = " [COMPLETE]"
      elseif input_exists then
        status = " [INPUT ONLY]"
      else
        status = " [INCOMPLETE]"
      end
      table.insert(output_lines, "  Test " .. num .. status)
    end
  end

  if #standard_cases > 0 then
    table.insert(output_lines, "")
    table.insert(output_lines, "Standard Format:")
    table.sort(standard_cases, function(a, b) return tonumber(a) < tonumber(b) end)
    for _, num in ipairs(standard_cases) do
      local input_exists = vim.fn.filereadable(M.path_join(directory, "input" .. num .. ".txt")) == 1
      local output_exists = vim.fn.filereadable(M.path_join(directory, "output" .. num .. ".txt")) == 1
      local status = ""
      if input_exists and output_exists then
        status = " [COMPLETE]"
      elseif input_exists then
        status = " [INPUT ONLY]"
      else
        status = " [INCOMPLETE]"
      end
      table.insert(output_lines, "  Test " .. num .. status)
    end
  end

  if #competitest_cases == 0 and #standard_cases == 0 then
    table.insert(output_lines, "")
    table.insert(output_lines, "No test cases found.")
    table.insert(output_lines, "Use :CPManualTest to create CompetiTest format")
    table.insert(output_lines, "Use :CPQuickTest to create standard format")
  end

  -- Create popup to show results, set buffer name so CPCloseTest can detect it
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, "Test Cases")
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, output_lines)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "modifiable", false)


  -- Calculate popup size
  local width = math.max(50, math.min(80, vim.o.columns - 10))
  local height = math.max(8, math.min(25, #output_lines + 4))

  -- Create popup
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
    title = " Test Cases ",
    title_pos = "center",
  })

  -- Set popup keymap to close
  local function close_popup()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
  vim.keymap.set("n", "q", close_popup, { buffer = buf, noremap = true, silent = true })
  vim.keymap.set("n", "<Esc>", close_popup, { buffer = buf, noremap = true, silent = true })

  vim.notify("Test case list - Press 'q' or Esc to close", vim.log.levels.INFO)
end

-- Commands for manual test case creation
vim.api.nvim_create_user_command("CPManualTest", create_manual_testcase, { desc = "Create manual test case for CompetiTest" })
vim.api.nvim_create_user_command("CPQuickTest", create_quick_testcase, { desc = "Create quick test case (standard format)" })
vim.api.nvim_create_user_command("CPListTests", list_testcases, { desc = "List all test cases for current file" })

-- =====================================================
-- Contest Setup Function
-- =====================================================

-- Function to create contest files A.cpp through H.cpp with test cases
local function create_contest()
  local directory = vim.fn.expand("%:p:h")

  -- Get the standardized template
  local template = M.get_cp_template()

  -- Create files A.cpp through H.cpp
  local problems = { "A", "B", "C", "D", "E", "F", "G", "H" }
  local created_files = {}

  for _, problem in ipairs(problems) do
    local filename = M.path_join(directory, problem .. ".cpp")

    local file = io.open(filename, "w")
    if file then
      for _, line in ipairs(template) do
        file:write(line .. "\n")
      end
      file:close()
      table.insert(created_files, problem .. ".cpp")
    end

    -- Create input and output files for CompetiTest format
    local input_file = M.path_join(directory, problem .. "_input1.txt")
    local output_file = M.path_join(directory, problem .. "_output1.txt")

    local input_handle = io.open(input_file, "w")
    if input_handle then
      input_handle:write("1\n")
      input_handle:close()
    end

    local output_handle = io.open(output_file, "w")
    if output_handle then
      output_handle:write("1\n")
      output_handle:close()
    end

    -- Create standard test cases (input1.txt) only once, for problem A
    if problem == "A" then
      local std_input_file = M.path_join(directory, "input1.txt")
      local std_output_file = M.path_join(directory, "output1.txt")
      local std_input_handle = io.open(std_input_file, "w")
      if std_input_handle then
        std_input_handle:write("1\n")
        std_input_handle:close()
      end

      local std_output_handle = io.open(std_output_file, "w")
      if std_output_handle then
        std_output_handle:write("1\n")
        std_output_handle:close()
      end
    end
  end

  -- Open the first problem file
  vim.cmd("edit " .. M.path_join(directory, "A.cpp"))
  vim.api.nvim_win_set_cursor(0, { #template - 2, #template[#template - 2] })

  -- Create tabs for all problems
  for i = 2, #problems do
    vim.cmd("tabnew " .. M.path_join(directory, problems[i] .. ".cpp"))
    vim.api.nvim_win_set_cursor(0, { #template - 2, #template[#template - 2] })
  end

  vim.cmd("tabfirst")

  vim.notify("Contest setup complete! Created files: " .. table.concat(created_files, ", "), vim.log.levels.INFO)
  vim.notify("Test cases created for CompetiTest format (A_input1.txt, etc.)", vim.log.levels.INFO)
  vim.notify("Standard test cases created (input1.txt, output1.txt)", vim.log.levels.INFO)
end

-- Command to set up contest
vim.api.nvim_create_user_command("Contest", create_contest, { desc = "Create contest files A.cpp through H.cpp with templates and test cases" })

print("Competitive Programming Neovim setup loaded successfully!")

-- Set default directory to CP folder if no file specified
local cp_dir = M.path_join(vim.fn.expand('~'), 'Desktop', 'CP')
if vim.fn.argc() == 0 and vim.fn.isdirectory(cp_dir) == 1 then
  vim.api.nvim_set_current_dir(cp_dir)
end

