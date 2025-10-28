-- ~/.config/nvim/lua/custom/dap_env.lua

local M = {}

local cache_file = '.nvim/dap_python_env.json'

local function file_exists(path)
  local stat = vim.loop.fs_stat(path)
  return (stat and stat.type) or false
end

local function ensure_cache_dir()
  local dir = vim.fn.getcwd() .. '/.nvim'
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end
end

local function get_cache_path()
  return vim.fn.getcwd() .. '/' .. cache_file
end

local function read_cached_env()
  local path = get_cache_path()
  if file_exists(path) then
    local content = vim.fn.readfile(path)
    if #content > 0 then
      local ok, parsed = pcall(vim.fn.json_decode, table.concat(content, '\n'))
      if ok and parsed and parsed.python_path then
        return parsed.python_path
      end
    end
  end
  return nil
end

local function write_cached_env(python_path)
  ensure_cache_dir()
  local path = get_cache_path()
  local data = { python_path = python_path }
  local json = vim.fn.json_encode(data)
  vim.fn.writefile({ json }, path)
end

function M.clear_cached_env()
  local path = get_cache_path()
  if file_exists(path) then
    os.remove(path)
    print '🧹 Cleared cached DAP Python environment'
  else
    print 'ℹ️ No cached environment to clear'
  end
end

local function get_conda_env()
  local active = os.getenv 'CONDA_PREFIX'
  if active and file_exists(active .. '/bin/python') then
    return active .. '/bin/python'
  end

  local conda_base = nil
  local handle = io.popen 'conda info --base 2>/dev/null'
  if handle then
    conda_base = handle:read '*l'
    handle:close()
  end

  if not conda_base or conda_base == '' then
    conda_base = os.getenv 'HOME' .. '/miniconda3'
  end

  if file_exists(conda_base .. '/bin/python') then
    return conda_base .. '/bin/python'
  end

  return nil
end

local function get_venv()
  local cwd = vim.fn.getcwd()
  local default_venv = cwd .. '/.venv'
  if file_exists(default_venv .. '/bin/python') then
    return default_venv .. '/bin/python'
  end
  return nil
end

function M.set_env()
  vim.ui.select({ 'conda', 'venv' }, { prompt = 'Environment type:' }, function(choice)
    if not choice then
      print '❌ No environment type selected.'
      return
    end

    vim.ui.input({ prompt = 'Environment name (or path):' }, function(env_name)
      if not env_name or env_name == '' then
        print '❌ No environment name provided.'
        return
      end

      local python_path = nil

      if choice == 'conda' then
        local conda_base = nil
        local handle = io.popen 'conda info --base 2>/dev/null'
        if handle then
          conda_base = handle:read '*l'
          handle:close()
        end

        if not conda_base or conda_base == '' then
          conda_base = os.getenv 'HOME' .. '/miniconda3'
        end

        python_path = conda_base .. '/envs/' .. env_name .. '/bin/python'
      elseif choice == 'venv' then
        local cwd = vim.fn.getcwd()
        if file_exists(env_name .. '/bin/python') then
          python_path = env_name .. '/bin/python'
        elseif file_exists(cwd .. '/' .. env_name .. '/bin/python') then
          python_path = cwd .. '/' .. env_name .. '/bin/python'
        else
          python_path = os.getenv 'HOME' .. '/.virtualenvs/' .. env_name .. '/bin/python'
        end
      end

      if vim.fn.executable(python_path) == 1 then
        require('dap-python').setup(python_path)
        write_cached_env(python_path)
        print('✅ DAP configured with: ' .. python_path)
      else
        print('❌ Python not found at: ' .. python_path)
      end
    end)
  end)
end

function M.setup_python_dap()
  local cached = read_cached_env()
  if cached and vim.fn.executable(cached) == 1 then
    require('dap-python').setup(cached)
    print('✅ Loaded cached DAP Python: ' .. cached)
    return
  end

  local auto_path = get_venv() or get_conda_env()
  if auto_path and vim.fn.executable(auto_path) == 1 then
    require('dap-python').setup(auto_path)
    write_cached_env(auto_path)
    print('✅ Auto-configured DAP Python: ' .. auto_path)
    return
  end
end

return M
