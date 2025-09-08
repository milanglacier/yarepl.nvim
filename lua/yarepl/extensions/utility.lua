local M = {}

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
