#!/usr/bin/python

import re

def obfuscator(o_cmd: str) -> str:
    if ' ' not in o_cmd:
        tmp = "\$\\'" + ''.join(f"\\\\$(($((1<<1))#{int(f'{ord(i):o}'):b}))" for i in o_cmd) + "\\'"

    else:
        tmp = "{\$\\'" + ''.join(f"\\\\$(($((1<<1))#{int(f'{ord(i):o}'):b}))" if i != ' ' else r"\',\$\'" for i in o_cmd) + "\\'}"

    data = f"${{!##\-}}<<<{tmp}"

    print(f"\nOutput v1 : {data}\n")
    print(f"Output v2 : {data.replace('1','${##}').replace('0','${#}')}\n")

def deobfuscator(deo_cmd: str) -> str:
    if '${##}' in deo_cmd or '${#}' in deo_cmd:
        deo_cmd = deo_cmd.replace('${##}','1').replace('${#}','0').replace(' ','')

    findBin = re.findall(r"\b[01]+.\b|\\',\\\$\\'", deo_cmd)
    data = ''.join(chr(int(str(int(i,2)),8)) if r"\',\$\'" not in i else ' ' for i in findBin)

    print("\nDeobfuscator :", repr(data))


menu = {
        1:obfuscator,
        2:deobfuscator
    
    }.get(int(input("""Menu :
    1. Obfuscator
    2. Deobfuscator
: """)))
cmd = menu(input("Cmd : "))
