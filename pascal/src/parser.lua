
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
local function ProgramNode(stmt) return { tag = "program", statement = stmt } end




-- === Parser ===
local parser = {}
-- Внутреннее состояние парсера
local current_token
local lexer_instance

function parser:new(lexer_instance)
    local obj = {
        lexer = lexer_instance,
        current_token = lexer_instance.next_token()
    }
    setmetatable(obj, parser)
    return obj
end

local function eat(expected_type)
    if current_token.type == expected_type then
        current_token = lexer_instance.next_token()
    else
        error(string.format(
            "Syntax error at line %d: expected %s, got %s ('%s')",
            current_token.line,
            expected_type,
            current_token.type,
            tostring(current_token.token)
        ))
    end
end

-- factor : ( '+' | '-' ) factor
--        | INTEGER
--        | LPAREN expr RPAREN
--        | variable
local function factor()
    local token = current_token

    if token.type == token_type.OPERATOR then
        if token.token == '+' then
            eat(token_type.OPERATOR)
            local f = factor()
            return BinOpNode(NumberNode(0), '+', f)
        elseif token.token == '-' then
            eat(token_type.OPERATOR)
            local f = factor()
            return BinOpNode(NumberNode(0), '-', f)
        else
            error("Unexpected operator in factor at line " .. token.line)
        end

    elseif token.type == token_type.NUMBER then
        eat(token_type.NUMBER)
        return NumberNode(token.token)

    elseif token.type == token_type.LPAREN then
        eat(token_type.LPAREN)
        local expr_node = expr()
        eat(token_type.RPAREN)
        return expr_node

    elseif token.type == token_type.IDENTIFIER then
        local var = VariableNode(token.token)
        eat(token_type.IDENTIFIER)
        return var

    else
        error("Invalid syntax in factor at line " .. token.line)
    end
end

-- term : factor (( '*' | '/' ) factor)*
local function term()
    local node = factor()

    while current_token.type == token_type.OPERATOR and
          (current_token.token == '*' or current_token.token == '/') do
        local op = current_token.token
        eat(token_type.OPERATOR)
        local right = factor()
        node = BinOpNode(node, op, right)
    end

    return node
end

-- expr : term (( '+' | '-' ) term)*
local function expr()
    local node = term()

    while current_token.type == token_type.OPERATOR and
          (current_token.token == '+' or current_token.token == '-') do
        local op = current_token.token
        eat(token_type.OPERATOR)
        local right = term()
        node = BinOpNode(node, op, right)
    end

    return node
end

-- assignment : variable ASSIGN expr
local function assignment()
    local var_token = current_token
    local var_node = VariableNode(var_token.token)
    eat(token_type.IDENTIFIER)
    eat(token_type.ASSIGN)
    local expr_node = expr()
    return AssignmentNode(var_node, expr_node)
end

-- empty
local function empty()
    return EmptyNode()
end

-- statement : compound_statement | assignment | empty
local function statement()
    if current_token.type == token_type.BEGIN then
        return compound_statement()
    elseif current_token.type == token_type.IDENTIFIER then
        return assignment()
    else
        return empty()
    end
end

-- statement_list : statement | statement SEMI statement_list
local function statement_list()
    local statements = { statement() }

    while current_token.type == token_type.SEMICOLON do
        eat(token_type.SEMICOLON)
        if current_token.type == token_type.END then
            break
        end
        table.insert(statements, statement())
    end

    return statements
end

-- compound_statement : BEGIN statement_list END
local function compound_statement()
    eat(token_type.BEGIN)
    local stmts = statement_list()
    eat(token_type.END)
    return CompoundNode(stmts)
end

-- program : complex_statement DOT   (complex_statement = compound_statement)
local function program()
    local comp = compound_statement()
    eat(token_type.DOT)
    return ProgramNode(comp)
end

-- === Публичный API ===

function parser.set_lexer(lex)
    if type(lex) ~= "table" or type(lex.next_token) ~= "function" then
        error("parser.set_lexer(): expected a lexer instance")
    end
    lexer_instance = lex
    current_token = lexer_instance.next_token()
end

function parser.parse()
    if not lexer_instance then
        error("parser.parse(): lexer not set. Call parser.set_lexer() first.")
    end
    return program()
end

return parser