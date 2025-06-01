local M = {}
local api = vim.api
local fn = vim.fn
local is_win32 = vim.fn.has 'win32' == 1 and true or false

M.formatter = {}
M.commands = {}

local default_config = function()
    return {
        buflisted = true,
        scratch = true,
        ft = 'REPL',
        wincmd = 'belowright 15 split',
        metas = {
            aichat = { cmd = 'aichat', formatter = 'bracketed_pasting', source_syntax = 'aichat' },
            radian = { cmd = 'radian', formatter = 'bracketed_pasting_no_final_new_line', source_syntax = 'R' },
            ipython = { cmd = 'ipython', formatter = 'bracketed_pasting', source_syntax = 'ipython' },
            python = { cmd = 'python', formatter = 'trim_empty_lines', source_syntax = 'python' },
            R = { cmd = 'R', formatter = 'trim_empty_lines', source_syntax = 'R' },
            -- bash version >= 4.4 supports bracketed paste mode. but macos
            -- shipped with bash 3.2, so we don't use bracketed paste mode for
            -- macOS
            bash = {
                cmd = 'bash',
                formatter = vim.fn.has 'linux' == 1 and 'bracketed_pasting' or 'trim_empty_lines',
                source_syntax = 'bash',
            },
            zsh = { cmd = 'zsh', formatter = 'bracketed_pasting', source_syntax = 'bash' },
        },
        close_on_exit = true,
        scroll_to_bottom_after_sending = true,
        -- Format REPL buffer names as #repl_name#n (e.g., #ipython#1) instead of using terminal defaults
        format_repl_buffers_names = true,
        os = {
            windows = {
                send_delayed_cr_after_sending = true,
            },
        },
        print_1st_line_on_source = false, -- If true, sends the first non-empty line of sourced content as a comment
        comment_prefixes = { -- Defines comment characters for different REPLs
            python = '# ',
            ipython = '# ',
            R = '# ',
            bash = '# ',
            zsh = '# ',
            lua = '-- ',
        },
    }
end

M._repls = {}
M._bufnrs_to_repls = {}

local function repl_is_valid(repl)
    return repl ~= nil and api.nvim_buf_is_loaded(repl.bufnr)
end

-- rearrange repls such that there's no gap in the repls table.
local function repl_cleanup()
    local valid_repls = {}
    local valid_repls_id = {}
    for id, repl in pairs(M._repls) do
        if repl_is_valid(repl) then
            table.insert(valid_repls_id, id)
        end
    end

    for bufnr, repl in pairs(M._bufnrs_to_repls) do
        if not repl_is_valid(repl) then
            M._bufnrs_to_repls[bufnr] = nil
        end

        if not api.nvim_buf_is_loaded(bufnr) then
            M._bufnrs_to_repls[bufnr] = nil
        end
    end

    table.sort(valid_repls_id)

    for _, id in ipairs(valid_repls_id) do
        table.insert(valid_repls, M._repls[id])
    end
    M._repls = valid_repls

    if M._config.format_repl_buffers_names then
        for id, repl in pairs(M._repls) do
            -- to avoid name conflict, we add a temp prefix
            api.nvim_buf_set_name(repl.bufnr, string.format('#%s#temp#%d', repl.name, id))
        end

        for id, repl in pairs(M._repls) do
            api.nvim_buf_set_name(repl.bufnr, string.format('#%s#%d', repl.name, id))
        end
    end
end

local function focus_repl(repl)
    if not repl_is_valid(repl) then
        -- if id is nil, print it as -1
        vim.notify [[REPL doesn't exist!]]
        return
    end
    local win = fn.bufwinid(repl.bufnr)
    if win ~= -1 then
        api.nvim_set_current_win(win)
    else
        local wincmd = M._config.metas[repl.name].wincmd or M._config.wincmd

        if type(wincmd) == 'function' then
            wincmd(repl.bufnr, repl.name)
        else
            vim.cmd(wincmd)
            api.nvim_set_current_buf(repl.bufnr)
        end
    end
end

local function create_repl(id, repl_name)
    if repl_is_valid(M._repls[id]) then
        vim.notify(string.format('REPL %d already exists, no new REPL is created', id))
        return
    end

    if not M._config.metas[repl_name] then
        vim.notify 'No REPL palatte is found'
        return
    end

    local bufnr = api.nvim_create_buf(M._config.buflisted, M._config.scratch)
    vim.bo[bufnr].filetype = M._config.ft

    local cmd

    if type(M._config.metas[repl_name].cmd) == 'function' then
        cmd = M._config.metas[repl_name].cmd()
    else
        cmd = M._config.metas[repl_name].cmd
    end

    local wincmd = M._config.metas[repl_name].wincmd or M._config.wincmd

    if type(wincmd) == 'function' then
        wincmd(bufnr, repl_name)
    else
        vim.cmd(wincmd)
        api.nvim_set_current_buf(bufnr)
    end

    local opts = {}
    opts.on_exit = function()
        if M._config.close_on_exit then
            local bufwinid = fn.bufwinid(bufnr)
            while bufwinid ~= -1 do
                api.nvim_win_close(bufwinid, true)
                bufwinid = fn.bufwinid(bufnr)
            end
            -- It is possible that this buffer has already been deleted, before
            -- the process is exit.
            if api.nvim_buf_is_loaded(bufnr) then
                api.nvim_buf_delete(bufnr, { force = true })
            end
        end
        repl_cleanup()
    end

    ---@diagnostic disable-next-line: redefined-local
    local function termopen(cmd, opts)
        if vim.fn.has 'nvim-0.11' == 1 then
            opts.term = true
            return vim.fn.jobstart(cmd, opts)
        else
            return vim.fn.termopen(cmd, opts)
        end
    end

    local term = termopen(cmd, opts)
    if M._config.format_repl_buffers_names then
        api.nvim_buf_set_name(bufnr, string.format('#%s#%d', repl_name, id))
    end
    M._repls[id] = { bufnr = bufnr, term = term, name = repl_name }
end

-- get the id of the closest repl whose name is `NAME` from the `ID`
local function find_closest_repl_from_id_with_name(id, name)
    local closest_id = nil
    local closest_distance = math.huge
    for repl_id, repl in pairs(M._repls) do
        if repl.name == name then
            local distance = math.abs(repl_id - id)
            if distance < closest_distance then
                closest_id = repl_id
                closest_distance = distance
            end
            if distance == 0 then
                break
            end
        end
    end
    return closest_id
end

local function repl_swap(id_1, id_2)
    local repl_1 = M._repls[id_1]
    local repl_2 = M._repls[id_2]
    M._repls[id_1] = repl_2
    M._repls[id_2] = repl_1
    repl_cleanup()
end

local function attach_buffer_to_repl(bufnr, repl)
    if not repl_is_valid(repl) then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    if not api.nvim_buf_is_loaded(bufnr) then
        vim.notify [[Invalid buffer!]]
        return
    end
    M._bufnrs_to_repls[bufnr] = repl
end

M.bufnr_is_attached_to_repl = function(bufnr)
    if not repl_is_valid(M._bufnrs_to_repls[bufnr]) then
        return false
    else
        return true
    end
end

---@param id number|nil the id of the repl,
---@param name string|nil the name of the closest repl that will try to find
---@param bufnr number|nil the buffer number of the buffer
---@return table|nil repl the repl object or nil if not found
-- get the repl specified by `id` and `name`. If `id` is 0, then will try to
-- find the REPL `bufnr` is attached to, if not find, will use `id = 1`. If
-- `name` is not nil or not an empty string, then will try to find the REPL
-- with `name` relative to `id`.
function M._get_repl(id, name, bufnr)
    local repl
    if id == nil or id == 0 then
        repl = M._bufnrs_to_repls[bufnr]
        id = 1
        if not repl_is_valid(repl) then
            repl = M._repls[id]
        end
    else
        repl = M._repls[id]
    end

    if name ~= nil and name ~= '' then
        id = find_closest_repl_from_id_with_name(id, name)
        repl = M._repls[id]
    end

    if not repl_is_valid(repl) then
        return nil
    end

    return repl
end

local function repl_win_scroll_to_bottom(repl)
    if not repl_is_valid(repl) then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    local repl_win = fn.bufwinid(repl.bufnr)
    if repl_win ~= -1 then
        local lines = api.nvim_buf_line_count(repl.bufnr)
        api.nvim_win_set_cursor(repl_win, { lines, 0 })
    end
end

-- currently only support line-wise sending in both visual and operator mode.
local function get_lines(mode)
    local begin_mark = mode == 'operator' and "'[" or "'<"
    local end_mark = mode == 'operator' and "']" or "'>"

    local begin_line = fn.getpos(begin_mark)[2]
    local end_line = fn.getpos(end_mark)[2]
    return api.nvim_buf_get_lines(0, begin_line - 1, end_line, false)
end

---Get the formatter function from either a string name or function
---@param formatter string|function The formatter name or function
---@return function Formatter function to use
---@throws string Error if formatter name is unknown
local function get_formatter(formatter)
    if type(formatter) == 'string' then
        return M.formatter[formatter] or error('Unknown formatter: ' .. formatter)
    end
    return formatter
end

function M.formatter.factory(opts)
    if type(opts) ~= 'table' then
        error 'opts must be a table'
    end

    local config = {
        replace_tab_by_space = false,
        number_of_spaces_to_replace_tab = 8,
        when_multi_lines = {
            open_code = '',
            end_code = '\r',
            trim_empty_lines = false,
            remove_leading_spaces = false,
            -- If gsub_pattern and gsub_repl are not empty, `string.gsub` will
            -- be called with `gsub_pattern` and `gsub_repl` on each line. Note
            -- that you should use Lua pattern instead of Vim regex pattern.
            -- The gsub calls happen after `trim_empty_lines`,
            -- `remove_leading_spaces`, and `replace_tab_by_space`, and before
            -- prepending and appending `open_code` and `end_code`.
            gsub_pattern = '',
            gsub_repl = '',
        },
        when_single_line = {
            open_code = '',
            end_code = '\r',
            gsub_pattern = '',
            gsub_repl = '',
        },
        os = {
            windows = {
                join_lines_with_cr = true,
            },
        },
    }

    config = vim.tbl_deep_extend('force', config, opts)

    return function(lines)
        if #lines == 1 then
            if config.replace_tab_by_space then
                lines[1] = lines[1]:gsub('\t', string.rep(' ', config.number_of_spaces_to_replace_tab))
            end

            lines[1] = lines[1]:gsub(config.when_single_line.gsub_pattern, config.when_single_line.gsub_repl)

            lines[1] = config.when_single_line.open_code .. lines[1] .. config.when_single_line.end_code
            return lines
        end

        local formatted_lines = {}
        local line = lines[1]

        line = line:gsub(config.when_multi_lines.gsub_pattern, config.when_multi_lines.gsub_repl)
        line = config.when_multi_lines.open_code .. line

        table.insert(formatted_lines, line)

        for i = 2, #lines do
            line = lines[i]

            if config.when_multi_lines.trim_empty_lines and line == '' then
                goto continue
            end

            if config.when_multi_lines.remove_leading_spaces then
                line = line:gsub('^%s+', '')
            end

            if config.replace_tab_by_space then
                line = line:gsub('\t', string.rep(' ', config.number_of_spaces_to_replace_tab))
            end

            line = line:gsub(config.when_multi_lines.gsub_pattern, config.when_multi_lines.gsub_repl)

            table.insert(formatted_lines, line)

            ::continue::
        end

        if config.when_multi_lines.end_code then
            table.insert(formatted_lines, config.when_multi_lines.end_code)
        end

        -- The `chansend` function joins lines with `\n`, which can result in a
        -- large number of unnecessary blank lines being sent to the REPL. For
        -- example, `{ "hello", "world", "again!" }` would be sent to the REPL
        -- as:

        -- ```
        -- hello
        --
        -- world
        --
        -- again!
        -- ```

        -- To prevent this issue, we manually join lines with `\r` on Windows.
        if is_win32 and config.os.windows.join_lines_with_cr then
            formatted_lines = { table.concat(formatted_lines, '\r') }
        end

        return formatted_lines
    end
end

M.formatter.trim_empty_lines = M.formatter.factory {
    when_multi_lines = {
        trim_empty_lines = true,
    },
}

M.formatter.bracketed_pasting = M.formatter.factory {
    when_multi_lines = {
        open_code = '\27[200~',
        end_code = '\27[201~\r',
    },
}

M.formatter.bracketed_pasting_no_final_new_line = M.formatter.factory {
    when_multi_lines = {
        open_code = '\27[200~',
        end_code = '\27[201~',
    },
}

--- Processes the source command to potentially add a commented first line.
-- @param initial_source_command string The initial command string generated for sourcing.
-- @param original_code_lines table A list of the original code lines being sent.
-- @param source_syntax_key string The key for the source syntax (e.g., 'python', 'R').
-- @return string The potentially modified source command string.
local function append_source_log(initial_source_command, strings, source_syntax)
    local comment_to_send_to_repl

    -- Check if the feature to print the first line is enabled
    if M._config.print_1st_line_on_source then
        -- Get the specific comment prefix for the given source syntax
        local comment_prefix = M._config.comment_prefixes[source_syntax]
        -- Only proceed if a comment_prefix is defined for this source_syntax
        if comment_prefix then
            local first_non_empty_line = 'YAREPL' -- Default in case no non-empty line is found
            -- Determine the final prefix, ensuring a space if the prefix isn't empty and doesn't end with one
            local final_prefix = (comment_prefix:sub(-1) ~= ' ' and #comment_prefix > 0) and (comment_prefix .. ' ')
                or comment_prefix
            -- Find the first non-empty line from the original code lines
            for _, line in ipairs(strings) do
                local trimmed_line = vim.fn.trim(line)
                if #trimmed_line > 0 then
                    first_non_empty_line = trimmed_line
                    break
                end
            end
            -- Format the comment string with the prefix, timestamp, and the first non-empty line
            comment_to_send_to_repl = string.format('%s%s - %s', final_prefix, os.date '%H:%M:%S', first_non_empty_line)
        end
    end
    -- If a comment was generated, append it to the initial source command
    if comment_to_send_to_repl then
        return initial_source_command .. '\n' .. comment_to_send_to_repl
    else
        return initial_source_command
    end
end

---@param id number the id of the repl,
---@param name string? the name of the closest repl that will try to find
---@param bufnr number? the buffer number from which to find the attached REPL.
---@param strings string[] a list of strings
---@param use_formatter boolean? whether use formatter (e.g. bracketed_pasting)? Default: true
---@param source_content boolean? Whether use source_syntax (defined by REPL meta) Default: false
-- Send a list of strings to the repl specified by `id` and `name` and `bufnr`.
-- If `id` is 0, then will try to find the REPL that `bufnr` is attached to, if
-- not find, will use `id = 1`. If `name` is not nil or not an empty string,
-- then will try to find the REPL with `name` relative to `id`. If `bufnr` is
-- nil or `bufnr` = 0, will find the REPL that current buffer is attached to.
M._send_strings = function(id, name, bufnr, strings, use_formatter, source_content)
    use_formatter = use_formatter == nil and true or use_formatter
    if bufnr == nil or bufnr == 0 then
        bufnr = api.nvim_get_current_buf()
    end

    local repl = M._get_repl(id, name, bufnr)

    if not repl then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    if source_content then
        local meta = M._config.metas[repl.name]
        local source_syntax = M.source_syntaxes[meta.source_syntax] or meta.source_syntax

        if not source_syntax then
            vim.notify(
                'No source syntax or source function is available for '
                    .. repl.name
                    .. '. Fallback to send string directly.'
            )
        end

        local content = table.concat(strings, '\n')
        local source_command_sent_to_repl

        if type(source_syntax) == 'string' then
            source_command_sent_to_repl = M.source_file_with_source_syntax(content, source_syntax)
        elseif type(source_syntax) == 'function' then
            source_command_sent_to_repl = source_syntax(content)
        end

        if source_command_sent_to_repl and source_command_sent_to_repl ~= '' then
            source_command_sent_to_repl = append_source_log(source_command_sent_to_repl, strings, meta.source_syntax)
            strings = vim.split(source_command_sent_to_repl, '\n')
        end
    end

    if use_formatter then
        strings = M._config.metas[repl.name].formatter(strings)
    end

    fn.chansend(repl.term, strings)

    -- See https://github.com/milanglacier/yarepl.nvim/issues/12 and
    -- https://github.com/urbainvaes/vim-ripple/issues/12 for more information.
    -- It may be necessary to use a delayed `<CR>` on Windows to ensure that
    -- the code is executed in the REPL.
    if is_win32 and M._config.os.windows.send_delayed_cr_after_sending then
        vim.defer_fn(function()
            fn.chansend(repl.term, '\r')
        end, 100)
    end

    if M._config.scroll_to_bottom_after_sending then
        repl_win_scroll_to_bottom(repl)
    end
end

M._send_operator_internal = function(motion)
    -- hack: allow dot-repeat
    if motion == nil then
        vim.go.operatorfunc = [[v:lua.require'yarepl'._send_operator_internal]]
        api.nvim_feedkeys('g@', 'ni', false)
    end

    local id = vim.b[0].repl_id
    local name = vim.b[0].closest_repl_name
    local current_bufnr = api.nvim_get_current_buf()

    local lines = get_lines 'operator'

    if #lines == 0 then
        vim.notify 'No motion!'
        return
    end

    M._send_strings(id, name, current_bufnr, lines)
end

M._source_operator_internal = function(motion)
    -- hack: allow dot-repeat
    if motion == nil then
        vim.go.operatorfunc = [[v:lua.require'yarepl'._source_operator_internal]]
        api.nvim_feedkeys('g@', 'ni', false)
    end

    local id = vim.b[0].repl_id
    local name = vim.b[0].closest_repl_name
    local current_bufnr = api.nvim_get_current_buf()

    local lines = get_lines 'operator'

    if #lines == 0 then
        vim.notify 'No motion!'
        return
    end

    M._send_strings(id, name, current_bufnr, lines, nil, true)
end

local function run_cmd_with_count(cmd)
    vim.cmd(string.format('%d%s', vim.v.count, cmd))
end

local function partial_cmd_with_count_expr(cmd)
    -- <C-U> is equivalent to \21, we want to clear the range before
    -- next input to ensure the count is recognized correctly.
    return ':\21' .. vim.v.count .. cmd
end

local function add_keymap(meta_name)
    -- replace non alpha numeric and - _ keys to dash
    if meta_name then
        meta_name = meta_name:gsub('[^%w-_]', '-')
    end

    local suffix = meta_name and ('-' .. meta_name) or ''

    local mode_commands = {
        { 'n', 'REPLStart' },
        { 'n', 'REPLFocus' },
        { 'n', 'REPLHide' },
        { 'n', 'REPLHideOrFocus' },
        { 'n', 'REPLSendLine' },
        { 'n', 'REPLSendOperator' },
        { 'v', 'REPLSendVisual' },
        { 'n', 'REPLSourceOperator' },
        { 'v', 'REPLSourceVisual' },
        { 'n', 'REPLClose' },
    }

    for _, spec in ipairs(mode_commands) do
        api.nvim_set_keymap(spec[1], string.format('<Plug>(%s%s)', spec[2], suffix), '', {
            noremap = true,
            callback = function()
                if meta_name then
                    run_cmd_with_count(spec[2] .. ' ' .. meta_name)
                else
                    run_cmd_with_count(spec[2])
                end
            end,
        })
    end

    -- setting up keymaps for REPLExec is more complicated, setting it independently
    api.nvim_set_keymap('n', string.format('<Plug>(%s%s)', 'REPLExec', suffix), '', {
        noremap = true,
        callback = function()
            if meta_name then
                return partial_cmd_with_count_expr('REPLExec $' .. meta_name)
            else
                return partial_cmd_with_count_expr 'REPLExec '
            end
        end,
        expr = true,
    })
end

M.commands.start = function(opts)
    -- if calling the command without any count, we want count to become 1.
    local repl_name = opts.args
    local id = opts.count == 0 and #M._repls + 1 or opts.count
    local repl = M._repls[id]
    local current_bufnr = api.nvim_get_current_buf()

    if repl_is_valid(repl) then
        vim.notify(string.format('REPL %d already exists', id))
        focus_repl(repl)
        return
    end

    if repl_name == '' then
        local repls = {}
        for name, _ in pairs(M._config.metas) do
            table.insert(repls, name)
        end

        vim.ui.select(repls, {
            prompt = 'Select REPL: ',
        }, function(choice)
            if not choice then
                return
            end

            repl_name = choice
            create_repl(id, repl_name)

            if opts.bang then
                attach_buffer_to_repl(current_bufnr, M._repls[id])
            end

            if M._config.scroll_to_bottom_after_sending then
                repl_win_scroll_to_bottom(M._repls[id])
            end
        end)
    else
        create_repl(id, repl_name)

        if opts.bang then
            attach_buffer_to_repl(current_bufnr, M._repls[id])
        end

        if M._config.scroll_to_bottom_after_sending then
            repl_win_scroll_to_bottom(M._repls[id])
        end
    end
end

M.commands.cleanup = repl_cleanup

M.commands.focus = function(opts)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    local repl = M._get_repl(id, name, current_buffer)

    if not repl then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    focus_repl(repl)
end

M.commands.hide = function(opts)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    local repl = M._get_repl(id, name, current_buffer)

    if not repl then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    local bufnr = repl.bufnr
    local win = fn.bufwinid(bufnr)
    while win ~= -1 do
        api.nvim_win_close(win, true)
        win = fn.bufwinid(bufnr)
    end
end

M.commands.hide_or_focus = function(opts)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    local repl = M._get_repl(id, name, current_buffer)

    if not repl then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    local bufnr = repl.bufnr
    local win = fn.bufwinid(bufnr)
    if win ~= -1 then
        while win ~= -1 do
            api.nvim_win_close(win, true)
            win = fn.bufwinid(bufnr)
        end
    else
        focus_repl(repl)
    end
end

M.commands.close = function(opts)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    local repl = M._get_repl(id, name, current_buffer)

    if not repl then
        vim.notify [[REPL doesn't exist!]]
        return
    end

    fn.chansend(repl.term, string.char(4))
end

M.commands.swap = function(opts)
    local id_1 = tonumber(opts.fargs[1])
    local id_2 = tonumber(opts.fargs[2])

    if id_1 ~= nil and id_2 ~= nil then
        repl_swap(id_1, id_2)
        return
    end

    local repl_ids = {}
    for id, _ in pairs(M._repls) do
        table.insert(repl_ids, id)
    end

    table.sort(repl_ids)

    if id_1 == nil then
        vim.ui.select(repl_ids, {
            prompt = 'select first REPL',
            format_item = function(item)
                return item .. ' ' .. M._repls[item].name
            end,
        }, function(id1)
            if not id1 then
                return
            end

            vim.ui.select(repl_ids, {
                prompt = 'select second REPL',
                format_item = function(item)
                    return item .. ' ' .. M._repls[item].name
                end,
            }, function(id2)
                if not id2 then
                    return
                end

                repl_swap(id1, id2)
            end)
        end)
    elseif id_2 == nil then
        vim.ui.select(repl_ids, {
            prompt = 'select second REPL',
            format_item = function(item)
                return item .. ' ' .. M._repls[item].name
            end,
        }, function(id2)
            if not id2 then
                return
            end

            repl_swap(id_1, id2)
        end)
    end
end

M.commands.attach_buffer = function(opts)
    local current_buffer = api.nvim_get_current_buf()

    if opts.bang then
        M._bufnrs_to_repls[current_buffer] = nil
        return
    end

    local repl_id = opts.count

    local repl_ids = {}
    for id, _ in pairs(M._repls) do
        table.insert(repl_ids, id)
    end

    -- count = 0 means no count is provided
    if repl_id == 0 then
        vim.ui.select(repl_ids, {
            prompt = 'select REPL that you want to attach to',
            format_item = function(item)
                return item .. ' ' .. M._repls[item].name
            end,
        }, function(id)
            if not id then
                return
            end
            attach_buffer_to_repl(current_buffer, M._repls[id])
        end)
    else
        attach_buffer_to_repl(current_buffer, M._repls[repl_id])
    end
end

M.commands.detach_buffer = function()
    local current_buffer = api.nvim_get_current_buf()
    M._bufnrs_to_repls[current_buffer] = nil
end

M.commands.send_visual = function(opts)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    api.nvim_feedkeys('\27', 'nx', false)

    local lines = get_lines 'visual'

    if #lines == 0 then
        vim.notify 'No visual range!'
        return
    end

    M._send_strings(id, name, current_buffer, lines, nil, opts.source_content)
end

M.commands.send_line = function(opts)
    local id = opts.count
    local name = opts.args
    local current_buffer = api.nvim_get_current_buf()

    local line = api.nvim_get_current_line()

    M._send_strings(id, name, current_buffer, { line })
end

M.commands.send_operator = function(opts)
    local repl_name = opts.args
    local id = opts.count

    if repl_name ~= '' then
        vim.b[0].closest_repl_name = repl_name
    else
        vim.b[0].closest_repl_name = nil
    end

    if id ~= 0 then
        vim.b[0].repl_id = id
    else
        vim.b[0].repl_id = nil
    end

    vim.go.operatorfunc = opts.source_content and [[v:lua.require'yarepl'._source_operator_internal]]
        or [[v:lua.require'yarepl'._send_operator_internal]]
    api.nvim_feedkeys('g@', 'ni', false)
end

M.commands.source_visual = function(opts)
    opts.source_content = true
    M.commands.send_visual(opts)
end

M.commands.source_operator = function(opts)
    opts.source_content = true
    M.commands.send_operator(opts)
end

M.commands.exec = function(opts)
    local first_arg = opts.fargs[1]
    local current_buffer = api.nvim_get_current_buf()
    local name = ''
    local command = opts.args

    for repl_name, _ in pairs(M._config.metas) do
        if '$' .. repl_name == first_arg then
            name = first_arg:sub(2)
            break
        end
    end

    if name ~= '' then
        command = command:gsub('^%$' .. name .. '%s+', '')
    end

    local id = opts.count
    local command_list = vim.split(command, '\r')

    M._send_strings(id, name, current_buffer, command_list)
end

---@param content string
---@param keep_file boolean? Whether keep the temporary file after temporary execution
---@return string? The file name of the temporary file
function M.make_tmp_file(content, keep_file)
    local tmp_file = os.tmpname() .. '_yarepl'

    local f = io.open(tmp_file, 'w+')
    if f == nil then
        M.notify('Cannot open temporary message file: ' .. tmp_file, 'error', vim.log.levels.ERROR)
        return
    end

    f:write(content)
    f:close()

    if not keep_file then
        vim.defer_fn(function()
            os.remove(tmp_file)
        end, 5000)
    end

    return tmp_file
end

---@param content string
---@param source_syntax string
---@param keep_file boolean?
---@reutrn string? The syntax to source the file
function M.source_file_with_source_syntax(content, source_syntax, keep_file)
    local tmp_file = os.tmpname() .. '_yarepl'

    local f = io.open(tmp_file, 'w+')
    if f == nil then
        M.notify('Cannot open temporary message file: ' .. tmp_file, 'error', vim.log.levels.ERROR)
        return
    end

    f:write(content)
    f:close()

    if not keep_file then
        vim.defer_fn(function()
            os.remove(tmp_file)
        end, 5000)
    end

    -- replace {{file}} placeholder with the temp file name
    source_syntax = source_syntax:gsub('{{file}}', tmp_file)

    return source_syntax
end

---@type table<string, string | fun(str: string): string?>
M.source_syntaxes = {}

M.source_syntaxes.python = function(str)
    -- Preserve the temporary file since PDB requires its existence for
    -- displaying context via the `list` command
    return M.source_file_with_source_syntax(
        str,
        'exec(compile(open("{{file}}", "r").read(), "{{file}}", "exec"))',
        true
    )
end

M.source_syntaxes.ipython = function(str)
    -- The `-i` flag ensures the current environment is inherited when
    -- executing the file
    return M.source_file_with_source_syntax(str, '%run -i "{{file}}"', true)
end

M.source_syntaxes.bash = 'source "{{file}}"'
M.source_syntaxes.R = 'eval(parse(text = readr::read_file("{{file}}")))'
M.source_syntaxes.aichat = '.file "{{file}}"'

M.setup = function(opts)
    M._config = vim.tbl_deep_extend('force', default_config(), opts or {})

    for name, meta in pairs(M._config.metas) do
        -- remove the disabled builtin meta passed from user config
        if not meta then
            M._config.metas[name] = nil
        else
            -- Convert string formatter names to actual formatter functions
            if meta.formatter then
                meta.formatter = get_formatter(meta.formatter)
            end
        end
    end

    add_keymap()

    for meta_name, _ in pairs(M._config.metas) do
        add_keymap(meta_name)
    end
end

api.nvim_create_user_command('REPLStart', M.commands.start, {
    count = true,
    bang = true,
    nargs = '?',
    complete = function()
        local metas = {}
        for name, _ in pairs(M._config.metas) do
            table.insert(metas, name)
        end
        return metas
    end,
    desc = [[
Create REPL `i` from the list of available REPLs.
]],
})

api.nvim_create_user_command(
    'REPLCleanup',
    M.commands.cleanup,
    { desc = 'clean invalid repls, and rearrange the repls order.' }
)

api.nvim_create_user_command('REPLFocus', M.commands.focus, {
    count = true,
    nargs = '?',
    desc = [[
Focus on REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLHide', M.commands.hide, {
    count = true,
    nargs = '?',
    desc = [[
Hide REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLHideOrFocus', M.commands.hide_or_focus, {
    count = true,
    nargs = '?',
    desc = [[
Hide or focus REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLClose', M.commands.close, {
    count = true,
    nargs = '?',
    desc = [[
Close REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLSwap', M.commands.swap, {
    desc = [[Swap two REPLs]],
    nargs = '*',
})

api.nvim_create_user_command('REPLAttachBufferToREPL', M.commands.attach_buffer, {
    count = true,
    bang = true,
    desc = [[
Attach current buffer to REPL `i`
]],
})

api.nvim_create_user_command('REPLDetachBufferToREPL', M.commands.detach_buffer, {
    count = true,
    desc = [[Detach current buffer to any REPL.]],
})

api.nvim_create_user_command('REPLSendVisual', M.commands.send_visual, {
    count = true,
    nargs = '?',
    desc = [[
Send visual range to REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLSendLine', M.commands.send_line, {
    count = true,
    nargs = '?',
    desc = [[
Send current line to REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLSendOperator', M.commands.send_operator, {
    count = true,
    nargs = '?',
    desc = [[
The operator of send text to REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLSourceVisual', M.commands.source_visual, {
    count = true,
    nargs = '?',
    desc = [[
Source visual range to REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLSourceOperator', M.commands.source_operator, {
    count = true,
    nargs = '?',
    desc = [[
Source visual range to REPL `i` or the REPL that current buffer is attached to.
]],
})

api.nvim_create_user_command('REPLExec', M.commands.exec, {
    count = true,
    nargs = '*',
    desc = [[
Execute a command in REPL `i` or the REPL that current buffer is attached to.
]],
})

return M
