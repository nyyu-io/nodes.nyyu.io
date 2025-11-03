#!/bin/bash

# Solana Cleanup Script for Azure

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

AZURE_HOST="node-sol.nyyu.io"
AZURE_USER="azureuser"
SSH_KEY="./rcp_eth.pem"
REMOTE_DIR="/home/azureuser/sol-monitoring"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Solana Azure Cleanup Script          ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}WARNING: This will stop all Solana monitoring services!${NC}"
echo ""
read -p "Do you want to also remove all blockchain data? (y/N) [N]: " REMOVE_DATA
REMOVE_DATA=${REMOVE_DATA:-n}

if [[ "$REMOVE_DATA" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⚠ This will DELETE all blockchain data (~200GB for mainnet). This cannot be undone!${NC}"
    echo "Re-syncing will take 2-6 hours (with snapshot download)."
    echo ""
    read -p "Are you sure? Type 'yes' to confirm: " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Cleanup cancelled"
        exit 0
    fi
fi

if [[ "$REMOVE_DATA" =~ ^[Yy]$ ]]; then
    ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" "cd $REMOTE_DIR && docker compose down -v"
    echo -e "${GREEN}✓ All services stopped and data removed${NC}"
else
    ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" "cd $REMOTE_DIR && docker compose down"
    echo -e "${GREEN}✓ All services stopped (data preserved)${NC}"
fi

echo ""
echo -e "${GREEN}✓ Cleanup complete!${NC}"
