local source={}
function source.new() return setmetatable({},{__index=source}) end
function source.complete(_,params,callback)
    local function convert(comp)
        local text=comp.completion.text
        local range={
            start={
                line=tonumber(comp.range.startPosition.row) or 0,
                character=params.offset-1,
            },
            ["end"]={
                line=tonumber(comp.range.endPosition.row) or 0,
                character=comp.range.endPosition.col,
            },
        }
        return {
            documentation={kind='markdown',value=('```%s\n%s\n```'):format(vim.o.filetype,text)},
            label=vim.trim(text:sub(params.offset)),
            textEdit={newText=text:sub(params.offset),insert=range,replace=range},
        }
    end
    local other={}
    for _,v in ipairs(vim.tbl_filter(vim.api.nvim_buf_is_loaded,vim.api.nvim_list_bufs())) do
        if v~=vim.api.nvim_get_current_buf() and vim.bo[v].buflisted then
            table.insert(other,vim.fn['codeium#doc#GetDocument'](v,1,1))
        end
    end
    local data={
        metadata=vim.fn['codeium#server#RequestMetadata'](),
        document=vim.fn['codeium#doc#GetDocument'](vim.fn.bufnr(),vim.fn.line'.',vim.fn.col'.'),
        editor_options=vim.fn['codeium#doc#GetEditorOptions'](),
        other_documents=other,
    }
    local function fn(json,_,_)
        local event=vim.json.decode(table.concat(json,''))
        if event.code or not event.completionItems then return end
        callback(vim.tbl_map(convert,event.completionItems))
    end
    pcall(vim.fn['codeium#server#Request'],'GetCompletions',data,fn)
end
return source
