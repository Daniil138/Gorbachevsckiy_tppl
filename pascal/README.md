
## Клонируем репозиторий 

```bash
git clone https://github.com/Daniil138/Gorbachevsckiy_tppl.git
```
И переходим в папку pascal

```bash
cd cow
```


## Установка для Linux Ubuntu

```bash
sudo apt update
sudo apt install lua5.4  luarocks 
```

```bash
luarocks install --local busted
luarocks install --local luacov
luarocks install --local luacov-html
```

## Для проверки тестов 

```bash
busted --coverage
luacov
```
После этих двух команд в папке появить файл luacov.report.html в котором будет coverege

## Для запуска своего файла или приложеных файлов можно воспользоваться командой

```bash
lua main.lua test_prog/test1.pas
```

## Или можно воспользоваться примером для использования в коде

```lua
local interpreter = require("src.interpreter")

local code = [[
BEGIN
    x := 10
END.
]]

local result = interpreter.eval(code)

```
Тким образов в переменной result окажется таблица с переменными которые вы задали