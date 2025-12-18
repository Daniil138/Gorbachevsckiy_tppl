
local interpreter = require("src.interpreter")
local function print_table(tbl, indent, visited)
    if not indent then indent = 0 end
    if not visited then visited = {} end

    -- Защита от рекурсивных ссылок
    if visited[tbl] then
        print(string.rep("  ", indent) .. "*RECURSION*")
        return
    end
    visited[tbl] = true

    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end

    -- Сортируем ключи: сначала числовые, потом строковые
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
            print()  -- Перевод строки перед вложенной таблицей
            print_table(v, indent + 1, visited)
        else
            print(tostring(v))
        end
    end
end

local code = [[
BEGIN
  x := 5;
  y := (x + 3) * 2;
  ;;
END.
]]

print_table(interpreter.eval(code))
