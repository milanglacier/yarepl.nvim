local M = {}

-- Execute a user command with a count prefix, using the current v:count.
function M.run_cmd_with_count(cmd)
    require('yarepl').run_cmd_with_count(cmd)
end

-- Build an expression for mappings that need to pass a count to a user command.
function M.partial_cmd_with_count_expr(cmd)
    return require('yarepl').partial_cmd_with_count_expr(cmd)
end

-- Send raw strings to a named REPL without applying any formatter.
-- meta_name: the yarepl meta name (e.g., 'aider', 'codex')
-- id: the REPL id (number) to send to
-- lines: string or table of strings to send
function M.send_to_repl_no_format(meta_name, id, lines)
    local yarepl = require 'yarepl'
    local bufnr = vim.api.nvim_get_current_buf()
    yarepl._send_strings(id, meta_name, bufnr, lines, false)
end

return M
