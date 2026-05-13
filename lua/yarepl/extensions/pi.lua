local keymap = vim.api.nvim_set_keymap
local util = require 'yarepl.extensions.utility'

local M = {}

local default_wincmd = util.default_float_wincmd(function()
    return M.config
end)

local pi_args = {
    '--provider',
    '--model',
    '--api-key',
    '--system-prompt',
    '--append-system-prompt',
    '--mode',
    '--print',
    '--continue',
    '--resume',
    '--session',
    '--fork',
    '--session-dir',
    '--no-session',
    '--models',
    '--no-tools',
    '--no-builtin-tools',
    '--tools',
    '--thinking',
    '--extension',
    '--no-extensions',
    '--skill',
    '--no-skills',
    '--prompt-template',
    '--no-prompt-templates',
    '--theme',
    '--no-themes',
    '--no-context-files',
    '--export',
    '--list-models',
    '--verbose',
    '--offline',
    '--help',
    '--version',
}

local slash_commands = {
    '/changelog',
    '/clone',
    '/compact',
    '/copy',
    '/export',
    '/fork',
    '/hotkeys',
    '/login',
    '/logout',
    '/model',
    '/name',
    '/new',
    '/quit',
    '/reload',
    '/resume',
    '/scoped-models',
    '/session',
    '/settings',
    '/share',
    '/tree',
}

---@class yarepl.extensions.PiConfig
---@field show_winbar_in_float_window boolean
---@field wincmd fun(bufnr: number, name: string)
---@field formatter string
---@field pi_args string[]
---@field pi_cmd string|string[]
---@field warn_on_EDITOR_env_var boolean
---@type yarepl.extensions.PiConfig
M.config = {
    show_winbar_in_float_window = true,
    wincmd = default_wincmd,
    formatter = 'bracketed_pasting_delayed_cr',
    pi_args = {},
    pi_cmd = 'pi',
    warn_on_EDITOR_env_var = true,
}

M.setup = function(params)
    M.config = vim.tbl_deep_extend('force', M.config, params or {})
end

M.create_pi_meta = function()
    return {
        cmd = function()
            return util.build_cmd('pi', M.config.pi_cmd, M.config.pi_args)
        end,
        formatter = M.config.formatter,
        wincmd = M.config.wincmd,
        send_delayed_final_cr = true,
    }
end

local shortcuts = {
    -- Ctrl-c
    { name = 'send_abort', key = '\3', requires_cr = false },
    -- Ctrl-d
    { name = 'send_exit', key = '\4', requires_cr = false },
    -- Ctrl-g
    {
        name = 'send_open_editor',
        key = '\7',
        requires_cr = false,
        pre_hook = function()
            util.warn_editor_not_nvr(M.config.warn_on_EDITOR_env_var)
        end,
    },
}

local pi_commands = {}
local pi_completions = {}

for _, shortcut in ipairs(shortcuts) do
    pi_commands[shortcut.name] = function(opts)
        if type(shortcut.pre_hook) == 'function' then
            shortcut.pre_hook()
        end
        local id = opts.count
        util.send_to_repl_raw('pi', id, shortcut.key, shortcut.requires_cr)
    end
    pi_completions[shortcut.name] = true
end

pi_commands.set_args = function(opts)
    M.config.pi_args = opts.fargs or {}
end

pi_completions.set_args = function()
    return pi_args
end

pi_commands.exec = function(opts)
    local id = opts.count
    local command = opts.args
    util.send_to_repl_raw('pi', id, command, true)
end

pi_completions.exec = function()
    return slash_commands
end

local yarepl = require 'yarepl'

yarepl.commands.pi = function(opts)
    local fargs = opts.fargs
    if #fargs == 0 then
        vim.notify('Yarepl pi: subcommand required', vim.log.levels.ERROR)
        return
    end

    local subcmd = table.remove(fargs, 1)
    local handler = pi_commands[subcmd]
    if not handler then
        vim.notify('Yarepl pi: unknown subcommand: ' .. subcmd, vim.log.levels.ERROR)
        return
    end

    handler { args = table.concat(fargs, ' '), fargs = fargs, count = opts.count, bang = opts.bang }
end

yarepl.completions.pi = pi_completions

for _, shortcut in ipairs(shortcuts) do
    local plug_name = util.plug_name(shortcut.name)
    keymap('n', '<Plug>(yarepl-pi-' .. plug_name .. ')', '', {
        noremap = true,
        callback = function()
            util.run_cmd_with_count('Yarepl pi ' .. shortcut.name)
        end,
    })
end

keymap('n', '<Plug>(yarepl-pi-exec)', '', {
    noremap = true,
    callback = function()
        return util.partial_cmd_with_count_expr 'Yarepl pi exec '
    end,
    expr = true,
})

return M
