local km = vim.keymap
local actions = require("ibuff.actions")

local function resolve(v)
  if type(v) == "string" and vim.startswith(v, "actions.") then
    vim.print("string")
    local action_name = vim.split(v, ".", { plain = true })[2]
    local action = actions[action_name]
    if not action then
      vim.notify("[ibuff.nvim] Unkown action name: " .. action_name, vim.log.levels.ERROR)
    end
    return resolve(action)
  elseif type(v) == "table" then
    vim.print("table")
    local opts = vim.deepcopy(v)
    local callback, parent_opts = resolve(opts.callback)

    if parent_opts.desc and not opts.desc then
      if opts.desc then
        opts.desc = string.format("%s %s", parent_opts.desc, vim.inspect(opts.desc):gsub("%s+", " "))
      else
        opts.desc = parent_opts.desc
      end
    end

    local mode = opts.mode
    if type(v.callback) == "string" then
      vim.print("callback string")
      local action_opts, action_mode
      callback, action_opts, action_mode = resolve(v)
      opts = vim.tbl_extend("keep", opts, action_opts)
      mode = mode or action_mode
    end

    opts.callback = nil
    opts.mode = nil
    opts[1] = nil
    opts.deprecated = nil
    opts.parameters = nil

    if opts.opts and type(callback) == "function" then
      vim.print("function")
      opts.opts = nil
      local orig_callback = callback
      callback = function()
        orig_callback()
      end
    end

    return callback, opts, mode
  else
    return v, {}
  end
end

local M = {}

function M.setup_keys(keybinds)
  for k, v in pairs(keybinds) do
    local callback, opts, mode = resolve(v)
    if callback then
      km.set(mode or "", k, callback, opts)
    end
  end
end

return M
