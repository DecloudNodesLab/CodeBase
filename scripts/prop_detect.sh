#!/bin/bash
source ~/.bashrc
sleep 2m
RPC=localhost:26657
CATCHING_UP=`$BINARY status | jq -r .SyncInfo.catching_up`
echo $CATCHING_UP
while [[ $CATCHING_UP == true  ]]
do
sleep 1m
CATCHING_UP=`$BINARY status | jq -r .SyncInfo.catching_up`
echo $CATCHING_UP
done
BL=`curl -s $RPC/block?latest | jq -r .result.block.header.height`
let BL=$BL-50
while true
do
echo $BL
curl -s $RPC/block?height=$BL | jq -r .result.block.data.txs[] | base64 -d > /tmp/txs.txt
if [[ `curl -s $RPC/block?height=$BL | jq -r .result.block.header.last_block_id.hash` == null ]]
then
echo Block not create! Sleep 10 min...
sleep 10m
continue
elif grep -a Proposal /tmp/txs.txt || grep -a proposal /tmp/txs.txt
then
curl -s -H "Content-Type: application/json" -X POST -d '{"content":" ':bangbang:' **'$BINARY'** Alert @everyone !\n':bangbang:'Внимание! Обнаружено новое голосование! \n':bangbang:'**Проверьте сеть!**"}' "$WEBHOOKS"
let BL=$BL+1
else
let BL=$BL+1
fi
done
