#!/bin/bash

# Bitcoin Node Manager Script
# Provides easy commands for managing Bitcoin monitoring nodes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# RPC Credentials (should match bitcoin.conf)
RPC_USER="${BTC_RPC_USER:-rpcuser}"
RPC_PASSWORD="${BTC_RPC_PASSWORD:-rpcpassword}"

# Functions
print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Bitcoin Monitoring Node Manager     ║${NC}"
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

# Bitcoin RPC call helper
btc_rpc_call() {
    local node=$1
    local method=$2
    shift 2
    local params=$@

    local port=8332
    if [ "$node" == "testnet" ]; then
        port=18332
    fi

    curl -s --user "$RPC_USER:$RPC_PASSWORD" \
        --data-binary "{\"jsonrpc\":\"1.0\",\"id\":\"1\",\"method\":\"$method\",\"params\":[$params]}" \
        -H 'content-type: text/plain;' \
        "http://localhost:$port" | jq -r '.result'
}

# Start all services
start_all() {
    print_header
    print_info "Starting all Bitcoin monitoring services..."
    docker compose up -d
    print_success "All services started!"
    echo ""
    print_info "Access points:"
    echo "  • Bitcoin Mainnet RPC:  http://localhost:8332"
    echo "  • Bitcoin Testnet RPC:  http://localhost:18332"
    echo "  • Grafana:              http://localhost:3003 (admin/admin)"
    echo "  • Prometheus:           http://localhost:9093"
}

# Start only Bitcoin nodes
start_nodes() {
    print_header
    print_info "Starting Bitcoin nodes only (no monitoring)..."
    docker compose up -d btc-mainnet btc-testnet
    print_success "Bitcoin nodes started!"
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

    echo -e "${BLUE}Bitcoin Mainnet Sync Status:${NC}"
    if docker ps --format '{{.Names}}' | grep -q btc-mainnet-monitor; then
        MAINNET_INFO=$(btc_rpc_call mainnet getblockchaininfo)
        BLOCKS=$(echo "$MAINNET_INFO" | jq -r '.blocks')
        HEADERS=$(echo "$MAINNET_INFO" | jq -r '.headers')
        VERIFICATION=$(echo "$MAINNET_INFO" | jq -r '.verificationprogress * 100' | cut -d. -f1)

        echo "  Blocks: $BLOCKS / $HEADERS"
        echo "  Progress: $VERIFICATION%"

        if [ "$BLOCKS" == "$HEADERS" ]; then
            print_success "Fully synced!"
        else
            print_warning "Syncing in progress..."
        fi
    else
        print_warning "Mainnet node not running"
    fi
    echo ""

    echo -e "${BLUE}Bitcoin Testnet Sync Status:${NC}"
    if docker ps --format '{{.Names}}' | grep -q btc-testnet-monitor; then
        TESTNET_INFO=$(btc_rpc_call testnet getblockchaininfo)
        BLOCKS=$(echo "$TESTNET_INFO" | jq -r '.blocks')
        HEADERS=$(echo "$TESTNET_INFO" | jq -r '.headers')
        VERIFICATION=$(echo "$TESTNET_INFO" | jq -r '.verificationprogress * 100' | cut -d. -f1)

        echo "  Blocks: $BLOCKS / $HEADERS"
        echo "  Progress: $VERIFICATION%"

        if [ "$BLOCKS" == "$HEADERS" ]; then
            print_success "Fully synced!"
        else
            print_warning "Syncing in progress..."
        fi
    else
        print_warning "Testnet node not running"
    fi
    echo ""
}

# Check peer count
check_peers() {
    print_header

    echo -e "${BLUE}Bitcoin Mainnet Peers:${NC}"
    if docker ps --format '{{.Names}}' | grep -q btc-mainnet-monitor; then
        MAINNET_PEERS=$(btc_rpc_call mainnet getconnectioncount)
        echo "  Connected peers: $MAINNET_PEERS"

        if [ "$MAINNET_PEERS" -lt 8 ]; then
            print_warning "Low peer count detected"
        fi
    else
        print_warning "Mainnet node not running"
    fi
    echo ""

    echo -e "${BLUE}Bitcoin Testnet Peers:${NC}"
    if docker ps --format '{{.Names}}' | grep -q btc-testnet-monitor; then
        TESTNET_PEERS=$(btc_rpc_call testnet getconnectioncount)
        echo "  Connected peers: $TESTNET_PEERS"

        if [ "$TESTNET_PEERS" -lt 5 ]; then
            print_warning "Low peer count detected"
        fi
    else
        print_warning "Testnet node not running"
    fi
    echo ""
}

# Check block height
check_blocks() {
    print_header

    echo -e "${BLUE}Bitcoin Mainnet Block Height:${NC}"
    if docker ps --format '{{.Names}}' | grep -q btc-mainnet-monitor; then
        MAINNET_BLOCK=$(btc_rpc_call mainnet getblockcount)
        echo "  Block: $MAINNET_BLOCK"
    else
        print_warning "Mainnet node not running"
    fi
    echo ""

    echo -e "${BLUE}Bitcoin Testnet Block Height:${NC}"
    if docker ps --format '{{.Names}}' | grep -q btc-testnet-monitor; then
        TESTNET_BLOCK=$(btc_rpc_call testnet getblockcount)
        echo "  Block: $TESTNET_BLOCK"
    else
        print_warning "Testnet node not running"
    fi
}

# Get blockchain info
get_info() {
    print_header

    echo -e "${BLUE}Bitcoin Mainnet Info:${NC}"
    if docker ps --format '{{.Names}}' | grep -q btc-mainnet-monitor; then
        btc_rpc_call mainnet getblockchaininfo | jq '.'
    else
        print_warning "Mainnet node not running"
    fi
    echo ""

    echo -e "${BLUE}Bitcoin Testnet Info:${NC}"
    if docker ps --format '{{.Names}}' | grep -q btc-testnet-monitor; then
        btc_rpc_call testnet getblockchaininfo | jq '.'
    else
        print_warning "Testnet node not running"
    fi
}

# Get mempool info
get_mempool() {
    print_header

    echo -e "${BLUE}Bitcoin Mainnet Mempool:${NC}"
    if docker ps --format '{{.Names}}' | grep -q btc-mainnet-monitor; then
        MEMPOOL=$(btc_rpc_call mainnet getmempoolinfo)
        SIZE=$(echo "$MEMPOOL" | jq -r '.size')
        BYTES=$(echo "$MEMPOOL" | jq -r '.bytes')
        echo "  Transactions: $SIZE"
        echo "  Size: $(($BYTES / 1024 / 1024)) MB"
    else
        print_warning "Mainnet node not running"
    fi
    echo ""

    echo -e "${BLUE}Bitcoin Testnet Mempool:${NC}"
    if docker ps --format '{{.Names}}' | grep -q btc-testnet-monitor; then
        MEMPOOL=$(btc_rpc_call testnet getmempoolinfo)
        SIZE=$(echo "$MEMPOOL" | jq -r '.size')
        BYTES=$(echo "$MEMPOOL" | jq -r '.bytes')
        echo "  Transactions: $SIZE"
        echo "  Size: $(($BYTES / 1024 / 1024)) MB"
    else
        print_warning "Testnet node not running"
    fi
}

# View logs
view_logs() {
    print_header

    if [ "$1" == "mainnet" ]; then
        print_info "Showing Bitcoin Mainnet logs (Ctrl+C to exit)..."
        docker logs -f btc-mainnet-monitor
    elif [ "$1" == "testnet" ]; then
        print_info "Showing Bitcoin Testnet logs (Ctrl+C to exit)..."
        docker logs -f btc-testnet-monitor
    else
        print_error "Please specify 'mainnet' or 'testnet'"
        echo "Usage: $0 logs [mainnet|testnet]"
    fi
}

# Resource usage
check_resources() {
    print_header
    print_info "Resource Usage:"
    docker stats --no-stream btc-mainnet-monitor btc-testnet-monitor 2>/dev/null || print_warning "Nodes not running"
}

# Bitcoin console
attach_console() {
    print_header

    if [ "$1" == "mainnet" ]; then
        print_info "Attaching to Bitcoin Mainnet console (type 'exit' to quit)..."
        docker exec -it btc-mainnet-monitor bitcoin-cli -conf=/etc/bitcoin/bitcoin.conf
    elif [ "$1" == "testnet" ]; then
        print_info "Attaching to Bitcoin Testnet console (type 'exit' to quit)..."
        docker exec -it btc-testnet-monitor bitcoin-cli -conf=/etc/bitcoin/bitcoin.conf -testnet
    else
        print_error "Please specify 'mainnet' or 'testnet'"
        echo "Usage: $0 console [mainnet|testnet]"
    fi
}

# Test RPC
test_rpc() {
    print_header

    echo -e "${BLUE}Testing Bitcoin Mainnet RPC:${NC}"
    if docker ps --format '{{.Names}}' | grep -q btc-mainnet-monitor; then
        RESULT=$(btc_rpc_call mainnet getblockchaininfo)
        if [ ! -z "$RESULT" ]; then
            print_success "RPC responding"
            echo "$RESULT" | jq '{chain, blocks, headers, verificationprogress}'
        else
            print_error "RPC not responding"
        fi
    else
        print_warning "Mainnet node not running"
    fi
    echo ""

    echo -e "${BLUE}Testing Bitcoin Testnet RPC:${NC}"
    if docker ps --format '{{.Names}}' | grep -q btc-testnet-monitor; then
        RESULT=$(btc_rpc_call testnet getblockchaininfo)
        if [ ! -z "$RESULT" ]; then
            print_success "RPC responding"
            echo "$RESULT" | jq '{chain, blocks, headers, verificationprogress}'
        else
            print_error "RPC not responding"
        fi
    else
        print_warning "Testnet node not running"
    fi
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
    echo "  start           - Start all services (Bitcoin nodes + monitoring)"
    echo "  start-nodes     - Start only Bitcoin nodes (no monitoring)"
    echo "  stop            - Stop all services"
    echo "  status          - Show status of all services"
    echo "  sync            - Check sync status"
    echo "  peers           - Check peer count"
    echo "  blocks          - Check block height"
    echo "  info            - Get blockchain info"
    echo "  mempool         - Get mempool info"
    echo "  logs [network]  - View logs (mainnet|testnet)"
    echo "  resources       - Show resource usage"
    echo "  console [net]   - Attach to Bitcoin console (mainnet|testnet)"
    echo "  test-rpc        - Test RPC endpoints"
    echo "  help            - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 sync"
    echo "  $0 logs mainnet"
    echo "  $0 console testnet"
    echo "  $0 mempool"
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
    info)
        get_info
        ;;
    mempool)
        get_mempool
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
