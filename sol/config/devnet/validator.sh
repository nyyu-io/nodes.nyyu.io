#!/bin/bash

# Solana Devnet RPC Node Configuration
# This script starts a Solana RPC node (non-validating) for Devnet

set -e

echo "Starting Solana Devnet RPC Node..."

# Create necessary directories
mkdir -p /sol/ledger /sol/accounts /sol/snapshots

# Start Solana validator in RPC mode (non-validating)
exec solana-validator \
  --identity /sol/identity.json \
  --ledger /sol/ledger \
  --accounts /sol/accounts \
  --snapshots /sol/snapshots \
  --entrypoint entrypoint.devnet.solana.com:8001 \
  --entrypoint entrypoint2.devnet.solana.com:8001 \
  --entrypoint entrypoint3.devnet.solana.com:8001 \
  --entrypoint entrypoint4.devnet.solana.com:8001 \
  --entrypoint entrypoint5.devnet.solana.com:8001 \
  --known-validator dv1ZAGvdsz5hHLwWXsVnM94hWf1pjbKVau1QVkaMJ92 \
  --known-validator dv2eQHeP4RFrJZ6UeiZWoc3XTtmtZCUKxxCApCDcRNV \
  --known-validator dv4ACNkpYPcE3aKmYDqZm9G5EB3J4MRoeE7WNDRBVJB \
  --known-validator dv3qDFk1DTF36Z62bNvrCXe9sKATA6xvVy6A798xxAS \
  --expected-genesis-hash EtWTRABZaYq6iMfeYKouRu166VU2xqa1wcaWoxPkrZBG \
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
  --limit-ledger-size 50000000 \
  --block-production-method central-scheduler \
  --wal-recovery-mode skip_any_corrupted_record \
  --log -
