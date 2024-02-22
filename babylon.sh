#!/bin/bash
nodeName=$1

sudo apt update -y;
sudo apt install -y snapd;

snap remove go
rm -rf go
snap install go --classic

# Clone project repository
rm -rf babylon
rm -rf .babylond
git clone https://github.com/babylonchain/babylon
cd babylon
git checkout v0.8.3

# Build binary
make install

export PATH=$PATH:/root/go/bin
echo "export PATH=\$PATH:/root/go/bin" >> ~/.bashrc
source ~/.bashrc

babylond init $nodeName --chain-id bbn-test-3

wget https://github.com/babylonchain/networks/raw/main/bbn-test-3/genesis.tar.bz2
tar -xjf genesis.tar.bz2 && rm genesis.tar.bz2
mv genesis.json ~/.babylond/config/genesis.json

sed -i -e 's|^minimum-gas-prices *=.*|minimum-gas-prices = "0.001ubbn"|' ~/.babylond/config/app.toml
sed -i -e 's|^network *=.*|network = "signet"|' ~/.babylond/config/app.toml

sed -i -e 's|^seeds *=.*|seeds = "49b4685f16670e784a0fe78f37cd37d56c7aff0e@3.14.89.82:26656,9cb1974618ddd541c9a4f4562b842b96ffaf1446@3.16.63.237:26656,ade4d8bc8cbe014af6ebdf3cb7b1e9ad36f412c0@testnet-seeds.polkachu.com:20656"|' ~/.babylond/config/config.toml

go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@latest
mkdir -p ~/.babylond
mkdir -p ~/.babylond/cosmovisor
mkdir -p ~/.babylond/cosmovisor/genesis
mkdir -p ~/.babylond/cosmovisor/genesis/bin
mkdir -p ~/.babylond/cosmovisor/upgrades

cp ~/go/bin/babylond ~/.babylond/cosmovisor/genesis/bin/babylond

sudo tee /etc/systemd/system/babylond.service > /dev/null <<EOF
[Unit]
Description=Babylon daemon
After=network-online.target

[Service]
User=$USER
ExecStart=$(which cosmovisor) run start --x-crisis-skip-assert-invariants
Restart=always
RestartSec=3
LimitNOFILE=infinity

Environment="DAEMON_NAME=babylond"
Environment="DAEMON_HOME=${HOME}/.babylond"
Environment="DAEMON_RESTART_AFTER_UPGRADE=true"
Environment="DAEMON_ALLOW_DOWNLOAD_BINARIES=false"

[Install]
WantedBy=multi-user.target
EOF

snap install jq
sudo -S systemctl daemon-reload
sudo -S systemctl enable babylond
sudo -S systemctl start babylond