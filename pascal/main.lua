
local interpreter = require("src.interpreter")
local function print_table(tbl, indent, visited)
    if not indent then indent = 0 end
    if not visited then visited = {} end
    if visited[tbl] then
        print(string.rep("  ", indent) .. "*RECURSION*")
        return
    end
    visited[tbl] = true

    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    table.sort(keys, function(a, b)
        local ta, tb = type(a), type(b)
        if ta == "number" and tb == "number" then return a < b end
        if ta == "number" then return true end
        if tb == "number" then return false end
        return tostring(a) < tostring(b)
    end)
    for _, k in ipairs(keys) do
        local v = tbl[k]
        local key_str = type(k) == "string" and k or "[" .. tostring(k) .. "]"
        io.write(string.rep("  ", indent) .. key_str .. " = ")

        if type(v) == "table" then
            print()  
            print_table(v, indent + 1, visited)
        else
            print(tostring(v))
        end
    end
end


local filename = arg[1]
if not filename then
    print("Usage: lua script.lua <pascal_file>")
    os.exit(1)
end

local file = io.open(filename, "r")
if not file then
    print("Error: Cannot open file '" .. filename .. "'")
    os.exit(1)
end
local code = file:read("*all")
file:close()


print_table(interpreter.eval(code))
