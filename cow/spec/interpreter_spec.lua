local interpreter


local function reset_interpreter()
    interpreter.memory = {}
    local size = 30000
    for i = 1, size do
        interpreter.memory[i] = 0
    end
    interpreter.ptr = 1
    interpreter.pc = 1
    interpreter.register = 0
    interpreter.jump_map = {}
    interpreter.output = {}
end

describe("Cow Interpreter — модульные тестирование", function()
    setup(function()
        interpreter = require("src.interpreter")
        reset_interpreter()
    end)

    before_each(function()
        reset_interpreter()
    end)

    
    -- Тестирование get_commands 
    

    describe("get_commands", function()
        it("вернет коректный список команд", function()
            local code = "MoO reo moO meo MOO moo"
            local commands = interpreter.get_commands(code)
            assert.same({"MoO", "moO", "MOO", "moo"}, commands)
        end)

        it("выделит только команды без лишних символов", function()
            local code = "MoO\n\t moO 123 !@# MOO"
            local commands = interpreter.get_commands(code)
            assert.same({"MoO", "moO", "MOO"}, commands)
        end)
    end)

    
    -- Тестирование построения jump_map
    

    describe("jump_map construction", function()
        it("построит правильный массив переходов для циклов в данном случае {2,1}", function()
            local commands = interpreter.get_commands("MOO moo")
            interpreter.interpretations(commands)  
            assert.equal(2, interpreter.jump_map[1])  
            assert.equal(1, interpreter.jump_map[2])  
        end)

        it("построит правильный массив для вложеных циклов в данном случае {4,3,2,1}", function()
            local code = "MOO MOO moo moo"
            local commands = interpreter.get_commands(code)
            interpreter.interpretations(commands)
      
            assert.equal(4, interpreter.jump_map[1])
            assert.equal(1, interpreter.jump_map[4])
            assert.equal(3, interpreter.jump_map[2])
            assert.equal(2, interpreter.jump_map[3])
        end)

        it("проверяем ошибку что осталась не закрытая функция", function()
            local commands = interpreter.get_commands("MOO")
            assert.has_error(function()
                interpreter.interpretations(commands)
            end, "Нет конца функции")
        end)

        it("проверяем ошибку что осталась открытая функция", function()
            local commands = interpreter.get_commands("moo")
            assert.has_error(function()
                interpreter.interpretations(commands)
            end, "Нет начала функции")
        end)
    end)

    
    -- Тестирование отдельных команд через interpretations_one_command
    

    describe("проверка команд на корректность", function()
        local commands_stub = {}  

        it("mOo уменьшит указатель памяти на 1", function()
            interpreter.ptr = 5
            interpreter.interpretations_one_command("mOo", commands_stub)
            assert.equal(4, interpreter.ptr)
        end)

        it("moO увеличит указатель памяти на 1", function()
            interpreter.ptr = 1
            interpreter.interpretations_one_command("moO", commands_stub)
            assert.equal(2, interpreter.ptr)
        end)

        it("mOo не выйдет за рамки", function()
            interpreter.ptr = 1
            interpreter.interpretations_one_command("mOo", commands_stub)
            assert.equal(1, interpreter.ptr)
        end)

        it("moO не выйдет за рамки", function()
            interpreter.ptr = 30000
            interpreter.interpretations_one_command("moO", commands_stub)
            assert.equal(30000, interpreter.ptr)
        end)

        it("MoO увеличит значение ячейки на 1", function()
            interpreter.memory[1] = 10
            interpreter.interpretations_one_command("MoO", commands_stub)
            assert.equal(11, interpreter.memory[1])
        end)

        it("MOo уменьшит значение ячейки", function()
            interpreter.memory[1] = 10
            interpreter.interpretations_one_command("MOo", commands_stub)
            assert.equal(9, interpreter.memory[1])
        end)

        it("OOO обнулит значение ячейки", function()
            interpreter.memory[1] = 123
            interpreter.interpretations_one_command("OOO", commands_stub)
            assert.equal(0, interpreter.memory[1])
        end)

        it("MMM копирует врегистер если он 0", function()
            interpreter.memory[1] = 42
            interpreter.register = 0
            interpreter.interpretations_one_command("MMM", commands_stub)
            assert.equal(42, interpreter.register)
          
        end)

        it("MMM копирует из регистра если он не  0", function()
            interpreter.register = 99
            interpreter.memory[1] = 0
            interpreter.interpretations_one_command("MMM", commands_stub)
            assert.equal(99, interpreter.memory[1])
        end)

        it("OOM добавит в вывод число", function()
            interpreter.memory[1] = 777
            interpreter.interpretations_one_command("OOM", commands_stub)
            assert.equal(1, #interpreter.output)
            assert.equal("777\n", interpreter.output[1])
        end)

        it("Moo выведет строку если ячейка не 0", function()
            interpreter.memory[1] = 65  
            interpreter.interpretations_one_command("Moo", commands_stub)
            assert.equal(1, #interpreter.output)
            assert.equal("A", interpreter.output[1])
        end)


    end)

    
    -- Тестирование команд, зависящих от jump_map (MOO/moo)
    

    describe("loop commands (MOO/moo)", function()
        it("MOO при значении 0 в ячейке прыгнет на конец цыкла", function()
          
            interpreter.jump_map[1] = 3  
            interpreter.memory[1] = 0
            interpreter.pc = 1
            interpreter.interpretations_one_command("MOO", {})
            -- значение ячейки останеться, потому что движение по командам осуществляется в другой функции
            assert.equal(3, interpreter.pc)
        end)

        it("MOO должен начать выполнять цикл ", function()
            interpreter.memory[1] = 5
            interpreter.pc = 10
            interpreter.interpretations_one_command("MOO", {})
            -- значение ячейки останеться, потому что движение по командам осуществляется в другой функции
            assert.equal(10, interpreter.pc)
        end)

        it("moo должен вернуться на начало так как в ячейке не 0", function()
            interpreter.jump_map[5] = 2  
            interpreter.memory[1] = 1
            interpreter.pc = 5
            interpreter.interpretations_one_command("moo", {})
            -- значение ячейки останеться, потому что движение по командам осуществляется в другой функции
            assert.equal(2, interpreter.pc)
        end)

        it("moo должен пойти дальше если в ячейке 0", function()
            interpreter.memory[1] = 0
            interpreter.pc = 7
            interpreter.interpretations_one_command("moo", {})
            -- значение ячейки останеться, потому что движение по командам осуществляется в другой функции
            assert.equal(7, interpreter.pc)
        end)
    end)

    
    -- Интеграционные тесты (итоговое поведение)
    

    describe("integration", function()
        local function run(code)
            local ok, result = pcall(interpreter.start_code, code)
            if not ok then error(result) end
            return result
        end

        it("вернет Hi", function()
            local code = ("MoO "):rep(72) .. "Moo " ..  
                         "OOO " .. ("MoO "):rep(105) .. "Moo"  
            assert.equal("Hi", run(code))
        end)

        it("функция где обнуляется заранее заданное значение", function()
            local code = [[
                MoO MoO MoO     -- mem[1] = 3
                MOO
                    MOo         -- mem[1]--
                moo
                OOM
            ]]
            assert.equal("0\n", run(code))
        end)
    end)
end)