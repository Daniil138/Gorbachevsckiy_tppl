local lexer = require("src.lexer")
local parser = require("src.parser")

local code = [[
BEGIN
  x := 5;
  y := x + 3 * 2
END.
]]

lexer.set_text(code)
parser.set_lexer(lexer)
local ast = parser.parse()
