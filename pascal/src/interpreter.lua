local lexer = require("src.lexer")
local parser = require("src.parser")


local interpreter = {}


interpreter.lexer = lexer
interpreter.parser = parser
interpreter.parser.set_lexer(interpreter.lexer)




function interpreter.visit(node)
    if node.tag == "assign" then
        interpreter.visit_assign(node)

    elseif node.tag == "number" then
        return interpreter.visit_number(node)

    elseif  node.tag == "variable" then
        return interpreter.variable(node)

    elseif node.tag == "binop" then
        return interpreter.visit_binop(node)
    elseif node.tag == "empty" then
        return
    end
end

function interpreter.visit_number(node)
    return node.value.token+0.0
end

function interpreter.variable(node)
    if interpreter.variables[node.name.token]~=nil then
        return interpreter.variables[node.name.token]
    else 
        return error("Undefined variabl: " .. node.name.token .. " in line " .. node.name.line)
    end
end

function interpreter.visit_assign(node)
    local variabl = node.var.name.token
    local value = interpreter.visit(node.expr)
    interpreter.variables[variabl] = value
    
end


function interpreter.visit_binop(node)
    local op = node.op.token
    local left = interpreter.visit(node.left)
    local right = interpreter.visit(node.right)
    if op == "+" then
        return left + right
    elseif op == "-" then
        return left - right
    elseif op == "*" then
        return left * right
    elseif op == "/" then
        return left / right
    end
end


function interpreter.eval(text)
    interpreter.variables = {}
    interpreter.lexer.set_text(text)
    local ast = interpreter.parser.parse().programm.statements
    for _,node in pairs(ast) do
        interpreter.visit(node)
    end
    return interpreter.variables
end

return interpreter