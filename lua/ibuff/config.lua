local M = {}

M.keybinds = {
  ["<CR>"] = "actions.select",

  ["q"] = { "actions.close", mode = "n" },

  ["d"] = { "actions.delete", mode = "n" }
}

return M
