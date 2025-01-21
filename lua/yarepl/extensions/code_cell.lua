local M = {}

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup('yarepl.code_cell', {})
local bufmap = vim.api.nvim_buf_set_keymap

function M.textobj_code_cell(around_or_inner, start_pattern, end_pattern)
    local has_same_start_end_pattern = start_pattern == end_pattern
    -- \22 is Ctrl-V
    local is_in_visual_mode = vim.tbl_contains({ 'v', 'V', '\22' }, vim.fn.mode())

    -- send `<ESC>` key to clear visual marks such that we can update the
    -- visual range.
    if is_in_visual_mode then
        vim.api.nvim_feedkeys('\27', 'nx', false)
    end

    local row = vim.api.nvim_win_get_cursor(0)[1]
    local max_row = vim.api.nvim_buf_line_count(0)

    -- nvim_buf_get_lines is 0 indexed, while nvim_win_get_cursor is 1 indexed
    local chunk_start = nil

    for row_idx = row, 1, -1 do
        local line_content = vim.api.nvim_buf_get_lines(0, row_idx - 1, row_idx, false)[1]

        -- upward searching if find the end_pattern first which means
        -- the cursor pos is not in a chunk, then early return
        -- this method only works when start and end pattern are not same
        ---@diagnostic disable-next-line undefined-filed
        if not has_same_start_end_pattern and line_content:match(end_pattern) then
            return
        end

        ---@diagnostic disable-next-line undefined-filed
        if line_content:match(start_pattern) then
            chunk_start = row_idx
            break
        end
    end

    -- if find chunk_start then find chunk_end
    local chunk_end = nil

    if chunk_start then
        if chunk_start == max_row then
            return
        end

        for row_idx = chunk_start + 1, max_row, 1 do
            local line_content = vim.api.nvim_buf_get_lines(0, row_idx - 1, row_idx, false)[1]

            ---@diagnostic disable-next-line undefined-filed
            if line_content:match(end_pattern) then
                chunk_end = row_idx
                break
            end
        end
    end

    if chunk_start and chunk_end then
        if around_or_inner == 'i' then
            vim.api.nvim_win_set_cursor(0, { chunk_start + 1, 0 })
            local internal_length = chunk_end - chunk_start - 2
            if internal_length == 0 then
                vim.cmd.normal { 'V', bang = true }
            elseif internal_length > 0 then
                vim.cmd.normal { 'V' .. internal_length .. 'j', bang = true }
            end
        end

        if around_or_inner == 'a' then
            vim.api.nvim_win_set_cursor(0, { chunk_start, 0 })
            local chunk_length = chunk_end - chunk_start
            vim.cmd.normal { 'V' .. chunk_length .. 'j', bang = true }
        end
    end
end

function M.set_code_cell_keymaps(start_pattern, end_pattern, key, desc)
    for _, mode in ipairs { 'o', 'x' } do
        for _, around_or_inner in ipairs { 'a', 'i' } do
            bufmap(0, mode, around_or_inner .. key, '', {
                silent = true,
                desc = desc,
                callback = function()
                    M.textobj_code_cell(around_or_inner, start_pattern, end_pattern)
                end,
            })
        end
    end
end

function M.register_text_objects(options)
    for _, opt in ipairs(options) do
        autocmd('FileType', {
            group = augroup,
            desc = 'Setup yarepl code cell text objects: ' .. opt.desc,
            callback = function()
                M.set_code_cell_keymaps(opt.start_pattern, opt.end_pattern, opt.key, opt.desc)
            end,
            pattern = opt.ft,
        })
    end
end

return M
