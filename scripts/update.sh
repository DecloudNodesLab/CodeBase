#!/bin/bash
if [[ -z $BINARY_LINK ]] || [{ -z $UPDATE_BLOCK_NUMBER ]] || [[ -z $SERVICE ]]
then
echo "Ошибка! Не заданы необходимые переменные! Проверьте BINARY_LINK, UPDATE_BLOCK_NUMBER, SERVICE."
echo "Отмена запуска!"
exit
fi
mkdir /root/update
wget -O /root/update/$SERVICE $BINARY_LINK && chmod +x /root/update/$SERVICE
UPDATE_PATH=/root/update
TEXT="$SERVICE auto-update feature enabled on $UPDATE_BLOCK_NUMBER block!"
echo $TEXT
FOLDER=."$SERVICE"
LATEST_BLOCK=`curl -s localhost:26657/block | jq -r .result.block.last_commit.height`
while true
do
BLOCK_COUNTER=$((UPDATE_BLOCK_NUMBER-LATEST_BLOCK))
TEXT="До обновления осталось $BLOCK_COUNTER блоков"
echo $TEXT
	if [[ $LATEST_BLOCK -ge $UPDATE_BLOCK_NUMBER ]]
	then
		sleep 10
		TEXT="Update Block Reached! Starting the update process!"
		echo $TEXT
		sv stop $SERVICE
		chmod +x /root/update/$SERVICE
		mv /usr/bin/$SERVICE /tmp/$SERVICE
		mv /root/update/$SERVICE /usr/bin/$SERVICE
		sed -i.bak -e "s/^double_sign_check_height *=.*/double_sign_check_height = 0/;" /root/$FOLDER/config/config.toml
		sv start $SERVICE
		TEXT="Update completed! Check the signature in the block explorer https://explorer.declab.pro/ !"
		echo $TEXT
		exit
		
	fi

sleep 20
LATEST_BLOCK=`curl -s localhost:26657/block | jq -r .result.block.last_commit.height`
done
