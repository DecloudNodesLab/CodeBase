# Telegram @Dimokus
# Discord Dimokus#1032
# 2023
#!/bin/bash
# Часть 1 Установка ПО
TZ=Europe/Kiev && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
apt install -y nano tar wget lz4 zip jq runit build-essential git make gcc nvme-cli pv unzip
runsvdir -P /etc/service &
if [[ -z $GO_VERSION ]]; then GO_VERSION="1.20.1"; fi
wget https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz && tar -C /usr/local -xzf go$GO_VERSION.linux-amd64.tar.gz
if [[ -z $LIBWASMVM_VERSION ]]; then LIBWASMVM_VERSION="v1.2.3"; fi
wget -P /usr/lib/ https://github.com/CosmWasm/wasmvm/releases/download/$LIBWASMVM_VERSION/libwasmvm.x86_64.so
PATH=$PATH:/usr/local/go/bin && go version && echo 'export PATH='$PATH:/usr/local/go/bin >> /root/.bashrc
if [[ -n $SSH_PASS ]] ; then apt install -y ssh; echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && (echo ${SSH_PASS}; echo ${SSH_PASS}) | passwd root && service ssh restart; fi
if [[ -n $SSH_KEY ]] ; then apt install -y ssh && echo $SSH_KEY > /root/.ssh/authorized_keys; chmod 0600 /root/.ssh/authorized_keys && service ssh restart; fi
# Часть 2 Переменные
if [[ -n $RPC ]]
then
	if [[ -z $CHAIN ]] ; then CHAIN=`curl -s $RPC/status | jq -r .result.node_info.network`; fi
	if [[ -z $BINARY_VERSION ]] ; then BINARY_VERSION=`curl -s $RPC/abci_info | jq -r .result.response.version` ; fi
fi
echo 'export CHAIN='${CHAIN} >> /root/.bashrc
echo 'export MONIKER='${MONIKER} >> /root/.bashrc ; echo 'export BINARY_VERSION='${BINARY_VERSION} >> /root/.bashrc ; echo 'export CHAIN='${CHAIN} >> /root/.bashrc ; echo 'export RPC='${RPC} >> /root/.bashrc ; echo 'export GENESIS='${GENESIS} >> /root/.bashrc
# Часть 3 Компиляция
if [[ -n $BINARY_LINK ]]
then
	if echo $BINARY_LINK | grep tar 
	then 
	  wget -O /tmp/$BINARY.tar.gz $BINARY_LINK && tar -xvf /tmp/$BINARY.tar.gz -C /usr/bin/ 
	elif echo $BINARY_LINK | grep zip 
	then 
	  ARCHIVE_NAME=`basename $BINARY_LINK | sed "s/.zip//"`
	  wget -O /tmp/$BINARY.zip $BINARY_LINK && unzip /tmp/$BINARY.zip && mv ./$ARCHIVE_NAME /usr/bin/$BINARY
	else 
	  wget -O /usr/bin/$BINARY $BINARY_LINK
	fi
else
	GIT_FOLDER=`basename $GITHUB_REPOSITORY | sed "s/.git//"` && git clone $GITHUB_REPOSITORY && cd $GIT_FOLDER && git checkout $BINARY_VERSION 
	make build
	make install
	BINARY=`ls /root/go/bin`
	if [[ -z $BINARY ]] ; then BINARY=`ls /root/$GIT_FOLDER/build/` && cp /root/$GIT_FOLDER/build/$BINARY /usr/bin/$BINARY ; else cp /root/go/bin/$BINARY /usr/bin/$BINARY ; fi
fi
sleep 1
chmod +x /usr/bin/$BINARY && echo $BINARY && echo 'export BINARY='${BINARY} >> /root/.bashrc && $BINARY version
# Часть 4 Конфигурирование
$BINARY init "$MONIKER" --chain-id $CHAIN  && sleep 1

if [[ -z $FOLDER ]] ; then FOLDER=.`echo $BINARY | sed "s/d$//"` ; fi
echo 'export FOLDER='${FOLDER} >> /root/.bashrc
if [[ -n ${RPC} ]] && [[ -z ${GENESIS} ]]
then 
	rm /root/$FOLDER/config/genesis.json &&	curl -s $RPC/genesis | jq .result.genesis >> /root/$FOLDER/config/genesis.json
	if [[ -z $DENOM ]] ; then DENOM=`curl -s $RPC/genesis | grep denom -m 1 | tr -d \"\, | sed "s/denom://" | tr -d \ `;	fi
fi
echo 'export DENOM='${DENOM} >> /root/.bashrc
if [[ -n $GENESIS ]]
then	
	if echo $GENESIS | grep tar
	then
		rm /root/$FOLDER/config/genesis.json && mkdir /tmp/genesis/
		wget -O /tmp/genesis.tar.gz $GENESIS && tar -C /tmp/genesis/ -xf /tmp/genesis.tar.gz
		rm /tmp/genesis.tar.gz && mv /tmp/genesis/`ls /tmp/genesis/` /root/$FOLDER/config/genesis.json		
		if [[ -z $DENOM ]] ; then DENOM=`curl -s $RPC/genesis | grep denom -m 1 | tr -d \"\, | sed "s/denom://" | tr -d \ ` && echo 'export DENOM='${DENOM} >> /root/.bashrc ; fi
	else
		rm /root/$FOLDER/config/genesis.json && wget -O /root/$FOLDER/config/genesis.json $GENESIS
		if [[ -z $DENOM ]] ; then DENOM=`curl -s $RPC/genesis | grep denom -m 1 | tr -d \"\, | sed "s/denom://" | tr -d \ ` && echo 'export DENOM='${DENOM} >> /root/.bashrc ; fi
	fi
fi
echo 'export DENOM='${DENOM} >> /root/.bashrc
echo $DENOM && sleep 1
echo $PEERS && echo $SEEDS
sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0.0025$DENOM\"/;" /root/$FOLDER/config/app.toml
sed -i.bak -e "s/^seeds *=.*/seeds = \"$SEEDS\"/;" /root/$FOLDER/config/config.toml
sed -i.bak -e "s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|;" /root/$FOLDER/config/config.toml
if [[ -z $KEEP_RECENT ]] || [[ -z $INTERVAL ]] ; then KEEP_RECENT=1000 && INTERVAL=10 ; fi
if [[ -z $PRUNING ]]
then
  sed -i -e "s/^pruning *=.*/pruning = \"custom\"/" /root/$FOLDER/config/app.toml && \
  sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$KEEP_RECENT\"/" /root/$FOLDER/config/app.toml && \
  sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$INTERVAL\"/" /root/$FOLDER/config/app.toml
else
  sed -i -e "s/^pruning *=.*/pruning = \"$PRUNING\"/" /root/$FOLDER/config/app.toml && \
  sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$KEEP_RECENT\"/" /root/$FOLDER/config/app.toml && \
  sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$INTERVAL\"/" /root/$FOLDER/config/app.toml
fi
if [[ -z $INDEXER ]] ; then INDEXER=kv ; fi
sed -i -e "s/^indexer *=.*/indexer = \"$INDEXER\"/" /root/$FOLDER/config/config.toml
if [[ -z $SNAPSHOT_INTERVAL ]] ; then SNAPSHOT_INTERVAL="2000" ; fi
sed -i.bak -e "s/^snapshot-interval *=.*/snapshot-interval = \"$SNAPSHOT_INTERVAL\"/" /root/$FOLDER/config/app.toml
sed -i 's/^\[api\]\s*enable\s*=.*/[api]\nenable = true/' /root/$FOLDER/config/app.toml
# ====================RPC======================
#================================================
# Часть 5 Запуск
echo =Run node...= 
mkdir -p /root/$BINARY/log    
cat > /root/$BINARY/run <<EOF 
#!/bin/bash
exec 2>&1
exec $BINARY start
EOF
mkdir /tmp/log/
cat > /root/$BINARY/log/run <<EOF 
#!/bin/bash
exec svlogd -tt /tmp/log/
EOF
chmod +x /root/$BINARY/log/run /root/$BINARY/run 
ln -s /root/$BINARY /etc/service && ln -s /tmp/log/current /LOG
sleep 20
while true ; do tail -100 /LOG | grep -iv peer && sleep 20 ; done
