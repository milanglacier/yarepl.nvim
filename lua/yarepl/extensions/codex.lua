local keymap = vim.api.nvim_set_keymap
local util = require 'yarepl.extensions.utility'

local M = {}
M.show_winbar_in_float_window = true

M.wincmd = function(bufnr, name)
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
    if M.show_winbar_in_float_window then
        vim.wo[winid].winbar = '%t'
    end
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
M.formatter = 'bracketed_pasting_delayed_cr'
M.codex_cmd = 'codex'
M.warn_on_EDITOR_env_var = true

M.setup = function(params)
    M = vim.tbl_deep_extend('force', M, params or {})
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
        send_delayed_final_cr = true,
    }
end

local shortcuts = {
    -- Ctrl-c
    { name = 'Abort', key = '\3', requires_cr = false },
    -- Ctrl-d
    { name = 'Exit', key = '\4', requires_cr = false },
    { name = 'Diff', key = '/diff', requires_cr = true },
    { name = 'Status', key = '/status', requires_cr = true },
    { name = 'Model', key = '/model', requires_cr = true },
    { name = 'New', key = '/new', requires_cr = true },
    { name = 'Approvals', key = '/approvals', requires_cr = true },
    { name = 'Compact', key = '/compact', requires_cr = true },
    -- Ctrl-g
    {
        name = 'OpenEditor',
        key = '\7',
        requires_cr = false,
        pre_hook = function()
            if M.warn_on_EDITOR_env_var and ((not vim.env.EDITOR) or (not vim.env.EDITOR:find 'nvr')) then
                vim.notify('current $EDITOR command is not nvr, please consider using nvr', vim.log.levels.WARN)
            end
        end,
    },
    --Ctrl-t
    { name = 'TranscriptEnter', key = '\20', requires_cr = false },
    { name = 'TranscriptQuit', key = 'q', requires_cr = false },
    -- Home
    { name = 'TranscriptBegin', key = '\27[1~', requires_cr = false },
    -- End
    { name = 'TranscriptEnd', key = '\27[4~', requires_cr = false },
    { name = 'PageUp', key = '\27[5~', requires_cr = false },
    { name = 'PageDown', key = '\27[6~', requires_cr = false },
}

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
        if type(shortcut.pre_hook) == 'function' then
            shortcut.pre_hook()
        end
        local id = opts.count
        util.send_to_repl_raw('codex', id, shortcut.key, shortcut.requires_cr)
    end, { count = true })

    keymap('n', string.format('<Plug>(CodexSend%s)', shortcut.name), '', {
        noremap = true,
        callback = function()
            util.run_cmd_with_count('CodexSend' .. shortcut.name)
        end,
    })
end

vim.api.nvim_create_user_command('CodexExec', function(opts)
    local id = opts.count
    local command = opts.args
    util.send_to_repl_raw('codex', id, command, true)
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
        return util.partial_cmd_with_count_expr 'CodexExec'
    end,
    expr = true,
})

return M
