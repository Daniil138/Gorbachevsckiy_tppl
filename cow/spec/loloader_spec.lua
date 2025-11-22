local loader = require("src.loader")

describe("Read_file", function()
    it("корректно считает файл", function()
        local result =  loader.read_file("files/test.txt")
        assert.equals("Hello, world!",  result)
    end)

    it("вернет нул и ошбку если файла нет", function()
        local content, err = loader.read_file("files/nonexistent.txt")
        assert.is_nil(content)
        assert.is_not_nil(err)
        assert.is_true(type(err) == "string")
    end)

end)