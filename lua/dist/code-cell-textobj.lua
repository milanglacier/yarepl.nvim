local M = {}

function M.textobj_code_chunk(
    around_or_inner,
    start_pattern,
    end_pattern,
    has_same_start_end_pattern,
    is_in_visual_mode
)
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
        if not has_same_start_end_pattern and line_content:match(end_pattern) then
            return
        end

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

function M.setup(config)
    -- example config
    --  {
    --     global = {
    --         k = { '###', '###', true },
    --     },
    --     ft = {
    --         python = {
    --             c = { '^# ?%%%%.*', '^# ?%%%%.*', true },
    --         },
    --         markdown = {
    --             c = { '```{.+}', '^```$', false },
    --         },
    --     },
    -- }
    -- for each entry, the first parameter is the the lua pattern (note that
    -- lua pattern is not the same as vim regex) to match the beginning of the
    -- code cell, the second parameter is the lua pattern to match the end of
    -- the code cell, the third parameter is a boolean value to indicate
    -- whether the start and end pattern are the same. If false, then when it
    -- detects that the cursor is not in a code cell, it will return nothing.
    -- Say for example, in markdown, the start pattern is ```{python} and the
    -- end pattern is ```, then the start and end pattern are not the same. and
    -- if the cursor is not in a code cell, then it will return nothing.
end

return M
