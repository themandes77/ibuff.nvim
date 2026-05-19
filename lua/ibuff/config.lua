local M = {}

M.keybinds = {
  ["<CR>"] = "actions.select",
  ["q"] = {
    "actions.close",
    mode = "n"
  }
}

return M
