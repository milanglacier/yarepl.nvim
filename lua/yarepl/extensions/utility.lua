local M = {}

---@param config_getter fun(): table
---@return fun(bufnr: number, name: string)
function M.default_float_wincmd(config_getter)
    return function(bufnr, name)
        local winid = vim.api.nvim_open_win(bufnr, true, {
            relative = 'laststatus',
            row = 0,
            col = math.floor(vim.o.columns * 0.5),
            width = math.floor(vim.o.columns * 0.5),
            height = math.floor(vim.o.lines * 0.7),
            style = 'minimal',
            title = name,
            border = 'rounded',
            title_pos = 'center',
        })
        if config_getter().show_winbar_in_float_window then
            vim.wo[winid].winbar = '%t'
        end
    end
end

---@param tool_name string
---@param cmd string|string[]
---@param extra_args string[]
---@return string[]?
function M.build_cmd(tool_name, cmd, extra_args)
    if type(cmd) == 'string' then
        local args = vim.deepcopy(extra_args)
        table.insert(args, 1, cmd)
        return args
    elseif type(cmd) == 'table' then
        ---@type string[]
        local args = vim.deepcopy(cmd)
        for _, arg in ipairs(extra_args) do
            table.insert(args, arg)
        end
        return args
    end

    vim.notify('invalid ' .. tool_name .. ' cmd type', vim.log.levels.ERROR)
end

---@param enabled boolean
function M.warn_editor_not_nvr(enabled)
    if enabled and ((not vim.env.EDITOR) or (not vim.env.EDITOR:find 'nvr')) then
        vim.notify('current $EDITOR command is not nvr, please consider using nvr', vim.log.levels.WARN)
    end
end

---@param shortcut_name string
---@return string
function M.plug_name(shortcut_name)
    return shortcut_name:gsub('_', '-')
end

-- Execute a user command with a count prefix, using the current v:count.
function M.run_cmd_with_count(cmd)
    require('yarepl').run_cmd_with_count(cmd)
end

-- Build an expression for mappings that need to pass a count to a user command.
function M.partial_cmd_with_count_expr(cmd)
    return require('yarepl').partial_cmd_with_count_expr(cmd)
end

-- Send raw strings to a named REPL
---@param meta_name string
---@param id integer
---@param lines string
---@param send_delayed_final_cr boolean?
---@return nil
function M.send_to_repl_raw(meta_name, id, lines, send_delayed_final_cr)
    local yarepl = require 'yarepl'
    ---@diagnostic disable-next-line redefined-local
    local lines = vim.split(lines, '\r')
    local bufnr = vim.api.nvim_get_current_buf()
    yarepl._send_strings(id, meta_name, bufnr, lines, false, false, send_delayed_final_cr)
end

return M
