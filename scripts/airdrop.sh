#!/bin/bash
MIN=$1
MAX=$2
WINNER=$3
BLOCK=$4
snap(){
# Получение данных и сохранение их в файл delegations.json
akash q staking delegations-to akashvaloper1ax4c40gn3s74xxm75g6cmts3fw7rq64gq0kaj4 --node https://akash.declab.pro:26601 --output json --limit 3000 --height $BLOCK > ./delegations.json

# Исходный файл
input_file="./delegations.json"

# Файлы для сохранения результатов
output_file="./filtered_delegations.json"
delegators_file="./delegator_addresses_on_$BLOCK.txt"

# Фильтрация данных и сохранение результатов
jq --argjson MIN "$MIN" --argjson MAX "$MAX" '
  .delegation_responses |= map(select(.balance.amount | tonumber <= $MAX and tonumber >= $MIN))
' "$input_file" > "$output_file"

# Извлечение адресов делегаторов и сохранение их в отдельный файл
jq --argjson MIN "$MIN" --argjson MAX "$MAX" -r '
  .delegation_responses[]
  | select(.balance.amount | tonumber <= $MAX and tonumber >= $MIN)
  | .delegation.delegator_address
' "$output_file" > "$delegators_file"

# Проверка содержимого файла с адресами
if [ ! -s "$delegators_file" ]; then
  echo "Файл $delegators_file пуст или не существует. Проверьте исходные данные и параметры фильтрации."
  exit 1
fi

# Вывод случайных  адресов из полученного списка
random_delegators=$(shuf -n $WINNER "$delegators_file")
echo ==========================
echo "Случайные $WINNER адресов делегаторов:"
echo "Random $WINNER delegator addresses:"
echo "$random_delegators"
echo ===========================
# Сохранение случайных адресов в отдельный файл (если необходимо)
random_delegators_file="./winner.txt"
echo "$random_delegators" > "$random_delegators_file"
echo "$WINNER адресов победителей сохранены в файл $random_delegators_file"
echo "$WINNER winners addresses saved to file $random_delegators_file"
echo ============================
echo "Результаты сохранены в файлы $output_file и $delegators_file."
echo "Results saved to $output_file and $delegators_file."
echo ============================
exit 0
}

TEXT="Победитель будет определен на блоке $BLOCK!"
ALT_TEXT="The winner will be determined on the $BLOCK block!"
echo $TEXT $ALT_TEXT
LATEST_BLOCK=`akash status | jq -r .SyncInfo.latest_block_height`
while true
do
BLOCK_COUNTER=$((BLOCK-LATEST_BLOCK))
TEXT="$BLOCK_COUNTER блоков до определения победителя!"
ALT_TEXT="$BLOCK_COUNTER blocks until the winner is determined!"
echo $TEXT $ALT_TEXT
	if [[ $LATEST_BLOCK -ge $BLOCK ]]
	then
		sleep 5
		snap
	fi

sleep 6
LATEST_BLOCK=`akash status | jq -r .SyncInfo.latest_block_height`
done
