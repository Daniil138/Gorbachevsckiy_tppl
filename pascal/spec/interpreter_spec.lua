local interpreter = require("src.interpreter")


describe("Pascal interpreter", function()

    it("should assign a constant value to a variable in a simple block", function()
        local result = interpreter.eval("BEGIN x := 42; END.")
        assert.equal(result.x, 42)
    end)

    it("should evaluate multiple assignments using previously defined variables", function()
        local result = interpreter.eval("BEGIN x := 42; y:=x+15 END.")
        assert.equal(result.x, 42)
        assert.equal(result.y, 57)
    end)

    it("should support arithmetic expressions with multiple operations and parentheses", function()
        local result = interpreter.eval("BEGIN x := 42; y:=x+15; z:=x*(y-55) END.")
        assert.equal(result.x, 42)
        assert.equal(result.y, 57)
        assert.equal(result.z, 84)
    end)

    it("should handle nested BEGIN...END blocks", function()
        local result = interpreter.eval("BEGIN BEGIN x := 42; END; y :=10 END.")
        assert.equal(result.x, 42)
        assert.equal(result.y, 10)
    end)

    it("should tolerate extra semicolons and perform division correctly", function()
        local result = interpreter.eval("BEGIN BEGIN x := 42;;; END; y := 10/2 END.")
        assert.equal(result.x, 42)
        assert.equal(result.y, 5)
    end)

    it("should raise an error when using an undefined variable", function()
        assert.has_error(function()
            interpreter.eval("BEGIN BEGIN x := 42;;; END; y := 10/2+z END.") -- @
        end, "Undefined variabl: z in line 1")
    end)
end)