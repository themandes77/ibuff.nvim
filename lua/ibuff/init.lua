local M = {}

local session = {}

local function Is_Ibuff_buffer(bufnr)
  if vim.bo[bufnr].filetype == "ibuff" then
    return true
  end
  return false
end

-- TODO: find a better name for Buffer Number
-- Use ~/.../file instead of /home/username/.../file
-- Use File name ex: test.lua instead of /home/username/.../test.lua

local function render_table(lines)
  local str_lines = {}

  table.insert(str_lines, " #                         Name                   Filename")
  table.insert(str_lines, "---                        ----                   --------")

  for _, bufnr in ipairs(lines) do
    if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_is_valid(bufnr) then
      if vim.bo[bufnr].buflisted then
        local bufname = vim.api.nvim_buf_get_name(bufnr)
        table.insert(str_lines, bufnr .. "              " .. bufname)
      end
    else
    end
  end

  return str_lines
end

  local prev_buf
  local prev_buf_name

local function render_buffer_async(bufnr)
  local keybinds = require("ibuff.keybinds")
  local config = require("ibuff.config")

  prev_buf = vim.api.nvim_get_current_buf()
  prev_buf_name = vim.api.nvim_buf_get_name(prev_buf)

  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  if not Is_Ibuff_buffer(bufnr) then
    return false
  end

  local entries = vim.api.nvim_list_bufs()

  local lines = render_table(entries)

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
  vim.bo[bufnr].modifiable = false
  vim.bo[bufnr].modified = false

  local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

  for i, str in ipairs(buf_lines) do
    if str:gmatch(prev_buf_name) then
      vim.api.nvim_win_set_cursor(0, {i,0})
    end
  end


  keybinds.setup_keys(config.keybinds, bufnr)
end

function M.initialize(bufnr)

  if bufnr == 0 then
    bufnr = vim.api.nvim_get_current_buf()
  end
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end

  vim.api.nvim_clear_autocmds({
    buffer = bufnr,
    group = "Ibuff",
  })

  vim.bo[bufnr].filetype = "ibuff"
  session[bufnr] = session[bufnr] or {}

  vim.api.nvim_create_autocmd("BufUnload", {
    group = "Ibuff",
    nested = true,
    once = true,
    buffer = bufnr,
    callback = function ()
      local view_data = session[bufnr]
      session[bufnr] = nil
      if view_data and view_data.fs_event then
        view_data.fs_event:stop()
      end
    end
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = "Ibuff",
    buffer = bufnr,
    callback = function(args)
      render_buffer_async(args.buf)
    end
  })

end

function M.select(entry)
  local bufnr = vim.api.nvim_get_current_buf()
  if Is_Ibuff_buffer(bufnr) then
    entry = tonumber(entry)
    if vim.api.nvim_buf_is_valid(entry) then
      vim.api.nvim_set_current_buf(entry)
    end
  end
end

function M.open()

  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr) == "Ibuff" then
      session[bufnr] = session[bufnr] or {}
      session[bufnr].previous_buf = vim.api.nvim_get_current_buf()
      vim.api.nvim_set_current_buf(bufnr)
      render_buffer_async(bufnr)
      return
    end
  end

  local ibuff_buffer = vim.api.nvim_create_buf(false, true)
  pcall(vim.api.nvim_buf_set_name, ibuff_buffer, "Ibuff")
  vim.bo[ibuff_buffer].filetype = "ibuff"
  vim.bo[ibuff_buffer].buftype = "nofile"

  local prev_buf = vim.api.nvim_get_current_buf()

  M.initialize(ibuff_buffer)
  session[ibuff_buffer].previous_buf = prev_buf
  vim.api.nvim_set_current_buf(ibuff_buffer)

end

 function M.close()
  local ibuf = vim.api.nvim_get_current_buf()

  if not vim.api.nvim_buf_is_valid(ibuf) then
    return false
  end
  if not Is_Ibuff_buffer(ibuf) then
    return false
  end

  local prev = session[ibuf] and session[ibuf].previous_buf
  if prev and vim.api.nvim_buf_is_valid(prev) then
    vim.api.nvim_set_current_buf(prev)
  else
    vim.cmd.enew()
  end

  vim.api.nvim_buf_delete(ibuf, {force = true})
end

function M.setup()
  vim.api.nvim_create_user_command("Ibuff", M.open, {desc = "open Ibuff"})

  local aug = vim.api.nvim_create_augroup("Ibuff", { clear = true })

  vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
    group = aug,
    callback = function()
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[bufnr].filetype == "ibuff" and vim.api.nvim_buf_is_valid(bufnr) then
          if #vim.fn.win_findbuf(bufnr) > 0 then
            render_buffer_async(bufnr)
          end
        end
      end
    end,
  })
end

return M
