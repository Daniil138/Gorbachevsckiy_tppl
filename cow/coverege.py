empty_lines = 0
zero_count = 0
len_l=0
with open("src/interpreter.lua", 'r', encoding='utf-8') as f:


    with open("luacov.stats.out", 'r', encoding='utf-8') as fl:
        lines = fl.readlines()
        
        cov = lines[-3].split()
        count_line=0
        zero_count = cov.count('0')
        line_file = f.readlines()
        len_l=len(line_file)
        for line in line_file:
            if cov[count_line]== '0':
                print(line)
            if line.strip() == '' or line.strip()=="end":
                empty_lines += 1
            count_line+=1
   
print("coverege:", 100 - 100 * ((zero_count-empty_lines)/len_l))

