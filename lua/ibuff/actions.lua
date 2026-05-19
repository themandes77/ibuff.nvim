local ibuff = require("ibuff")
local utils = require("ibuff.utils")

local M = {}

local function get_entry_on_line(bufnr, lnum)
  if vim.bo[bufnr].filetype ~= "ibuff" then
    return
  end
  local line = vim.api.nvim_buf_get_lines(bufnr, lnum - 1, lnum, true)[1]
  if not line then
    return nil
  end

  local entry, bufname = vim.split(line, " ", { plain = true })
  vim.print(entry, bufname)
  return entry, bufname
end

local function get_entry_on_cursor()
  local lnum = vim.api.nvim_win_get_cursor(0)[1]
  return get_entry_on_line(0, lnum)
end

M.select = {
  desc = "Open the buffer under the cursor",
  callback = function ()
    local entry, bufname = get_entry_on_cursor()
    local bufnr = tonumber(entry)
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_set_current_buf(bufnr)
    end
  end,
}

M.close = {
  desc = "Close Ibuff",
  callback = function()
    ibuff.close()
  end
}

return M
