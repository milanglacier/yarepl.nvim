local keymap = vim.api.nvim_set_keymap
local util = require 'yarepl.extensions.utility'

local M = {}

local default_wincmd = util.default_float_wincmd(function()
    return M.config
end)

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

---@class yarepl.extensions.CodexConfig
---@field show_winbar_in_float_window boolean
---@field wincmd fun(bufnr: number, name: string)
---@field source_syntax string
---@field codex_args string[]
---@field formatter string
---@field codex_cmd string|string[]
---@field warn_on_EDITOR_env_var boolean
---@type yarepl.extensions.CodexConfig
M.config = {
    show_winbar_in_float_window = true,
    wincmd = default_wincmd,
    source_syntax = 'read the instruction from {{file}}',
    codex_args = {},
    formatter = 'bracketed_pasting_delayed_cr',
    codex_cmd = 'codex',
    warn_on_EDITOR_env_var = true,
}

M.setup = function(params)
    M.config = vim.tbl_deep_extend('force', M.config, params or {})
end

M.create_codex_meta = function()
    return {
        cmd = function()
            return util.build_cmd('codex', M.config.codex_cmd, M.config.codex_args)
        end,
        formatter = M.config.formatter,
        wincmd = M.config.wincmd,
        source_syntax = M.config.source_syntax,
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
            util.warn_editor_not_nvr(M.config.warn_on_EDITOR_env_var)
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
    M.config.codex_args = opts.fargs or {}
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
-- New <Plug(yarepl-codex-*) keymaps
-------------------------------------

for _, shortcut in ipairs(shortcuts) do
    local plug_name = util.plug_name(shortcut.name)
    keymap('n', '<Plug>(yarepl-codex-' .. plug_name .. ')', '', {
        noremap = true,
        callback = function()
            util.run_cmd_with_count('Yarepl codex ' .. shortcut.name)
        end,
    })
end

keymap('n', '<Plug>(yarepl-codex-exec)', '', {
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
    M.config.codex_args = opts.fargs or {}
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
    local new_plug = '<Plug>(yarepl-codex-' .. util.plug_name(shortcut.name) .. ')'
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
        vim.deprecate('<Plug>(CodexExec)', '<Plug>(yarepl-codex-exec)', '2026-06-01', 'yarepl.nvim', false)
        return util.partial_cmd_with_count_expr 'CodexExec'
    end,
    expr = true,
})

return M
