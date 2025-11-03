#!/bin/bash

# BSC Node Manager Script
# Provides easy commands for managing BSC monitoring nodes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   BSC Monitoring Node Manager         ║${NC}"
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

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

# Start all services
start_all() {
    print_header
    print_info "Starting all BSC monitoring services..."
    docker compose up -d
    print_success "All services started!"
    echo ""
    print_info "Access points:"
    echo "  • BSC Mainnet RPC:  http://localhost:8575"
    echo "  • BSC Mainnet WS:   ws://localhost:8576"
    echo "  • BSC Testnet RPC:  http://localhost:8577"
    echo "  • BSC Testnet WS:   ws://localhost:8578"
    echo "  • Grafana:          http://localhost:3002 (admin/admin)"
    echo "  • Prometheus:       http://localhost:9092"
}

# Start only BSC nodes
start_nodes() {
    print_header
    print_info "Starting BSC nodes only (no monitoring)..."
    docker compose up -d bsc-mainnet bsc-testnet
    print_success "BSC nodes started!"
}

# Stop all services
stop_all() {
    print_header
    print_info "Stopping all services..."
    docker compose down
    print_success "All services stopped!"
}

# Check sync status
check_sync() {
    print_header

    echo -e "${BLUE}BSC Mainnet Sync Status:${NC}"
    curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        http://localhost:8575 | jq -r '.result' || print_warning "BSC Mainnet node not running"
    echo ""

    echo -e "${BLUE}BSC Testnet Sync Status:${NC}"
    curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        http://localhost:8577 | jq -r '.result' || print_warning "BSC Testnet node not running"
    echo ""

    print_info "Note: 'false' means fully synced"
}

# Check peer count
check_peers() {
    print_header

    echo -e "${BLUE}BSC Mainnet Peers:${NC}"
    MAINNET_PEERS=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        http://localhost:8575 | jq -r '.result' | xargs printf "%d\n" 2>/dev/null || echo "0")
    echo "  Connected peers: $MAINNET_PEERS"
    echo ""

    echo -e "${BLUE}BSC Testnet Peers:${NC}"
    TESTNET_PEERS=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        http://localhost:8577 | jq -r '.result' | xargs printf "%d\n" 2>/dev/null || echo "0")
    echo "  Connected peers: $TESTNET_PEERS"
    echo ""

    if [ "$MAINNET_PEERS" -lt 5 ] || [ "$TESTNET_PEERS" -lt 5 ]; then
        print_warning "Low peer count detected. Consider checking your network/firewall."
    fi
}

# Check block height
check_blocks() {
    print_header

    echo -e "${BLUE}BSC Mainnet Block Height:${NC}"
    MAINNET_BLOCK=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8575 | jq -r '.result' | xargs printf "%d\n" 2>/dev/null || echo "0")
    echo "  Block: $MAINNET_BLOCK"
    echo ""

    echo -e "${BLUE}BSC Testnet Block Height:${NC}"
    TESTNET_BLOCK=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8577 | jq -r '.result' | xargs printf "%d\n" 2>/dev/null || echo "0")
    echo "  Block: $TESTNET_BLOCK"
}

# View logs
view_logs() {
    print_header

    if [ "$1" == "mainnet" ]; then
        print_info "Showing BSC Mainnet logs (Ctrl+C to exit)..."
        docker logs -f bsc-mainnet-monitor
    elif [ "$1" == "testnet" ]; then
        print_info "Showing BSC Testnet logs (Ctrl+C to exit)..."
        docker logs -f bsc-testnet-monitor
    else
        print_error "Please specify 'mainnet' or 'testnet'"
        echo "Usage: $0 logs [mainnet|testnet]"
    fi
}

# Resource usage
check_resources() {
    print_header
    print_info "Resource Usage:"
    docker stats --no-stream bsc-mainnet-monitor bsc-testnet-monitor 2>/dev/null || print_warning "Nodes not running"
}

# BSC console
attach_console() {
    print_header

    if [ "$1" == "mainnet" ]; then
        print_info "Attaching to BSC Mainnet console (type 'exit' to quit)..."
        docker exec -it bsc-mainnet-monitor geth attach http://localhost:8545
    elif [ "$1" == "testnet" ]; then
        print_info "Attaching to BSC Testnet console (type 'exit' to quit)..."
        docker exec -it bsc-testnet-monitor geth attach http://localhost:8545
    else
        print_error "Please specify 'mainnet' or 'testnet'"
        echo "Usage: $0 console [mainnet|testnet]"
    fi
}

# Test RPC
test_rpc() {
    print_header

    echo -e "${BLUE}Testing BSC Mainnet RPC:${NC}"
    curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8575 | jq || print_error "BSC Mainnet RPC not responding"
    echo ""

    echo -e "${BLUE}Testing BSC Testnet RPC:${NC}"
    curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8577 | jq || print_error "BSC Testnet RPC not responding"
}

# Full status
status() {
    print_header

    print_info "Service Status:"
    docker compose ps
    echo ""

    check_peers
    check_blocks
}

# Show help
show_help() {
    print_header
    echo "Usage: $0 [command]"
    echo ""
    echo "Available commands:"
    echo "  start           - Start all services (BSC nodes + monitoring)"
    echo "  start-nodes     - Start only BSC nodes (no monitoring)"
    echo "  stop            - Stop all services"
    echo "  status          - Show status of all services"
    echo "  sync            - Check sync status"
    echo "  peers           - Check peer count"
    echo "  blocks          - Check block height"
    echo "  logs [network]  - View logs (mainnet|testnet)"
    echo "  resources       - Show resource usage"
    echo "  console [net]   - Attach to BSC console (mainnet|testnet)"
    echo "  test-rpc        - Test RPC endpoints"
    echo "  help            - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 sync"
    echo "  $0 logs mainnet"
    echo "  $0 console testnet"
}

# Main script
check_docker

case "$1" in
    start)
        start_all
        ;;
    start-nodes)
        start_nodes
        ;;
    stop)
        stop_all
        ;;
    status)
        status
        ;;
    sync)
        check_sync
        ;;
    peers)
        check_peers
        ;;
    blocks)
        check_blocks
        ;;
    logs)
        view_logs "$2"
        ;;
    resources)
        check_resources
        ;;
    console)
        attach_console "$2"
        ;;
    test-rpc)
        test_rpc
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
