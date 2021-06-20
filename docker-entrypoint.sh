#!/usr/bin/env sh
set -ex

if [ -z "$WALLET"]; then
	echo "No wallet specified"
	exit 1
fi

# Network switch
if [ "$TESTNET" = true ] || [ "$ELECTRUM_NETWORK" = "testnet" ]; then
  FLAGS='--testnet'
elif [ "$ELECTRUM_NETWORK" = "regtest" ]; then
  FLAGS='--regtest'
elif [ "$ELECTRUM_NETWORK" = "simnet" ]; then
  FLAGS='--simnet'
fi

# Graceful shutdown
trap 'pkill -TERM -P1; electrum daemon stop; exit 0' SIGTERM

# Set config
electrum $FLAGS setconfig --offline rpcuser ${ELECTRUM_USER}
electrum $FLAGS setconfig --offline rpcpassword ${ELECTRUM_PASSWORD}
electrum $FLAGS setconfig --offline rpchost 0.0.0.0
electrum $FLAGS setconfig --offline rpcport 7000

if [ -z "$GOSSIP"]; then
  GOSSIP=false
fi

electrum $FLAGS setconfig --offline use_gossip $GOSSIP

# XXX: Check load wallet or create

# Run application
electrum $FLAGS --wallet $WALLET daemon &
ELECTRUM_PID=$!

TRIES_LEFT=10
IS_UP=0

while [ ! $TRIES_LEFT -eq 0 -a $IS_UP -eq 0 ]; do
  sleep 1
  echo "Checking if electrum is up yet..."
  electrum $FLAGS getinfo >> /dev/null && IS_UP=1 || true
  TRIES_LEFT=`expr $TRIES_LEFT - 1`
done

if [ ! $IS_UP -eq 1 ]; then
  echo "Electrum did not start"
  exit 1
fi

if [ ! -f $WALLET ]; then
  echo "Wallet file does not exist, creating"
  electrum $FLAGS create
fi

electrum $FLAGS load_wallet

echo "Waiting for electrum to finish"
wait $ELECTRUM_PID
echo "Electrum finished"
