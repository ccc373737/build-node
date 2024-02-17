#!/bin/bash
psqlPw=$1

# install postgresql
sudo apt-get --purge -y remove postgresql
sudo apt update;
sudo apt install -y postgresql postgresql-contrib;
sudo systemctl start postgresql.service;

apt-mark hold postgresql postgresql-14 postgresql-client-14 postgresql-client-common postgresql-common postgresql-contrib;

sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '$psqlPw';"

# install node
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash - &&\
sudo apt-get install -y nodejs

# install cargo
curl https://sh.rustup.rs -sSf | sh -s -- -y
source "$HOME/.cargo/env";
rustup update stable;

# intall py
sudo apt install -y python3
sudo apt install -y python3-pip
python3 -m pip install python-dotenv;
python3 -m pip install psycopg2-binary;
python3 -m pip install json5;

sudo apt install postgresql-client-common;
sudo apt install postgresql-client-14;
sudo apt install pbzip2;
python3 -m pip install boto3;
python3 -m pip install tqdm;
python3 -m pip install stdiomask;
python3 -m pip install requests;

# install OPI
rm -rf OPI
sudo apt install -y git
git clone https://github.com/bestinslot-xyz/OPI.git;
cd OPI;
cd modules/main_index; npm install;
cd ../brc20_api; npm install;

sudo apt install -y build-essential;
cd ../../ord/
cargo build --release;

npm install pm2@latest -g;