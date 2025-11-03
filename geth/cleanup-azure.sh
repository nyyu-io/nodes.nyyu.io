#!/bin/bash

# Cleanup Geth installation on Azure
# This will stop and remove all containers and optionally volumes

set -e

# Configuration
AZURE_USER="azureuser"
AZURE_HOST="node-eth.nyyu.io"
SSH_KEY="./Azure-NYYU.pem"
REMOTE_DIR="/home/azureuser/geth-monitoring"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Azure Geth Cleanup Script            ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_header

echo -e "${YELLOW}WARNING: This will stop all Geth services on Azure${NC}"
echo ""
read -p "Do you want to remove blockchain data (volumes)? This will require re-syncing from scratch. (y/n) [n]: " REMOVE_VOLUMES
REMOVE_VOLUMES=${REMOVE_VOLUMES:-n}

echo ""
read -p "Proceed with cleanup? (y/n) [y]: " PROCEED
PROCEED=${PROCEED:-y}

if [[ ! "$PROCEED" =~ ^[Yy]$ ]]; then
    print_warning "Cleanup cancelled"
    exit 0
fi

print_info "Connecting to Azure server..."

if [[ "$REMOVE_VOLUMES" =~ ^[Yy]$ ]]; then
    print_warning "This will remove all blockchain data!"
    ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" << ENDSSH
set -e

if [ -d "$REMOTE_DIR" ]; then
    echo "Stopping and removing all services..."
    cd $REMOTE_DIR

    # Stop all services
    docker compose --profile ssl down -v || docker compose down -v || true

    # Remove all containers
    docker ps -aq --filter "name=geth-" | xargs -r docker rm -f || true

    # Remove all volumes
    docker volume ls -q --filter "name=geth-" | xargs -r docker volume rm || true

    echo "All services and data removed!"
else
    echo "Directory $REMOTE_DIR does not exist, nothing to clean"
fi
ENDSSH
    print_success "All services and blockchain data removed"
else
    print_info "Preserving blockchain data..."
    ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" << ENDSSH
set -e

if [ -d "$REMOTE_DIR" ]; then
    echo "Stopping all services..."
    cd $REMOTE_DIR

    # Stop all services but keep volumes
    docker compose --profile ssl down || docker compose down || true

    # Stop any remaining geth containers
    docker ps -aq --filter "name=geth-" | xargs -r docker stop || true

    echo "All services stopped, data preserved!"
else
    echo "Directory $REMOTE_DIR does not exist, nothing to clean"
fi
ENDSSH
    print_success "All services stopped, blockchain data preserved"
fi

echo ""
print_success "Cleanup complete!"
echo ""
echo -e "${BLUE}Next step: Run ./deploy-to-azure.sh to reinstall${NC}"
