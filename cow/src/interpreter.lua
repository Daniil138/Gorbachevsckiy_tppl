local interpreter ={}

interpreter["memory"] = {}
local size = 30000
for i = 1, size do
    interpreter.memory[i] = 0
end
interpreter["ptr"] = 1
interpreter["pc"] = 1

interpreter["register"] = 0
interpreter["jump_map"] = {}
interpreter["output"] = {}


function interpreter.get_commands(text)
    local result = {}
    local valid_ops = {
        moo = true, mOo = true, moO = true, mOO = true,
        Moo = true, MOo = true, MoO = true, MOO = true,
        OOO = true, MMM = true, OOM = true, oom = true}
    for com in text:gmatch("%a+") do
        if valid_ops[com] then
            table.insert(result, com)
        end
    end

    return result
end

function interpreter.interpretations_one_command(op,commands)

        if op == "mOo" and interpreter.ptr > 1 then 
            interpreter.ptr = interpreter.ptr - 1

        elseif op == "moO" and interpreter.ptr < 30000 then 
            interpreter.ptr = interpreter.ptr + 1

        elseif op == "MoO" then 
            interpreter.memory[interpreter.ptr] = interpreter.memory[interpreter.ptr] + 1

        elseif op == "MOo" then 
            interpreter.memory[interpreter.ptr] = interpreter.memory[interpreter.ptr] - 1

        elseif  op == "OOO" then
            interpreter.memory[interpreter.ptr] = 0        

        elseif op == "OOM" then
            table.insert(interpreter.output, tostring(interpreter.memory[interpreter.ptr]) .. "\n")

        elseif op == "Moo" then
            if interpreter.memory[interpreter.ptr] == 0 then 
                io.write("Input char: ")
                io.flush()
                local user_input = io.read("*l")  -- читает строку до перевода строки

                if user_input and user_input ~= "" then
                    interpreter.memory[interpreter.ptr] = string.byte(user_input, 1)  -- ASCII-код первого символа
                else
                    interpreter.memory[interpreter.ptr] = 0
                 end
            else 
                table.insert(interpreter.output, string.char(interpreter.memory[interpreter.ptr]%256))
            end

        elseif op == "MMM" then 
            if interpreter.register == 0 then 
                interpreter.register = interpreter.memory[interpreter.ptr]
            else
                interpreter.memory[interpreter.ptr] = interpreter.register
            end 

        elseif op == 'MOO' then
            if interpreter.memory[interpreter.ptr] == 0 then
                interpreter.pc = interpreter.jump_map[interpreter.pc]

            end

        elseif op == 'moo' then
            if interpreter.memory[interpreter.ptr] ~= 0 then
                interpreter.pc = interpreter.jump_map[interpreter.pc]
            end
            
        elseif op == "mOO" then
            if interpreter.memory[interpreter.ptr] <= #commands and interpreter.memory[interpreter.ptr] >=1  then
                if commands[interpreter.memory[interpreter.ptr]]~= "moo" and commands[interpreter.memory[interpreter.ptr]]~= "MOO" then
                    interpreter.interpretations_one_command(commands[interpreter.memory[interpreter.ptr]],commands)
                end
            end

        elseif op == "oom" then 

            io.write("Input number: ")
            io.flush()
            local input = io.read("*l")
            local num = tonumber(input) or 0
            interpreter.memory[interpreter.ptr] = num
        end
    
    
end

function interpreter.interpretations(commands)
   local jump_stack = {}

    for i = 1, #commands do 
        if commands[i] == "MOO" then 
            table.insert(jump_stack,i)
        elseif commands[i] == "moo" then
            if #jump_stack == 0 then
                error("Нет начала функции", 2)
            else
                local start = table.remove(jump_stack)
                interpreter.jump_map[start]  = i
                interpreter.jump_map[i] = start    
            
            end
        end
    end

    if #jump_stack > 0 then
        error("Нет конца функции", 2)
    end
    while interpreter.pc <= #commands do
        local op = commands[interpreter.pc]
        interpreter.interpretations_one_command(op,commands)
        interpreter.pc = interpreter.pc +1
    end
end

function  interpreter.start_code(code)
    local commands = interpreter.get_commands(code)
    interpreter.interpretations(commands)
    return table.concat(interpreter.output,"")
end
return interpreter