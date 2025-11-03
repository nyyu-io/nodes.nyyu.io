#!/bin/bash

# BSC Cleanup Script for Azure
# Safely stop and optionally remove all BSC services and data

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   BSC Azure Cleanup Script            ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Default configuration
AZURE_HOST="node-bsc.nyyu.io"
AZURE_USER="azureuser"
SSH_KEY="./Azure-NYYU.pem"
REMOTE_DIR="/home/azureuser/bsc-monitoring"

print_header

echo -e "${YELLOW}WARNING: This will stop all BSC monitoring services!${NC}"
echo ""
read -p "Do you want to also remove all data? (y/N) [N]: " REMOVE_DATA
REMOVE_DATA=${REMOVE_DATA:-n}

if [[ "$REMOVE_DATA" =~ ^[Yy]$ ]]; then
    print_warning "This will DELETE all blockchain data. This cannot be undone!"
    read -p "Are you sure? Type 'yes' to confirm: " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Cleanup cancelled"
        exit 0
    fi
fi


if [[ "$REMOVE_DATA" =~ ^[Yy]$ ]]; then
    # Stop and remove everything including volumes
    ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" << ENDSSH
cd $REMOTE_DIR
echo "Stopping all services..."
docker compose down -v
echo "Services stopped and data volumes removed"
ENDSSH
    print_success "All services stopped and data removed"
else
    # Just stop services, keep data
    ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" << ENDSSH
cd $REMOTE_DIR
echo "Stopping all services..."
docker compose down
echo "Services stopped (data preserved)"
ENDSSH
    print_success "All services stopped (data preserved)"
fi

echo ""
print_success "Cleanup complete!"

if [[ ! "$REMOVE_DATA" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${BLUE}Data volumes preserved. To restart services:${NC}"
    echo "  ssh -i $SSH_KEY $AZURE_USER@$AZURE_HOST 'cd $REMOTE_DIR && docker compose up -d'"
fi
