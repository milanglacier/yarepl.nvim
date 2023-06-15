local M = {}

local get_tmux_sessions = function()
    if vim.fn.executable 'tmux' == 0 then
        vim.notify 'tmux not found in PATH'
        return
    end

    local sessions_raw = vim.fn.system 'tmux list-sessions -F "#S"'

    if sessions_raw:find 'no server' then
        return {}
    end

    local sessions = vim.split(sessions_raw, '\n')

    local sessions_filtered = {}

    for _, session in ipairs(sessions) do
        if session ~= '' then
            table.insert(sessions_filtered, session)
        end
    end

    return sessions_filtered
end

return M
