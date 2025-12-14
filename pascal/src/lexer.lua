-- lexer.lua
-- Токенизатор который разобьет исходный текст на токены с определенным типом 

local lexer = {}


local token_type = require("src.token")

--Для проверки ключевых слов, чтобы можно было в проверке написать keywords["BEGIN"] -> true
local keywords = {
    BEGIN = true,
    END = true
}

function lexer.set_text(text)
    if text == nil or type(text) ~= "string" or #text == 0 then
        error("lexer.set_text(): expected a string")
    end
    lexer.pos = 1
    lexer.line = 1
    lexer.code = text
    lexer.current_char = lexer.code:sub(lexer.pos,lexer.pos)
end

function lexer.next_token()



    --функция которая двигается на след символ  и проверяет переход на след строку
    local function forward()        
        lexer.pos = lexer.pos + 1
        if lexer.current_char == "\n" then
                lexer.line = lexer.line +1
        end

        if lexer.pos > #lexer.code then
            lexer.current_char ='\0'
        else
            lexer.current_char = lexer.code:sub(lexer.pos,lexer.pos)
        end
    end

    -- Функция пропуска всего ненужного 
    local function skip()
        while lexer.current_char ~= '\0' and (lexer.current_char  == ' ' or lexer.current_char == '\t' or lexer.current_char == '\n' or lexer.current_char == '\r') do
            forward()
        end
    end



    -- Получаем любой токен кроме знаков и скобок 
    local function get_token()
        local start = lexer.pos
        forward()
        while lexer.current_char:match('[a-zA-Z0-9_]') do 
            forward()
        end
        return lexer.code:sub(start,lexer.pos-1)        
    end

    --Добавление токена 
    local function token(type,value)
        return {
            token = value,
            type = type,
            line = lexer.line
        }
    end

    if lexer.current_char  == ' ' or lexer.current_char == '\t' or lexer.current_char == '\n' or lexer.current_char == '\r' then
        skip()
    end


    if lexer.current_char == '\0' then
        return token(token_type.EOF, "<eof>")
    end



    if lexer.current_char:match('[a-zA-Z0-9_]') then 

        local new_token = get_token()

            if new_token:match("^[0-9]+$") then
                return token(token_type.NUMBER , tonumber(new_token))

            elseif new_token:match("^[a-zA-Z_][a-zA-Z0-9_]*$") then

                local upper = new_token:upper()

                if upper == "BEGIN" then
                    return token(token_type.BEGIN, new_token)
                elseif upper == "END" then
                    return token(token_type.END,upper)
                else
                    return token(token_type.IDENTIFIER, new_token)
                end
            else
                error("Unexpected token at line " .. lexer.line .. " (expected " .. new_token ..")")
            end

        elseif lexer.current_char == ':' then
            forward()  
            if lexer.current_char == '=' then
                forward() 
                return token(token_type.ASSIGN, ':=')
            else
                error("Unexpected ':' at line " .. lexer.line .. " (expected ':=')")
        end

        elseif lexer.current_char == '.' then
            local char = lexer.current_char
            forward()
            return token(token_type.DOT, char)

        elseif lexer.current_char == ';' then
            local char = lexer.current_char
            forward()
            return token(token_type.SEMICOLON, char)

        elseif lexer.current_char == '+' or lexer.current_char == '-' or lexer.current_char == '*' or lexer.current_char == '/' then
            local op = lexer.current_char
            forward()
            return token(token_type.OPERATOR, op)

        elseif lexer.current_char == '(' then
            local char = lexer.current_char
            forward()
            return token(token_type.LPAREN, char)

        elseif lexer.current_char == ')' then
            local char = lexer.current_char
            forward()
            return token(token_type.RPAREN, char)

        else
            error("Unexpected character '" .. lexer.current_char .. "' at line " .. lexer.line)
        end

end

return lexer