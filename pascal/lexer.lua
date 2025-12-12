-- lexer.lua
-- Токенизатор который разобьет исходный текст на токены с определенным типом 

local lexer = {}

--Для проверки ключевых слов, чтобы можно было в проверке написать keywords["BEGIN"] -> true
local keywords = {
    BEGIN = true,
    END = true
}


function lexer.token(code)
    --Основная функция токенизатора
    local pos = 1
    local line = 1
    local tokens = {}
    local code_len = #code
    local current_char = code:sub(pos,pos)
    local last_token = ""

    --функция которая двигается на след символ  и проверяет переход на след строку
    local function forward()        
        pos = pos + 1
        if pos > code_len then 
            return '\0'
        end

        local c = current_char
        if c == "\n" then 
            line = line +1
        end

        
    end
    -- Функция пропуска всего ненужного 
    local function skip()
        while current_char ~= '\0' and current_char  == ' ' or current_char == '\t' or current_char == '\n' or current_char == '\r' do
            forward()
        end
    end

    local function get_token()
        local start = pos
        forward()
        while current_char:match('[a-zA-Z0-9_]') do 
            forward()
        end
        return code:sub(start,pos-1)        
    end

    local function next_token()
        while current_char ~= '\0' do
            if current_char  == ' ' or current_char == '\t' or current_char == '\n' or current_char == '\r' then
                skip()
            end


        end
            
        
        
    end



    
end