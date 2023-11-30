local codeium_started=false
local source={}
local function code2cmp(comp,offset)
    local text=comp.completion.text
    local range={
        start={
            line=tonumber(comp.range.startPosition.row) or 0,
            character=offset-1,
        },
        ["end"]={
            line=tonumber(comp.range.endPosition.row) or 0,
            character=comp.range.endPosition.col,
        },
    }
    return {
        documentation={kind='markdown',value=('```%s\n%s\n```'):format(vim.o.filetype,text)},
        label=text,
        textEdit={newText=text:sub(offset),insert=range,replace=range},
    }
end
function source.new() return setmetatable({},{__index=source}) end
function source.complete(_,params,callback)
    local offset=params.offset
    local data={
        metadata=vim.fn['codeium#server#RequestMetadata'](),
        document=vim.fn['codeium#doc#GetDocument'](vim.fn.bufnr(),vim.fn.line'.',vim.fn.col'.'),
        editor_options=vim.fn['codeium#doc#GetEditorOptions'](),
        other_documents={},
    }
    local function fn(json,_,_)
        local event=vim.json.decode(table.concat(json,''))
        if event.code then return end
        local citems=event.completionItems or {}
        local completions={}
        for _,comp in ipairs(citems) do
            table.insert(completions,code2cmp(comp,offset))
        end
        callback(completions)
    end
    local s,_=pcall(vim.fn['codeium#server#Request'],'GetCompletions',data,fn)
    if not s then return end
end
return source
