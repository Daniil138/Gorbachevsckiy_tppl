-- spec/parser_spec.lua
local lexer = require("src.lexer")
local parser = require("src.parser")
local token_type = require("src.token")

-- Вспомогательная функция для быстрого парсинга строки
local function parse_code(code)
    lexer.set_text(code)
    parser.set_lexer(lexer)
    return parser.parse()
end

describe("Parser", function()
    it("error receiving lexer", function()
        assert.has_error(function()
            parser.parse()
        end, "parser.parse(): lexer not set. Call parser.set_lexer() first.")
    end)

    it("parses a simple assignment", function()
        local ast = parse_code("BEGIN x := 5 END.")
        assert.equals("program", ast.tag)
        local stmts = ast.programm.statements
        assert.equals(1, #stmts)
        assert.equals("assign", stmts[1].tag)
        assert.equals("x", stmts[1].var.name.token)
        assert.equals(5, stmts[1].expr.value.token)
    end)

    it("parses multiple assignments", function()
        local ast = parse_code("BEGIN a := 1; b := 2 END.")
        local stmts = ast.programm.statements
        assert.equals(2, #stmts)
        assert.equals("a", stmts[1].var.name.token)
        assert.equals(1, stmts[1].expr.value.token)
        assert.equals("b", stmts[2].var.name.token)
        assert.equals(2, stmts[2].expr.value.token)
    end)

    it("parses empty programm statement", function()
        local ast = parse_code("BEGIN END.")
        assert.equals(0, #ast.programm.statements[1])
    end)

    it("parses nested programm statements", function()
        local ast = parse_code("BEGIN BEGIN x := 1 END END.")
        local outer = ast.programm.statements
        assert.equals(1, #outer)
        assert.equals("compound", outer[1].tag)
        local inner = outer[1].statements
        assert.equals(1, #inner)
        assert.equals("x", inner[1].var.name.token)
    end)

    it("parses arithmetic expressions with correct precedence", function()
        local ast = parse_code("BEGIN z := 2 + 3 * 4 END.")
        local expr = ast.programm.statements[1].expr

        assert.equals("binop", expr.tag)
        assert.equals("+", expr.op.token)
        assert.equals(2, expr.left.value.token)
        assert.equals("binop", expr.right.tag)
        assert.equals("*", expr.right.op.token)
        assert.equals(3, expr.right.left.value.token)
        assert.equals(4, expr.right.right.value.token)
    end)

    it("parses left-associative operations", function()
        local ast = parse_code("BEGIN a := 10 - 4 - 2 END.")
        local expr = ast.programm.statements[1].expr

        assert.equals("binop", expr.tag)
        assert.equals("-", expr.op.token)
        assert.equals("binop", expr.left.tag)
        assert.equals("-", expr.left.op.token)
        assert.equals(10, expr.left.left.value.token)
        assert.equals(4, expr.left.right.value.token)
        assert.equals(2, expr.right.value.token)
    end)

    it("parses unary minus", function()
        local ast = parse_code("BEGIN x := -5 END.")
        local expr = ast.programm.statements[1].expr

        assert.equals("binop", expr.tag)
        assert.equals("-", expr.op.token)
        assert.equals(0, expr.left.value.token)
        assert.equals(5, expr.right.value.token)
    end)

    it("parses unary plus", function()
        local ast = parse_code("BEGIN x := +42 END.")
        local expr = ast.programm.statements[1].expr
        assert.equals("binop", expr.tag)
        assert.equals("+", expr.op.token)
        assert.equals(0, expr.left.value.token)
        assert.equals(42, expr.right.value.token)
    end)

    it("parses parentheses", function()
        local ast = parse_code("BEGIN y := (1 + 2) * 3 END.")
        local expr = ast.programm.statements[1].expr

        assert.equals("binop", expr.tag)
        assert.equals("*", expr.op.token)
        assert.equals("binop", expr.left.tag)
        assert.equals("+", expr.left.op.token)
        assert.equals(1, expr.left.left.value.token)
        assert.equals(2, expr.left.right.value.token)
        assert.equals(3, expr.right.value.token)
    end)

    it("parses identifiers with underscores and letters", function()
        local ast = parse_code("BEGIN my_var1 := 100 END.")
        assert.equals("my_var1", ast.programm.statements[1].var.name.token)
    end)

    it("rejects missing dot at end", function()
        assert.has_error(function()
            parse_code("BEGIN x := 5 END")
        end, "Invalid syntax at line 1 token: <eof> but token should be type DOT")
    end)

    it("rejects missing END", function()
        assert.has_error(function()
            parse_code("BEGIN x := 5.")
        end, "Invalid syntax at line 1 token: . but token should be type END")
    end)

    it("rejects invalid token after END", function()
        assert.has_error(function()
            parse_code("BEGIN x := 5 END ; .")
        end, "Invalid syntax at line 1 token: ; but token should be type DOT")
    end)

    it("handles empty statements (e.g. ;;)", function()
        -- в данном случае получим две пустые ноды и одну с присваеванием
        local ast = parse_code("BEGIN ; ; x := 1 END.")
        assert.equals(3, #ast.programm.statements)
    end)

    it("rejects invalid token after *", function()
        assert.has_error(function()
            parse_code("BEGIN x := 5 * BEGIN END.")
        end, "Invalid factor at line 1 token: BEGIN")
    end)
        


    it("parses complex expression with mixed operators", function()
        local ast = parse_code("BEGIN r := a + b * c - d / 2 END.")
 
        local expr = ast.programm.statements[1].expr
        assert.equals("binop", expr.tag)
        assert.equals("-", expr.op.token)
        assert.equals("binop", expr.left.tag)
        assert.equals("+", expr.left.op.token)
        assert.equals("a", expr.left.left.name.token)
        assert.equals("*", expr.left.right.op.token)
        assert.equals("b", expr.left.right.left.name.token)
        assert.equals("c", expr.left.right.right.name.token)
        assert.equals("/", expr.right.op.token)
        assert.equals("d", expr.right.left.name.token)
        assert.equals(2, expr.right.right.value.token)
    end)

end)