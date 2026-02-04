local finders = require 'telescope.finders'
local pickers = require 'telescope.pickers'

local conf = require('telescope.config').values

local function REPLShow(opts)
    vim.cmd.REPLCleanup()

    local repls = require('yarepl')._repls
    local buffers = {}
    for _, repl in ipairs(repls) do
        table.insert(buffers, { bufnr = repl.bufnr, name = vim.api.nvim_buf_get_name(repl.bufnr) })
    end
    if #buffers == 0 then
        return
    end

    local function focus_repl(prompt_bufnr)
        local actions = require 'telescope.actions'
        local action_state = require 'telescope.actions.state'
        local selection = action_state.get_selected_entry()
        if not selection then
            return
        end

        for id, repl in ipairs(repls) do
            if repl.bufnr == selection.bufnr then
                actions.close(prompt_bufnr)
                -- Open the REPL buffer with configured wincmd.
                vim.cmd(id .. 'REPLFocus')
                return
            end
        end
    end

    pickers
        .new(opts, {
            prompt_title = 'REPL Buffers',
            finder = finders.new_table {
                results = buffers,
                entry_maker = function(entry)
                    return {
                        value = entry.name,
                        display = ' ' .. entry.name,
                        ordinal = entry.name,
                        bufnr = entry.bufnr,
                        lnum = vim.api.nvim_buf_line_count(entry.bufnr),
                    }
                end,
            },
            previewer = conf.grep_previewer(opts),
            sorter = conf.generic_sorter(opts),
            default_selection_index = 1,
            attach_mappings = function(_, _)
                local actions = require 'telescope.actions'
                actions.select_default:replace(focus_repl)
                return true
            end,
        })
        :find()
end

return require('telescope').register_extension {
    exports = {
        REPLShow = REPLShow,
    },
}
