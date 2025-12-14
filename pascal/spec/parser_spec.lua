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

    it("parses a simple assignment", function()
        local ast = parse_code("BEGIN x := 5 END.")
        assert.equals("program", ast.tag)
        local stmts = ast.compound.statements
        assert.equals(1, #stmts)
        assert.equals("assign", stmts[1].tag)
        assert.equals("x", stmts[1].var.name)
        assert.equals(5, stmts[1].expr.value)
    end)

    it("parses multiple assignments", function()
        local ast = parse_code("BEGIN a := 1; b := 2 END.")
        local stmts = ast.compound.statements
        assert.equals(2, #stmts)
        assert.equals("a", stmts[1].var.name)
        assert.equals(1, stmts[1].expr.value)
        assert.equals("b", stmts[2].var.name)
        assert.equals(2, stmts[2].expr.value)
    end)

    it("parses empty compound statement", function()
        local ast = parse_code("BEGIN END.")
        assert.equals(0, #ast.compound.statements)
    end)

    it("parses nested compound statements", function()
        local ast = parse_code("BEGIN BEGIN x := 1 END END.")
        local outer = ast.compound.statements
        assert.equals(1, #outer)
        assert.equals("compound", outer[1].tag)
        local inner = outer[1].statements
        assert.equals(1, #inner)
        assert.equals("x", inner[1].var.name)
    end)

    it("parses arithmetic expressions with correct precedence", function()
        local ast = parse_code("BEGIN z := 2 + 3 * 4 END.")
        local expr = ast.compound.statements[1].expr
        -- Ожидаем: 2 + (3 * 4)
        assert.equals("binop", expr.tag)
        assert.equals("+", expr.op)
        assert.equals(2, expr.left.value)
        assert.equals("binop", expr.right.tag)
        assert.equals("*", expr.right.op)
        assert.equals(3, expr.right.left.value)
        assert.equals(4, expr.right.right.value)
    end)

    it("parses left-associative operations", function()
        local ast = parse_code("BEGIN a := 10 - 4 - 2 END.")
        local expr = ast.compound.statements[1].expr
        -- Ожидаем: (10 - 4) - 2
        assert.equals("binop", expr.tag)
        assert.equals("-", expr.op)
        assert.equals("binop", expr.left.tag)
        assert.equals("-", expr.left.op)
        assert.equals(10, expr.left.left.value)
        assert.equals(4, expr.left.right.value)
        assert.equals(2, expr.right.value)
    end)

    it("parses unary minus", function()
        local ast = parse_code("BEGIN x := -5 END.")
        local expr = ast.compound.statements[1].expr
        -- У нас эмуляция через 0 - 5
        assert.equals("binop", expr.tag)
        assert.equals("-", expr.op)
        assert.equals(0, expr.left.value)
        assert.equals(5, expr.right.value)
    end)

    it("parses unary plus", function()
        local ast = parse_code("BEGIN x := +42 END.")
        local expr = ast.compound.statements[1].expr
        assert.equals("binop", expr.tag)
        assert.equals("+", expr.op)
        assert.equals(0, expr.left.value)
        assert.equals(42, expr.right.value)
    end)

    it("parses parentheses", function()
        local ast = parse_code("BEGIN y := (1 + 2) * 3 END.")
        local expr = ast.compound.statements[1].expr
        -- Ожидаем: (1 + 2) * 3
        assert.equals("binop", expr.tag)
        assert.equals("*", expr.op)
        assert.equals("binop", expr.left.tag)
        assert.equals("+", expr.left.op)
        assert.equals(1, expr.left.left.value)
        assert.equals(2, expr.left.right.value)
        assert.equals(3, expr.right.value)
    end)

    it("parses identifiers with underscores and letters", function()
        local ast = parse_code("BEGIN my_var1 := 100 END.")
        assert.equals("my_var1", ast.compound.statements[1].var.name)
    end)

    it("rejects missing dot at end", function()
        assert.has_error(function()
            parse_code("BEGIN x := 5 END")  -- нет точки!
        end, "Syntax error at line 1: expected DOT, got EOF ('<eof>')")
    end)

    it("rejects missing END", function()
        assert.has_error(function()
            parse_code("BEGIN x := 5.")
        end, "Syntax error at line 1: expected END, got DOT ('.')")
    end)

    it("rejects invalid token after END", function()
        assert.has_error(function()
            parse_code("BEGIN x := 5 END ; .")
        end, "Syntax error at line 1: expected DOT, got SEMICOLON (';')")
    end)

    it("rejects malformed assignment", function()
        assert.has_error(function()
            parse_code("BEGIN x = 5 END.")
        end, "Unexpected character '=' at line 1")
    end)

    it("handles empty statements (e.g. ;;)", function()
        -- Это допустимо в EBNF: statement → empty
        local ast = parse_code("BEGIN ; ; x := 1 END.")
        -- Пустые операторы не порождают узлы (мы их игнорируем после ; если дальше END)
        -- Но в нашем парсере они не добавляются, если после ; сразу идёт END или другой statement
        -- В данном случае у нас 1 реальный оператор
        assert.equals(1, #ast.compound.statements)
    end)

    it("parses complex expression with mixed operators", function()
        local ast = parse_code("BEGIN r := a + b * c - d / 2 END.")
        -- a + (b * c) - (d / 2)
        local expr = ast.compound.statements[1].expr
        assert.equals("binop", expr.tag)
        assert.equals("-", expr.op)
        assert.equals("binop", expr.left.tag)
        assert.equals("+", expr.left.op)
        assert.equals("a", expr.left.left.name)
        assert.equals("*", expr.left.right.op)
        assert.equals("b", expr.left.right.left.name)
        assert.equals("c", expr.left.right.right.name)
        assert.equals("/", expr.right.op)
        assert.equals("d", expr.right.left.name)
        assert.equals(2, expr.right.right.value)
    end)

end)