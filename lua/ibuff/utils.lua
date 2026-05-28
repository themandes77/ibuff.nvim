local M = {}
local session = {}

function M.Is_Ibuff_buffer(bufnr)
    if vim.bo[bufnr].filetype == "ibuff" then
        return true
    end
    return false
end

function M.render_table(lines)
    local str_lines = {}

    table.insert(str_lines, "bufnr            state                     Name                                  Filename")
    table.insert(str_lines, "-----            -----                     ----                                  --------")

    for _, bufnr in ipairs(lines) do
        if vim.api.nvim_buf_is_loaded(bufnr) and vim.api.nvim_buf_is_valid(bufnr) then
            if vim.bo[bufnr].buflisted then
                local bufname = vim.api.nvim_buf_get_name(bufnr)
                local splits = vim.split(bufname, "/")
                local name = splits[#splits]
                local state = "h"

                local ibufBuf = vim.api.nvim_get_current_buf()
                if M.Is_Ibuff_buffer(ibufBuf) then
                    local prev_buf = session[ibufBuf] and session[ibufBuf].prev_buf
                    if prev_buf and vim.api.nvim_buf_is_valid(prev_buf) then
                        local prev_buf_name = vim.api.nvim_buf_get_name(prev_buf)
                        if bufname:find(prev_buf_name, 1, true) then
                            state = "%a"
                        end
                    end
                end

                table.insert(str_lines, string.format("%-18d %-22s %-20s %-35s", bufnr, state, name, bufname)) -- didn't know i could do this, im dumb

            end
        end
    end

    return str_lines
end


function M.render_buffer_async(bufnr)
    local keybinds = require("ibuff.keybinds")
    local config = require("ibuff.config")

    if bufnr == 0 then
        bufnr = vim.api.nvim_get_current_buf()
    end

    if not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end

    if not M.Is_Ibuff_buffer(bufnr) then
        return false
    end

    local entries = vim.api.nvim_list_bufs()

    local lines = M.render_table(entries)

    vim.bo[bufnr].modifiable = true
    vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
    vim.bo[bufnr].modifiable = false
    vim.bo[bufnr].modified = false

    local buf_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, true)

    local prev = session[bufnr] and session[bufnr].prev_buf
    if prev and vim.api.nvim_buf_is_valid(prev) then
        local prev_buf_name = vim.api.nvim_buf_get_name(prev)

        for i, str in ipairs(buf_lines) do
            if str:find(prev_buf_name, 1, true) then
                vim.api.nvim_win_set_cursor(0, {i,0})
            end
        end
    end

    keybinds.setup_keys(config.keybinds, bufnr)
end

function M.getPrevBuf()
    local ibuff_buff = vim.api.nvim_get_current_buf()
    if M.Is_Ibuff_buffer(ibuff_buff) then
        return session[ibuff_buff] and session[ibuff_buff].prev_buf
    end
end

function M.setSessionPrevbuf(bufnr, prev_buf)
    if M.Is_Ibuff_buffer(bufnr) then
        session[bufnr].prev_buf = prev_buf
    end
end

function M.setSession(bufnr)
   session[bufnr] = session[bufnr] or {}
end

function M.sessionDelete(bufnr)
    local view_data = session[bufnr]
    session[bufnr] = nil
    if view_data and view_data.fs_event then
        view_data.fs_event:stop()
    end
end

return M
