local utils = require("ibuff.utils")
local M = {}

function M.delete(entry)
    if vim.api.nvim_buf_is_valid(entry) then
        local curr_buff = vim.api.nvim_get_current_buf()
        if utils.Is_Ibuff_buffer(curr_buff) then
            vim.api.nvim_buf_delete(entry, {force = true})

            local buffers = vim.api.nvim_list_bufs()

            local lines = utils.render_table(buffers)

            vim.bo[curr_buff].modifiable = true
            vim.api.nvim_buf_set_lines(curr_buff, 0, -1, true, lines)
            vim.bo[curr_buff].modifiable = false
            vim.bo[curr_buff].modified = false
        end
    end
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
    utils.setSession(bufnr)

    vim.api.nvim_create_autocmd("BufUnload", {
        group = "Ibuff",
        nested = true,
        once = true,
        buffer = bufnr,
        callback = function ()
            utils.sessionDelete(bufnr)
        end
    })

    vim.api.nvim_create_autocmd("BufEnter", {
        group = "Ibuff",
        buffer = bufnr,
        callback = function(args)
            utils.render_buffer_async(args.buf)
        end
    })

end

function M.select(entry)
    local bufnr = vim.api.nvim_get_current_buf()
    if utils. Is_Ibuff_buffer(bufnr) then
        entry = tonumber(entry)
        if vim.api.nvim_buf_is_valid(entry) then
            vim.api.nvim_set_current_buf(entry)
        end
    end
end

function M.open()
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_name(bufnr) == "Ibuff" then
            utils.setSession(bufnr)
            utils.setSessionPrevbuf(bufnr, vim.api.nvim_get_current_buf())
            vim.api.nvim_set_current_buf(bufnr)
            utils.render_buffer_async(bufnr)
            return
        end
    end

    local ibuff_buffer = vim.api.nvim_create_buf(false, true)
    pcall(vim.api.nvim_buf_set_name, ibuff_buffer, "Ibuff")
    vim.bo[ibuff_buffer].filetype = "ibuff"
    vim.bo[ibuff_buffer].buftype = "nofile"

    local prev_buf = vim.api.nvim_get_current_buf()

    M.initialize(ibuff_buffer)

    utils.setSessionPrevbuf(ibuff_buffer, prev_buf)
    vim.api.nvim_set_current_buf(ibuff_buffer)
end

function M.close()
    local ibuf = vim.api.nvim_get_current_buf()

    if not vim.api.nvim_buf_is_valid(ibuf) then
        return false
    end
    if not utils.Is_Ibuff_buffer(ibuf) then
        return false
    end

    local prev = utils.getPrevBuf()
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
                        -- M.open()
                    end
                end
            end
        end,
    })
end

return M
