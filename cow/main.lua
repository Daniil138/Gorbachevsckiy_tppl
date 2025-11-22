local interpreter = require("src.interpreter")
local loader = require("src.loader")



if not arg[1] then
    io.stderr:write("Использование: lua main.lua <путь_к_файлу.cow>\n")
    os.exit(1)
end

local filepath = arg[1]

local code = loader.read_file(filepath)
local result = interpreter.start_code(code)

if result then
    io.write(result)
end