local loader = {}

function loader.read_file(file_name)
    local file, err = io.open(file_name,"r")
    if not file then
        return nil, err
    end
    local content = file:read("*all")
    file:close()
    return content
end
return loader