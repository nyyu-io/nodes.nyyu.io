#!/bin/bash

# Solana Mainnet RPC Node Configuration
# This script starts a Solana RPC node (non-validating) for Mainnet-beta

set -e

echo "Starting Solana Mainnet RPC Node..."

# Create necessary directories
mkdir -p /sol/ledger /sol/accounts /sol/snapshots

# Start Solana validator in RPC mode (non-validating)
exec solana-validator \
  --identity /sol/identity.json \
  --ledger /sol/ledger \
  --accounts /sol/accounts \
  --snapshots /sol/snapshots \
  --entrypoint entrypoint.mainnet-beta.solana.com:8001 \
  --entrypoint entrypoint2.mainnet-beta.solana.com:8001 \
  --entrypoint entrypoint3.mainnet-beta.solana.com:8001 \
  --entrypoint entrypoint4.mainnet-beta.solana.com:8001 \
  --entrypoint entrypoint5.mainnet-beta.solana.com:8001 \
  --known-validator 7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2 \
  --known-validator GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ \
  --known-validator DE1bawNcRJB9rVm3buyMVfr8mBEoyyu73NBovf2oXJsJ \
  --known-validator CakcnaRDHka2gXyfbEd2d3xsvkJkqsLw2akB3zsN1D2S \
  --expected-genesis-hash 5eykt4UsFv8P8NJdTREpY1vzqKqZKvdpKuc147dw2N9d \
  --rpc-port 8899 \
  --rpc-bind-address 0.0.0.0 \
  --dynamic-port-range 8000-8020 \
  --gossip-port 8001 \
  --private-rpc \
  --only-known-rpc \
  --enable-rpc-transaction-history \
  --enable-cpi-and-log-storage \
  --rpc-pubsub-enable-block-subscription \
  --full-rpc-api \
  --no-voting \
  --limit-ledger-size 200000000 \
  --block-production-method central-scheduler \
  --wal-recovery-mode skip_any_corrupted_record \
  --log -
