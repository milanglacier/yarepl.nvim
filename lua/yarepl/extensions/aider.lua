local keymap = vim.api.nvim_set_keymap
local util = require 'yarepl.extensions.utility'

local M = {}

local default_wincmd = util.default_float_wincmd(function()
    return M.config
end)

-- Predefined prefix setters
local prefixes = {
    '',
    '/add',
    '/architect',
    '/ask',
    '/chat-mode',
    '/clear',
    '/code',
    '/commit',
    '/copy',
    '/copy-context',
    '/diff',
    '/drop',
    '/editor',
    '/exit',
    '/git',
    '/help',
    '/lint',
    '/load',
    '/ls',
    '/map',
    '/map-refresh',
    '/model',
    '/models',
    '/multiline-mode',
    '/paste',
    '/quit',
    '/read-only',
    '/report',
    '/reset',
    '/run',
    '/save',
    '/settings',
    '/test',
    '/tokens',
    '/undo',
    '/voice',
    '/web',
    '/think-tokens',
    '/reasoning-effort',
    '/editor-model',
    '/weak-model',
    '/editor',
    '/edit',
    '/context',
}

local aider_args = {
    '--reasoning-effort',
    '--watch-files',
    '--model',
    '--opus',
    '--sonnet',
    '--4',
    '--4o',
    '--mini',
    '--4-turbo',
    '--35turbo',
    '--deepseek',
    '--o1-mini',
    '--o1-preview',
    '--architect',
    '--weak-model',
    '--editor-model',
    '--editor-edit-format',
    '--show-model-warnings',
    '--no-show-model-warnings',
    '--cache-prompts',
    '--no-cache-prompts',
    '--map-refresh',
    '--map-multiplier-no-files',
    '--restore-chat-history',
    '--no-restore-chat-history',
    '--pretty',
    '--no-pretty',
    '--stream',
    '--no-stream',
    '--user-input-color',
    '--tool-output-color',
    '--tool-error-color',
    '--tool-warning-color',
    '--assistant-output-color',
    '--completion-menu-color',
    '--completion-menu-bg-color',
    '--completion-menu-current-color',
    '--completion-menu-current-bg-color',
    '--code-theme',
    '--show-diffs',
    '--git',
    '--no-git',
    '--gitignore',
    '--no-gitignore',
    '--aiderignore',
    '--subtree-only',
    '--auto-commits',
    '--no-auto-commits',
    '--dirty-commits',
    '--no-dirty-commits',
    '--attribute-author',
    '--no-attribute-author',
    '--attribute-committer',
    '--no-attribute-committer',
    '--attribute-commit-message-author',
    '--no-attribute-commit-message-author',
    '--attribute-commit-message-committer',
    '--no-attribute-commit-message-committer',
    '--commit',
    '--commit-prompt',
    '--dry-run',
    '--no-dry-run',
    '--skip-sanity-check-repo',
    '--lint',
    '--lint-cmd',
    '--auto-lint',
    '--no-auto-lint',
    '--test-cmd',
    '--auto-test',
    '--no-auto-test',
    '--test',
    '--file',
    '--read',
    '--vim',
    '--chat-language',
    '--install-main-branch',
    '--apply',
    '--yes-always',
    '-v',
    '--show-repo-map',
    '--show-prompts',
    '--message',
    '--message-file',
    '--encoding',
    '-c',
    '--gui',
    '--suggest-shell-commands',
    '--no-suggest-shell-commands',
    '--voice-format',
    '--voice-language',
    '--multiline',
    '--reasoning-effort',
    '--thinking-tokens',
    '--auto-accept-architect',
    '--no-auto-accept-architect',
}

-- Create a closure for prefix handling
local function create_prefix_handler()
    local yarepl = require 'yarepl'
    local current_prefix = ''

    local add_prefix = function(strings)
        if #current_prefix > 0 and #strings > 0 then
            strings[1] = current_prefix .. ' ' .. strings[1]
        end

        return yarepl.formatter.bracketed_pasting(strings)
    end

    return {
        set_prefix = function(prefix)
            if not vim.tbl_contains(prefixes, prefix) then
                vim.notify('Unknown prefix for aider: ' .. prefix, vim.log.levels.WARN)
                return
            end
            current_prefix = prefix
        end,
        formatter = add_prefix,
    }
end

-- Initialize the prefix handler
local prefix_handler = create_prefix_handler()

M.set_prefix = prefix_handler.set_prefix
---@class yarepl.extensions.AiderConfig
---@field show_winbar_in_float_window boolean
---@field wincmd fun(bufnr: number, name: string)
---@field formatter string|fun(lines: string[]): string[]
---@field aider_args string[]
---@field aider_cmd string|string[]
---@type yarepl.extensions.AiderConfig
M.config = {
    show_winbar_in_float_window = true,
    wincmd = default_wincmd,
    formatter = prefix_handler.formatter,
    aider_args = { '--watch-files' },
    aider_cmd = 'aider',
}

M.setup = function(params)
    M.config = vim.tbl_deep_extend('force', M.config, params or {})
end

M.create_aider_meta = function()
    return {
        cmd = function()
            return util.build_cmd('aider', M.config.aider_cmd, M.config.aider_args)
        end,
        formatter = M.config.formatter,
        wincmd = M.config.wincmd,
    }
end

local shortcuts = {
    { name = 'send_yes', legacy_name = 'Yes', key = 'y' },
    { name = 'send_no', legacy_name = 'No', key = 'n' },
    { name = 'send_abort', legacy_name = 'Abort', key = '\3' }, -- Ctrl-c
    { name = 'send_exit', legacy_name = 'Exit', key = '\4' }, -- Ctrl-d
    { name = 'send_diff', legacy_name = 'Diff', key = '/diff' },
    { name = 'send_paste', legacy_name = 'Paste', key = '/paste' },
    { name = 'send_clear', legacy_name = 'Clear', key = '/clear' },
    { name = 'send_undo', legacy_name = 'Undo', key = '/undo' },
    { name = 'send_reset', legacy_name = 'Reset', key = '/reset' },
    { name = 'send_drop', legacy_name = 'Drop', key = '/drop' },
    { name = 'send_ls', legacy_name = 'Ls', key = '/ls' },
    { name = 'send_ask_mode', legacy_name = 'AskMode', key = '/ask' },
    { name = 'send_arch_mode', legacy_name = 'ArchMode', key = '/architect' },
    { name = 'send_code_mode', legacy_name = 'CodeMode', key = '/code' },
    { name = 'send_context_mode', legacy_name = 'ContextMode', key = '/context' },
}

-------------------------------------
-- New unified Yarepl aider commands
-------------------------------------

local aider_commands = {}
local aider_completions = {}

for _, shortcut in ipairs(shortcuts) do
    aider_commands[shortcut.name] = function(opts)
        local id = opts.count
        util.send_to_repl_raw('aider', id, shortcut.key .. '\r')
    end
    aider_completions[shortcut.name] = true
end

aider_commands.set_args = function(opts)
    M.config.aider_args = opts.fargs or {}
end
aider_completions.set_args = function()
    return aider_args
end

aider_commands.set_prefix = function(opts)
    local prefix = opts.args

    if prefix == '' then
        vim.ui.select(prefixes, {
            prompt = 'Select prefix: ',
        }, function(choice)
            if not choice then
                return
            end

            M.set_prefix(choice)
        end)
    else
        M.set_prefix(prefix)
    end
end
aider_completions.set_prefix = function()
    return prefixes
end

aider_commands.remove_prefix = function()
    M.set_prefix ''
end
aider_completions.remove_prefix = true

aider_commands.exec = function(opts)
    local id = opts.count
    local command = opts.args
    util.send_to_repl_raw('aider', id, command .. '\r')
end
aider_completions.exec = function()
    return prefixes
end

local yarepl = require 'yarepl'

yarepl.commands.aider = function(opts)
    local fargs = opts.fargs
    if #fargs == 0 then
        vim.notify('Yarepl aider: subcommand required', vim.log.levels.ERROR)
        return
    end

    local subcmd = table.remove(fargs, 1)
    local handler = aider_commands[subcmd]
    if not handler then
        vim.notify('Yarepl aider: unknown subcommand: ' .. subcmd, vim.log.levels.ERROR)
        return
    end

    handler { args = table.concat(fargs, ' '), fargs = fargs, count = opts.count, bang = opts.bang }
end

yarepl.completions.aider = aider_completions

-------------------------------------
-- New <Plug(yarepl-aider-*) keymaps
-------------------------------------

for _, shortcut in ipairs(shortcuts) do
    local plug_name = util.plug_name(shortcut.name)
    keymap('n', '<Plug>(yarepl-aider-' .. plug_name .. ')', '', {
        noremap = true,
        callback = function()
            util.run_cmd_with_count('Yarepl aider ' .. shortcut.name)
        end,
    })
end

keymap('n', '<Plug>(yarepl-aider-exec)', '', {
    noremap = true,
    callback = function()
        return util.partial_cmd_with_count_expr 'Yarepl aider exec '
    end,
    expr = true,
})

-------------------------------------
-- Legacy commands with deprecation notices
-------------------------------------

vim.api.nvim_create_user_command('AiderSetArgs', function(opts)
    vim.deprecate('AiderSetArgs', 'Yarepl aider set_args', '2026-06-01', 'yarepl.nvim', false)
    M.config.aider_args = opts.fargs or {}
end, {
    nargs = '*',
    complete = function()
        return aider_args
    end,
})

vim.api.nvim_create_user_command('AiderSetPrefix', function(opts)
    vim.deprecate('AiderSetPrefix', 'Yarepl aider set_prefix', '2026-06-01', 'yarepl.nvim', false)
    local prefix = opts.args

    if prefix == '' then
        vim.ui.select(prefixes, {
            prompt = 'Select prefix: ',
        }, function(choice)
            if not choice then
                return
            end

            M.set_prefix(choice)
        end)
    else
        M.set_prefix(prefix)
    end
end, {
    nargs = '?',
    complete = function()
        return prefixes
    end,
})

vim.api.nvim_create_user_command('AiderRemovePrefix', function()
    vim.deprecate('AiderRemovePrefix', 'Yarepl aider remove_prefix', '2026-06-01', 'yarepl.nvim', false)
    M.set_prefix ''
end, {})

for _, shortcut in ipairs(shortcuts) do
    vim.api.nvim_create_user_command('AiderSend' .. shortcut.legacy_name, function(opts)
        vim.deprecate(
            'AiderSend' .. shortcut.legacy_name,
            'Yarepl aider ' .. shortcut.name,
            '2026-06-01',
            'yarepl.nvim',
            false
        )
        local id = opts.count
        util.send_to_repl_raw('aider', id, shortcut.key .. '\r')
    end, { count = true })
end

vim.api.nvim_create_user_command('AiderExec', function(opts)
    vim.deprecate('AiderExec', 'Yarepl aider exec', '2026-06-01', 'yarepl.nvim', false)
    local id = opts.count
    local command = opts.args
    util.send_to_repl_raw('aider', id, command .. '\r')
end, {
    count = true,
    nargs = '*',
    complete = function()
        return prefixes
    end,
})

-------------------------------------
-- Legacy <Plug>(Aider*) keymaps with deprecation notices
-------------------------------------

for _, shortcut in ipairs(shortcuts) do
    local old_plug = '<Plug>(AiderSend' .. shortcut.legacy_name .. ')'
    local new_plug = '<Plug>(yarepl-aider-' .. util.plug_name(shortcut.name) .. ')'
    keymap('n', old_plug, '', {
        noremap = true,
        callback = function()
            vim.deprecate(old_plug, new_plug, '2026-06-01', 'yarepl.nvim', false)
            util.run_cmd_with_count('AiderSend' .. shortcut.legacy_name)
        end,
    })
end

keymap('n', '<Plug>(AiderExec)', '', {
    noremap = true,
    callback = function()
        vim.deprecate('<Plug>(AiderExec)', '<Plug>(yarepl-aider-exec)', '2026-06-01', 'yarepl.nvim', false)
        return util.partial_cmd_with_count_expr 'AiderExec'
    end,
    expr = true,
})

return M
