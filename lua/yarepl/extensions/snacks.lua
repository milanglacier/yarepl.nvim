local M = {}

local function get_buf_name_without_dir(bufnr)
    return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ':t')
end

---@param opts snacks.picker.Config?
M.repl_show = function(opts)
    local has_snacks, snacks = pcall(require, 'snacks.picker')
    if not has_snacks then
        vim.notify('Snacks is not installed!', vim.log.levels.ERROR)
        return
    end

    local repls = require('yarepl')._repls

    ---@type snacks.picker.Config
    local source = {
        finder = function()
            local items = {}

            for _, repl in ipairs(repls) do
                table.insert(items, {
                    buf = repl.bufnr,
                    text = get_buf_name_without_dir(repl.bufnr),
                })
            end

            return items
        end,
        format = function(item, _)
            return { { item.text } }
        end,
        confirm = function(picker, item)
            for id, repl in ipairs(repls) do
                if repl.bufnr == item.buf then
                    -- the default action is to open the REPL buffer with configured wincmd
                    picker:close()
                    vim.schedule(function()
                        vim.cmd(id .. 'REPLFocus')
                    end)
                    return
                end
            end
        end,
    }

    source = vim.tbl_deep_extend('force', source, opts or {})

    snacks.pick(nil, source)
end

return M
