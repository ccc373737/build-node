#!/bin/bash
sudo apt update;
sudo apt install snapd;
snap install bitcoin-core;

RPC_USER=$1
RPC_PASSWORD=$2
RPC_PORT=$3

mkdir /root/btc

sudo apt install -y screen

screen

bitcoin-core.daemon -txindex=1 -server=1 -datadir="/root/btc" -rpcworkqueue=64 -rpcuser=$RPC_USER -rpcpassword=$RPC_PASSWORD -rest -rpcbind=0.0.0.0:$RPC_PORT -rpcallowip=0.0.0.0/0