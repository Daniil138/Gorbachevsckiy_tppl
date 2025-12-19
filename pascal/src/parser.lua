
-- src/parser.lua
local token_type = require("src.token")
local lexer = require("src.lexer")



-- AST узлы 
local function NumberNode(value) return { tag = "number", value = value } end
local function BinOpNode(left, op, right) return { tag = "binop", left = left, op = op, right = right } end
local function VariableNode(name) return { tag = "variable", name = name } end
local function AssignmentNode(var, expr) return { tag = "assign", var = var, expr = expr } end
local function CompoundNode(statements) return { tag = "compound", statements = statements } end
local function EmptyNode() return { tag = "empty" } end
local function ProgramNode(stmt) return { tag = "program", programm = stmt } end




-- === Parser ===
local parser = {}


function parser.parse()
    if not parser.lexer then
        error("parser.parse(): lexer not set. Call parser.set_lexer() first.")
    end
    return parser.program()
end



function  parser.set_lexer(lex)
    if type(lex) == "table" and type(lex.next_token) == "function" then
        parser.lexer = lex
        
    end
end



function parser.check_token_type(tk_type)
    if tk_type == parser.current_token.type then
        parser.current_token = parser.lexer.next_token()
    else
        return error("Invalid syntax at line " .. parser.current_token.line .. " token: " .. parser.current_token.token .. " but token should be type " .. tk_type)
    end
end


function parser.term()
    local node = parser.factor()

    while parser.current_token.type == token_type.OPERATOR and
          (parser.current_token.token == '*' or parser.current_token.token == '/') do
        local op = parser.current_token
        parser.check_token_type(token_type.OPERATOR)
        local right = parser.factor()
        node = BinOpNode(node, op, right)
    end

    return node
end


function parser.expr()
    local node = parser.term()
    while parser.current_token.type == token_type.OPERATOR and
          (parser.current_token.token == '+' or parser.current_token.token == '-') do
            local op = parser.current_token
            parser.check_token_type(token_type.OPERATOR)
            local right = parser.term()
            node = BinOpNode(node, op, right)
    end 
    return node 
end

function parser.factor()
    local token = parser.current_token

    if token.type == token_type.NUMBER then
        parser.check_token_type(token_type.NUMBER)
        return NumberNode(token)
    elseif token.type == token_type.LPAREN then
        parser.check_token_type(token_type.LPAREN)
        local res = parser.expr()
        parser.check_token_type(token_type.RPAREN)
        return res
    elseif token.type == token_type.IDENTIFIER then
        parser.check_token_type(token_type.IDENTIFIER)
        return VariableNode(token)
    elseif  token.type == token_type.OPERATOR then
        if token.token == "+" then
            local op = token
            parser.check_token_type(token_type.OPERATOR)
            local f = parser.factor()
            return BinOpNode(NumberNode({token = 0, type = token_type.NUMBER}),op,f)
        elseif token.token == "-" then
            local op = token
            parser.check_token_type(token_type.OPERATOR)
            local f = parser.factor()
            return BinOpNode(NumberNode({token = 0, type = token_type.NUMBER}),op,f)
        end

    end
    return error("Invalid factor at line " .. parser.current_token.line .. " token: " .. parser.current_token.token)
    
end




function parser.assigment()
    local var_name = parser.current_token
    local var_node = VariableNode(var_name)
    parser.check_token_type(token_type.IDENTIFIER)
    parser.check_token_type(token_type.ASSIGN)
    local var_expr = parser.expr()
    return AssignmentNode(var_node, var_expr)
end



function parser.empty()
    return EmptyNode()
end




function parser.statement()
    if parser.current_token.type == token_type.BEGIN then
        return parser.complex_statement()
    elseif parser.current_token.type == token_type.IDENTIFIER then 
        return parser.assigment()
    else 
        return parser.empty()
    end
    
end

function parser.statement_list()
    local statements = { parser.statement()}
    while parser.current_token.type == token_type.SEMICOLON do
        parser.check_token_type(token_type.SEMICOLON)
        if parser.current_token.type== token_type.END then
            break
        end
        table.insert(statements,parser.statement())
        
    end
    return statements
end


function parser.complex_statement()
    parser.check_token_type(token_type.BEGIN)
    local statement_list = parser.statement_list()
    parser.check_token_type(token_type.END)
    return CompoundNode(statement_list)
    
end

function parser.program()
    parser.current_token = parser.lexer.next_token()
    local stmt = parser.complex_statement()
    parser.check_token_type(token_type.DOT)
    return ProgramNode(stmt)
end


return parser