#!/bin/bash
install_babylon_env() {
    read -e -p "node_name: " node_name

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

    babylond init '$node_name' --chain-id bbn-test-3

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

    sudo -S systemctl daemon-reload
    sudo -S systemctl enable babylond
    sudo -S systemctl start babylond
}

start_validator_node() {
    read -e -p "validator_name: " validator_name

    read -e -p "amount (e.g., 1000000): " amount

    babylond create-bls-key $(babylond keys show wallet -a)
    sed -i -e "s|^timeout_commit *=.*|timeout_commit = \"30s\"|" ~/.babylond/config/config.toml

    PUBKEY=$(babylond tendermint show-validator)

    cat << EOF > validator.json
{
  "pubkey": $PUBKEY,
  "amount": "${amount}ubbn",
  "moniker": "$validator_name",
  "commission-rate": "0.10",
  "commission-max-rate": "0.20",
  "commission-max-change-rate": "0.01",
  "min-self-delegation": "1"
}
EOF

    babylond tx checkpointing create-validator validator.json \
    --chain-id="bbn-test-3" \
    --gas="100000" \
    --gas-adjustment="1.5" \
    --gas-prices="0.025ubbn" \
    --from=wallet
}


echo && echo -e "babylon
 ———————————————————————
 1.install_babylon_env
 2.start_validator_node
 ———————————————————————" && echo
read -e -p " number :" num
case "$num" in
1)
    install_babylon_env
    ;;
2)
    start_validator_node
    ;;

*)
    echo
    echo -e " ${Error}"
    ;;
esac