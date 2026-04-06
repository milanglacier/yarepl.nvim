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
    { name = 'send_abort', legacy_name = 'Abort', key = '\3', requires_cr = false },
    -- Ctrl-d
    { name = 'send_exit', legacy_name = 'Exit', key = '\4', requires_cr = false },
    { name = 'send_diff', legacy_name = 'Diff', key = '/diff', requires_cr = true },
    { name = 'send_status', legacy_name = 'Status', key = '/status', requires_cr = true },
    { name = 'send_model', legacy_name = 'Model', key = '/model', requires_cr = true },
    { name = 'send_new', legacy_name = 'New', key = '/new', requires_cr = true },
    { name = 'send_approvals', legacy_name = 'Approvals', key = '/approvals', requires_cr = true },
    { name = 'send_compact', legacy_name = 'Compact', key = '/compact', requires_cr = true },
    -- Ctrl-g
    {
        name = 'send_open_editor',
        legacy_name = 'OpenEditor',
        key = '\7',
        requires_cr = false,
        pre_hook = function()
            if M.warn_on_EDITOR_env_var and ((not vim.env.EDITOR) or (not vim.env.EDITOR:find 'nvr')) then
                vim.notify('current $EDITOR command is not nvr, please consider using nvr', vim.log.levels.WARN)
            end
        end,
    },
    --Ctrl-t
    { name = 'send_transcript_enter', legacy_name = 'TranscriptEnter', key = '\20', requires_cr = false },
    { name = 'send_transcript_quit', legacy_name = 'TranscriptQuit', key = 'q', requires_cr = false },
    -- Home
    { name = 'send_transcript_begin', legacy_name = 'TranscriptBegin', key = '\27[1~', requires_cr = false },
    -- End
    { name = 'send_transcript_end', legacy_name = 'TranscriptEnd', key = '\27[4~', requires_cr = false },
    { name = 'send_page_up', legacy_name = 'PageUp', key = '\27[5~', requires_cr = false },
    { name = 'send_page_down', legacy_name = 'PageDown', key = '\27[6~', requires_cr = false },
}

-------------------------------------
-- New unified Yarepl codex commands
-------------------------------------

local codex_commands = {}
local codex_completions = {}

for _, shortcut in ipairs(shortcuts) do
    codex_commands[shortcut.name] = function(opts)
        if type(shortcut.pre_hook) == 'function' then
            shortcut.pre_hook()
        end
        local id = opts.count
        util.send_to_repl_raw('codex', id, shortcut.key, shortcut.requires_cr)
    end
    codex_completions[shortcut.name] = true
end

codex_commands.set_args = function(opts)
    M.codex_args = opts.fargs or {}
end
codex_completions.set_args = function()
    return codex_args
end

codex_commands.exec = function(opts)
    local id = opts.count
    local command = opts.args
    util.send_to_repl_raw('codex', id, command, true)
end
codex_completions.exec = function()
    return prefixes
end

local yarepl = require 'yarepl'

yarepl.commands.codex = function(opts)
    local fargs = opts.fargs
    if #fargs == 0 then
        vim.notify('Yarepl codex: subcommand required', vim.log.levels.ERROR)
        return
    end

    local subcmd = table.remove(fargs, 1)
    local handler = codex_commands[subcmd]
    if not handler then
        vim.notify('Yarepl codex: unknown subcommand: ' .. subcmd, vim.log.levels.ERROR)
        return
    end

    handler { args = table.concat(fargs, ' '), fargs = fargs, count = opts.count, bang = opts.bang }
end

yarepl.completions.codex = codex_completions

-------------------------------------
-- New <Plug(Yarepl-codex-*) keymaps
-------------------------------------

for _, shortcut in ipairs(shortcuts) do
    local plug_name = shortcut.name:gsub('_', '-')
    keymap('n', '<Plug>(Yarepl-codex-' .. plug_name .. ')', '', {
        noremap = true,
        callback = function()
            util.run_cmd_with_count('Yarepl codex ' .. shortcut.name)
        end,
    })
end

keymap('n', '<Plug>(Yarepl-codex-exec)', '', {
    noremap = true,
    callback = function()
        return util.partial_cmd_with_count_expr 'Yarepl codex exec '
    end,
    expr = true,
})

-------------------------------------
-- Legacy commands with deprecation notices
-------------------------------------

vim.api.nvim_create_user_command('CodexSetArgs', function(opts)
    vim.deprecate('CodexSetArgs', 'Yarepl codex set_args', '2026-06-01', 'yarepl.nvim', false)
    M.codex_args = opts.fargs or {}
end, {
    nargs = '*',
    complete = function()
        return codex_args
    end,
})

for _, shortcut in ipairs(shortcuts) do
    vim.api.nvim_create_user_command('CodexSend' .. shortcut.legacy_name, function(opts)
        vim.deprecate(
            'CodexSend' .. shortcut.legacy_name,
            'Yarepl codex ' .. shortcut.name,
            '2026-06-01',
            'yarepl.nvim',
            false
        )
        if type(shortcut.pre_hook) == 'function' then
            shortcut.pre_hook()
        end
        local id = opts.count
        util.send_to_repl_raw('codex', id, shortcut.key, shortcut.requires_cr)
    end, { count = true })
end

vim.api.nvim_create_user_command('CodexExec', function(opts)
    vim.deprecate('CodexExec', 'Yarepl codex exec', '2026-06-01', 'yarepl.nvim', false)
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

-------------------------------------
-- Legacy <Plug>(Codex*) keymaps with deprecation notices
-------------------------------------

for _, shortcut in ipairs(shortcuts) do
    local old_plug = '<Plug>(CodexSend' .. shortcut.legacy_name .. ')'
    local new_plug = '<Plug(Yarepl-codex-' .. shortcut.name:gsub('_', '-') .. ')'
    keymap('n', old_plug, '', {
        noremap = true,
        callback = function()
            vim.deprecate(old_plug, new_plug, '2026-06-01', 'yarepl.nvim', false)
            util.run_cmd_with_count('CodexSend' .. shortcut.legacy_name)
        end,
    })
end

keymap('n', '<Plug>(CodexExec)', '', {
    noremap = true,
    callback = function()
        vim.deprecate('<Plug>(CodexExec)', '<Plug(Yarepl-codex-exec)', '2026-06-01', 'yarepl.nvim', false)
        return util.partial_cmd_with_count_expr 'CodexExec'
    end,
    expr = true,
})

return M
