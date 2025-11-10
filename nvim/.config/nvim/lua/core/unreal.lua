local is_open_ui = false
return {
  -- UEP.nvim is in development, so I'm using a local path
  dir = '~/Documents/git/UEP.nvim/',
  dev = true,

  -- Load when a C++/C file is opened
  ft = { "cpp", "c" },

  -- Allow loading via command
  cmd = { "UEP" },

  -- Allow loading via keymap
  keys = {
    { '<c-f>', '<cmd>UEP files --all-deps<CR>', mode = 'n' },
  },

  -- Dependencies
  dependencies = {
    "j-hui/fidget.nvim",
    "nvim-telescope/telescope.nvim",
    "taku25/UNL.nvim",
    "taku25/UBT.nvim",
    "taku25/UCM.nvim",
    "taku25/USH.nvim",
  },
  opts = {},
  config = function(_, opts)
    require("UEP").setup(opts)

    -- Keymap for switching between header/source files
    vim.keymap.set("n", "<leader>a", function()
      require("UCM.api").switch_file()
    end, { noremap = true, silent = true })

    -- A smart keymap for build / live coding
    vim.keymap.set("n", "<C-s>", function()
      local unl_api = require("UNL.api")
      -- Check if the Unreal Editor process is running
      unl_api.is_process_running("UnrealEditor", function(is_running)
        if is_running then
          -- If it's running, trigger a Live Coding compile
          require("ULG.api").remote_command("livecoding.compile")
        else
          -- If not, run a normal build
          require("UBT.api").build({})
        end
      end)
    end, { noremap = true, silent = true })

    -- Auto-open IDE-like UI
    local open_ui = function()
      if is_open_ui == true then
        return
      end
      local project = require("UNL.api").find_project(vim.loop.cwd())
      if project and project.root then
        require("UEP.api").tree() -- Show project tree in neo-tree
        require("ULG.api").start()  -- Show the log window
        is_open_ui = true
      end
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "cpp", "c" },
      callback = function()
        open_ui()
      end,
    })
    open_ui()
  end,
}
