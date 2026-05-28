local M = {}


function M.start(buf)
    
    vim.api.nvim_buf_set_lines(
        buf,
        0,
        -1,
        false,
        { "" }
    )

    return {
        buf = buf,
        done = false,
        job_id = nil,
        current_line = ""
    }

end

function M.append(stream, chunk)
    if stream.done then return end
    if not chunk or chunk == "" then return end
  
    if not vim.api.nvim_buf_is_valid(stream.buf) then
        stream.done = true
        return
    end

    -- merge with unfinished fragment
    chunk = stream.current_line .. chunk

    --split chunk into lines
    local parts = vim.split(
        chunk,
        "\n",
        { plain = true }
    )

    stream.current_line = table.remove(parts) or ""

    if #parts > 0 then
        vim.api.nvim_buf_set_lines(
            stream.buf,
            -1,
            -1,
            false,
            parts
        )
    end

    --update current unfinished line 
   local line_count = vim.api.nvim_buf_line_count(stream.buf)

        -- append active streaming line
        vim.api.nvim_buf_set_lines(
            stream.buf,
           line_count - 1,
            line_count,
            false,
            { stream.current_line }
        )
    end


function M.finish(stream)
    stream.done = true
    end


function M.abort(stream)
    if stream.job_id then
        vim.fn.jobstop(stream.job_id)
    end

    stream.done = true
end


return M