local actions = require("ibuff.actions")

local M = {}

M.keybinds = {
  ["<CR>"] = {
    action = "actions.select",
    desc = "Select buffer under cursor",
    mode = "n"
  },
  ["q"] = {
    action = "actions.close",
    desc = "Close Ibuff",
    mode = "n"
  }
}

return M
