#!/usr/bin/bash

set -euo pipefail
# -e == Immediately exit if any command [1] has a non-zero exit status.
# -u == Prevents "silent errors" / unidentifiable errors, outputting the exact error cause.
# -o pipefail == Prevents errors in a pipeline from being masked.
#gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca

echo -e "\n- Conversor\n  \x1b[32mUnicode UCS-4 Little Endian\x1b[0m --> \x1b[33mBytes\x1b[0m --> \x1b[34mBinário\x1b[0m (obase2)\n  GH: rodricbr\n"

STRINGS_="$@"

echo "$STRINGS_" > a.tmp

PRINCIPAL_(){
  # Unicode passado pelo usuário (Formato UCS-4 Little Endian) PARA Bytes (od faz a conversão), e retira os últimos 3 valores
  DECIMAL_=$(fold -w3 <<< $(cat a.tmp | od -t o1 -A n | sed 's/.\{3\}$//;s/ //g'))

  # Para coverter o $DECIMAL_ (decimal) em binário
  ARREI=($(bc <<< "obase=2;$DECIMAL_" | grep -P "\d" | tail -n 5 | sed 's/:.*//')); ARREI=("${ARREI[@]%%:*}"); echo -n "\${!##-}<<<\$\'"; for i in "${ARREI[@]}"; { echo -n "\\\\\$((\$((1<<1))#$i))";}; echo "\'"

  # Reverter o comando passado pelo usuário:
  while IFS= read -r a; do
    echo $a
  done < <(echo "$(<a.tmp)")
}

if [[ "$STRINGS_" =~ \ |\' ]]; then
  # Tem espaço no argumento do usuário
  echo -e "Contém espaço.\n"
  PRINCIPAL_ | sed 's/\\$(($((1<<1))#101000))/\x27,\\$\\\x27/g; s/$/}/g' | sed -re 's/^.{10}/&{/g'
else
  # Não tem espaço no argumento do usuário
  echo -e "Não contém espaço.\n"
  PRINCIPAL_
fi

unset DECIMAL_ ARREI STRINGS_
rm a.tmp

# Todo:
# 1- Fazer um if se o comando tiver espaço, tiver ele faz o "{comando1,comando2}"

# 2- Dar replace no espaço que o usuário deu dentro do if por: \',\$\'
#    Ou dar replace no: \\$(($((1<<1))#101000)) pelo: \',\$\'
# Ficando assim: ${!##-}<<<{$\'\\$(($((1<<1))#10011010))\\$(($((1<<1))#10100011))\',\$\'\\$(($((1<<1))#110111))\\$(($((1<<1))#10011010))\'}

# Ideia:
#echo "\${!##-}<<<\$\'\\\$((\$((1<<1))#10011010))\\\$((\$((1<<1))#10100011))\\\$((\$((1<<1))#101000))\\\$((\$((1<<1))#110111))\\\$((\$((1<<1))#10011010))\'" | sed 's/$(($((1<<1))#101000))/,/g'
