# Интерпритатор языка Cow


## Cow Language Commands

| Command | Description |
|--------|-------------|
| `moo`  | Paired with `MOO`. When executed, searches the program **backward** for a matching `MOO` command (skipping the instruction immediately before `moo`) and resumes execution from that `MOO`. |
| `mOo`  | Move the memory pointer **one block backward**. |
| `moO`  | Move the memory pointer **one block forward**. |
| `mOO`  | Execute the instruction whose **opcode** equals the value in the current memory block (e.g., 1 = `moo`, 2 = `mOo`, 3 = `moO`, etc.). **Opcode 3 is invalid** (would cause infinite recursion). Any invalid opcode terminates the program. |
| `Moo`  | If the current memory block is **0**, read a single ASCII character from **stdin** and store its byte value. Otherwise, print the ASCII character corresponding to the current value to **stdout**. |
| `MOo`  | Decrement the value in the current memory block by 1. |
| `MoO`  | Increment the value in the current memory block by 1. |
| `MOO`  | If the current memory block is **0**, skip the **next instruction** and resume execution **after the matching `moo`**. If non-zero, continue to the next instruction. Note: because the instruction immediately after `MOO` is skipped during the jump, the matching `moo` may not be the nearest one (e.g., in `OOO MOO moo moo`, the `MOO` pairs with the **second** `moo`). |
| `OOO`  | Set the current memory block value to **0**. |
| `MMM`  | If the register is **empty**, copy the current memory value into it. If the register **contains a value**, paste it into the current memory block and **clear the register**. |
| `OOM`  | Print the integer value of the current memory block to **stdout**. |
| `oom`  | Read an integer from **stdin** and store it in the current memory block. |


## Клонируем репозиторий 

```bash
git clone https://github.com/Daniil138/Gorbachevsckiy_tppl.git
```
И переходим в папку cow

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
```

```bash
echo 'eval $(luarocks path --bin)' >> ~/.bashrc  # или ~/.zshrc
source ~/.bashrc
```

## Установка для Windows

1) Скачайте установщик:
http://luabinaries.sourceforge.net/ → выберите "Lua for Windows" (например, luaforwindows-v5.1.4-46.exe)
2) Откройте  и кстановите зависимости 


```bash
luarocks install --local busted
luarocks install --local luacov
```

## Запуск программ 

Для запуска программ нужно запустить команду

```bash
lua main.lua путь_к_файлу
```

## Просмотр coverege 

Для этого запускаем команду 
```bash
busted
```
Проверям что все тесты отработали

Запускаем coverege
```bash 
busted --coverage    
```
В директории появится файл luacov.stats.out в нем для каждого файла проекта описано сколько раз в время тестов выполнялась каждая строка. Запускаем файл coverege.py 
```bash
python coverege.py    
```
Он выведет все строки что не запускались во время тестов и тоговый процент покрытия для файла(пустые строки и end не учитываются ), однако из вывода файла можно понять что не тестировались программыв с вводом данных вручную и дргие единичные слова,например else

### Важно 
Для повторного просмотра coverege особенно если в программе что-то менялось файл  luacov.stats.out нужно удалить