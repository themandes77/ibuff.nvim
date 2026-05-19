local M = {}

M.keybinds = {
  ["<CR>"] = {
    "actions.select",
    mode = "n"
  },
  ["q"] = {
    "actions.close",
    mode = "n"
  }
}

return M
