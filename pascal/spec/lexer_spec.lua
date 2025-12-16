-- spec/lexer_spec.lua
local lexer
local token_type

lexer = require("src.lexer")
token_type = require("src.token")

-- Вспомогательная функция: токенизировать строку полностью
local function tokenize(code)
    lexer.set_text(code)
    local tokens = {}
    local tok
    repeat
        tok = lexer.next_token()
        if tok and tok.type ~= token_type.EOF then
            table.insert(tokens, tok)
        end
    until not tok or tok.type == token_type.EOF
    return tokens
end

-- Функция для сравнения токенов
local function expect_token(actual, expected_type, expected_value)
    assert.are.equals(expected_type, actual.type)
    if expected_value then
        assert.are.equals(expected_value, actual.token)
    end
end

describe("Pascal Lexer", function()

    it("should tokenize a simple program: BEGIN x := 42; END.", function()
        local tokens = tokenize("BEGIN x := 42; END.")
        assert(#tokens == 7)

        expect_token(tokens[1], token_type.BEGIN, "BEGIN")
        expect_token(tokens[2], token_type.IDENTIFIER, "x")
        expect_token(tokens[3], token_type.ASSIGN, ":=")
        expect_token(tokens[4], token_type.NUMBER, 42)
        expect_token(tokens[5], token_type.SEMICOLON, ";")
        expect_token(tokens[6], token_type.END, "END")
    end)

    it("should handle identifiers with underscores and numbers", function()
        local tokens = tokenize("var_123")
        assert(#tokens == 1)
        expect_token(tokens[1], token_type.IDENTIFIER, "var_123")
    end)

    it("should tokenize numbers correctly", function()
        local tokens = tokenize("123 456")
        assert(#tokens == 2)
        expect_token(tokens[1], token_type.NUMBER, 123)
        expect_token(tokens[2], token_type.NUMBER, 456)
    end)

    it("should handle operators: + - * /", function()
        local tokens = tokenize("+ - * /")
        assert(#tokens == 4)
        expect_token(tokens[1], token_type.OPERATOR, "+")
        expect_token(tokens[2], token_type.OPERATOR, "-")
        expect_token(tokens[3], token_type.OPERATOR, "*")
        expect_token(tokens[4], token_type.OPERATOR, "/")
    end)

    it("should handle parentheses and dot", function()
        local tokens = tokenize("( ) .")
        assert(#tokens == 3)
        expect_token(tokens[1], token_type.LPAREN, "(")
        expect_token(tokens[2], token_type.RPAREN, ")")
        expect_token(tokens[3], token_type.DOT, ".")
    end)

    it("should skip all whitespace: spaces, tabs, newlines", function()
        local code = "BEGIN\t\n \r x \t:=\n42 ; END."
        local tokens = tokenize(code)
        assert(#tokens == 7)
        expect_token(tokens[1], token_type.BEGIN, "BEGIN")
        expect_token(tokens[2], token_type.IDENTIFIER, "x")
        expect_token(tokens[3], token_type.ASSIGN, ":=")
        expect_token(tokens[4], token_type.NUMBER, 42)
        expect_token(tokens[5], token_type.SEMICOLON, ";")
        expect_token(tokens[6], token_type.END, "END")
    end)

    it("should preserve original case in identifiers", function()
        local tokens = tokenize("MyVar")
        assert(#tokens == 1)
        expect_token(tokens[1], token_type.IDENTIFIER, "MyVar") 
    end)


    it("should recognize keywords case-insensitively", function()
        local tokens = tokenize("begin END")
        assert(#tokens == 2)
        expect_token(tokens[1], token_type.BEGIN, "begin")
        expect_token(tokens[2], token_type.END, "END")
    end)



    it("should error on unexpected character: @", function()
        lexer.set_text("x @ y")
        lexer.next_token() -- x
        assert.has_error(function()
            lexer.next_token() -- @
        end, "Unexpected character '@' at line 1")
    end)

    it("should error on lone ':'", function()
        lexer.set_text("x : y")
        lexer.next_token() -- x
        assert.has_error(function()
            lexer.next_token() -- :
        end, "Unexpected ':' at line 1 (expected ':=')")
    end)


    it("should error when set_text is called with nil", function()
        assert.has_error(function()
            lexer.set_text(nil)
        end, "lexer.set_text(): expected a string")
    end)

    it("should error when set_text is called with non-string (e.g., number)", function()
        assert.has_error(function()
            lexer.set_text(123)
        end, "lexer.set_text(): expected a string")
    end)

    it("should return empty token list for empty input", function()
        assert.has_error(function()
            lexer.set_text("")
        end, "lexer.set_text(): expected a string")
    end)

    it("should handle single-character identifier", function()
        local tokens = tokenize("a")
        assert(#tokens == 1)
        expect_token(tokens[1], token_type.IDENTIFIER, "a")
    end)

    it("should handle single number", function()
        local tokens = tokenize("999")
        assert(#tokens == 1)
        expect_token(tokens[1], token_type.NUMBER, 999)
    end)

    it("should track line numbers correctly", function()
        lexer.set_text("x\ny") -- две строки
        local t1 = lexer.next_token() -- x
        local t2 = lexer.next_token() -- y
        assert.are.equals(1, t1.line)
        assert.are.equals(2, t2.line)
    end)

end)