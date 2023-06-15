#!/bin/bash
if [[ -z $BINARY_LINK ]] || [{ -z $UPDATE_BLOCK_NUMBER ]] || [[ -z $BINARY ]]
then
echo "Error! Required variables not set! Check: BINARY_LINK, UPDATE_BLOCK_NUMBER, BINARY."
echo "Launch cancel!"
exit
fi
mkdir /root/update 
	if echo $BINARY_LINK | grep tar 
	then 
	  wget -O /root/update/$BINARY.tar.gz $BINARY_LINK && tar -xvf /root/update/$BINARY.tar.gz -C /root/update/ 
	elif echo $BINARY_LINK | grep zip 
	then 
	  ARCHIVE_NAME=`basename $BINARY_LINK`
	  wget -O /root/update/$ARCHIVE_NAME $BINARY_LINK && unzip /root/update/$ARCHIVE_NAME -d /root/update/
	else 
	  wget -O /root/update/$BINARY $BINARY_LINK
	fi
echo "New version $BINARY:"
/root/update/$BINARY version && sleep 5
UPDATE_PATH=/root/update
TEXT="$BINARY auto-update feature enabled on $UPDATE_BLOCK_NUMBER block!"
echo $TEXT
FOLDER=."$BINARY"
LATEST_BLOCK=`curl -s localhost:26657/block | jq -r .result.block.last_commit.height`
while true
do
BLOCK_COUNTER=$((UPDATE_BLOCK_NUMBER-LATEST_BLOCK))
TEXT="$BLOCK_COUNTER blocks left before update"
echo $TEXT
	if [[ $LATEST_BLOCK -ge $UPDATE_BLOCK_NUMBER ]]
	then
		sleep 10
		TEXT="Update Block Reached! Starting the update process!"
		echo $TEXT
		sv stop $BINARY
		chmod +x /root/update/$BINARY
		mv /usr/bin/$BINARY /tmp/$BINARY
		mv /root/update/$BINARY /usr/bin/$BINARY
		sv start $BINARY
		TEXT="Update completed! Check the signature in the block explorer https://explorer.declab.pro/ !"
		echo $TEXT
		exit
		
	fi

sleep 20
LATEST_BLOCK=`curl -s localhost:26657/block | jq -r .result.block.last_commit.height`
done
