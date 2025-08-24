local keymap = vim.api.nvim_set_keymap

local M = {}

M.wincmd = function(bufnr, name)
    vim.api.nvim_open_win(bufnr, true, {
        relative = 'editor',
        row = math.floor(vim.o.lines * 0.05),
        col = math.floor(vim.o.columns * 0.05),
        width = math.floor(vim.o.columns * 0.9),
        height = math.floor(vim.o.lines * 0.9),
        style = 'minimal',
        title = name,
        border = 'rounded',
        title_pos = 'center',
    })
end

M.source_syntax = 'read the instruction from {{file}}'

local prefixes = {
    '/model',
    '/approvals',
    '/init',
    '/new',
    '/compact',
    '/diff',
    '/mention',
    '/status',
}

local codex_args = {
    '--config',
    '--image',
    '--model',
    '--oss',
    '--profile',
    '--sandbox',
    '--ask-for-approval',
    '--full-auto',
    '--dangerously-bypass-approvals-and-sandbox',
    '--cd',
}

M.codex_args = {}
M.formatter = 'bracketed_pasting'
M.codex_cmd = 'codex'

M.setup = function(params)
    M.codex_cmd = params.codex_cmd or M.codex_cmd
    M.codex_args = params.codex_args or M.codex_args
    M.wincmd = params.wincmd or M.wincmd
end

M.create_codex_meta = function()
    return {
        cmd = function()
            local args
            -- build up the command to launch codex based on M.codex_args (the
            -- command line options) and the M.codex_cmd.
            if type(M.codex_cmd) == 'string' then
                args = vim.deepcopy(M.codex_args)
                table.insert(args, 1, M.codex_cmd)
            elseif type(M.codex_cmd == 'table') then
                args = vim.deepcopy(M.codex_cmd)
                for _, arg in ipairs(M.codex_args) do
                    table.insert(args, arg)
                end
            else
                vim.notify('invalid codex cmd type', vim.log.levels.ERROR)
                return
            end

            return args
        end,
        formatter = M.formatter,
        wincmd = M.wincmd,
        source_syntax = M.source_syntax,
    }
end

local shortcuts = {
    { name = 'Abort', key = '\3' }, -- Ctrl-c
    { name = 'Exit', key = '\4' }, -- Ctrl-d
    { name = 'Diff', key = '/diff' },
    { name = 'Status', key = '/status' },
    { name = 'Model', key = '/model' },
    { name = 'New', key = '/new' },
    { name = 'Approvals', key = '/approvals' },
    { name = 'Compact', key = '/compact' },
}

local function run_cmd_with_count(cmd)
    vim.cmd(string.format('%d%s', vim.v.count, cmd))
end

local function partial_cmd_with_count_expr(cmd)
    -- <C-U> is equivalent to \21, we want to clear the range before
    -- next input to ensure the count is recognized correctly.
    return ':\21' .. vim.v.count .. cmd
end

function M.send_to_codex_no_format(id, lines)
    local yarepl = require 'yarepl'
    local bufnr = vim.api.nvim_get_current_buf()
    yarepl._send_strings(id, 'codex', bufnr, lines, false)
end

vim.api.nvim_create_user_command('CodexSetArgs', function(opts)
    M.codex_args = opts.fargs or {}
end, {
    nargs = '*',
    complete = function()
        return codex_args
    end,
})

for _, shortcut in ipairs(shortcuts) do
    vim.api.nvim_create_user_command('CodexSend' .. shortcut.name, function(opts)
        local id = opts.count
        M.send_to_codex_no_format(id, { shortcut.key .. '\r' })
    end, { count = true })

    keymap('n', string.format('<Plug>(CodexSend%s)', shortcut.name), '', {
        noremap = true,
        callback = function()
            run_cmd_with_count('CodexSend' .. shortcut.name)
        end,
    })
end

vim.api.nvim_create_user_command('CodexExec', function(opts)
    local id = opts.count
    local command = opts.args
    M.send_to_codex_no_format(id, command .. '\r')
end, {
    count = true,
    nargs = '*',
    complete = function()
        return prefixes
    end,
})

keymap('n', '<Plug>(CodexExec)', '', {
    noremap = true,
    callback = function()
        return partial_cmd_with_count_expr 'CodexExec'
    end,
    expr = true,
})

return M
