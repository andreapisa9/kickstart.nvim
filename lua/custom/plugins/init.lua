-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  {
    'mfussenegger/nvim-dap-python',
    ft = 'python',
    dependencies = {
      'mfussenegger/nvim-dap',
    },
    config = function()
      require('custom.dap_env').setup_python_dap()

      vim.api.nvim_create_user_command('DapPythonResetEnv', function()
        require('custom.dap_env').clear_cached_env()
      end, { desc = 'Clear cached DAP Python environment for this project' })

      vim.keymap.set('n', '<leader>dr', function()
        require('custom.dap_env').clear_cached_env()
      end, { desc = 'Reset cached Python env for DAP' })

      vim.api.nvim_create_user_command('DapPythonSetEnv', function()
        require('custom.dap_env').set_env()
      end, { desc = 'Set DAP Python environment for this project' })

      vim.keymap.set('n', '<leader>ds', function()
        require('custom.dap_env').set_env()
      end, { desc = 'Set Python env for DAP' })
    end,
  },
}
