#!/bin/bash

# Polygon Node Manager Script
# Provides easy commands for managing Polygon nodes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Polygon Node Manager                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }

check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker first."
        exit 1
    fi
}

rpc_call() {
    local port=$1
    local method=$2
    local params=$3
    curl -s -X POST "http://localhost:$port" \
        -H "Content-Type: application/json" \
        -d "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":[$params],\"id\":1}" 2>/dev/null
}

hex_to_dec() {
    printf "%d" "$1" 2>/dev/null || echo "0"
}

start_all() {
    print_header
    print_info "Starting all Polygon services..."
    docker compose up -d
    print_success "All services started!"
    echo ""
    print_info "Access points:"
    echo "  • Polygon Mainnet RPC:  http://localhost:8545"
    echo "  • Polygon Mumbai RPC:   http://localhost:8547"
    echo "  • Grafana:              http://localhost:3006 (admin/admin)"
    echo "  • Prometheus:           http://localhost:9096"
}

start_nodes() {
    print_header
    print_info "Starting Polygon nodes only (no monitoring)..."
    docker compose up -d polygon-mainnet polygon-mumbai
    print_success "Polygon nodes started!"
}

stop_all() {
    print_header
    print_info "Stopping all services..."
    docker compose down
    print_success "All services stopped!"
}

check_sync() {
    print_header

    echo -e "${BLUE}Polygon Mainnet Sync Status:${NC}"
    if docker ps --format '{{.Names}}' | grep -q polygon-mainnet-monitor; then
        SYNC_INFO=$(rpc_call 8545 "eth_syncing" "")
        if [ ! -z "$SYNC_INFO" ]; then
            IS_SYNCING=$(echo "$SYNC_INFO" | jq -r '.result' 2>/dev/null)
            if [ "$IS_SYNCING" = "false" ]; then
                print_success "Mainnet is fully synced"
                BLOCK=$(rpc_call 8545 "eth_blockNumber" "" | jq -r '.result' 2>/dev/null)
                BLOCK_DEC=$(hex_to_dec "$BLOCK")
                echo "  Current block: $BLOCK_DEC"
            else
                CURRENT=$(echo "$SYNC_INFO" | jq -r '.result.currentBlock' 2>/dev/null)
                HIGHEST=$(echo "$SYNC_INFO" | jq -r '.result.highestBlock' 2>/dev/null)
                CURRENT_DEC=$(hex_to_dec "$CURRENT")
                HIGHEST_DEC=$(hex_to_dec "$HIGHEST")
                print_warning "Syncing: $CURRENT_DEC / $HIGHEST_DEC"
            fi
        else
            print_warning "Mainnet node starting or not responding"
        fi
    else
        print_warning "Mainnet node not running"
    fi
    echo ""

    echo -e "${BLUE}Polygon Mumbai Sync Status:${NC}"
    if docker ps --format '{{.Names}}' | grep -q polygon-mumbai-monitor; then
        SYNC_INFO=$(rpc_call 8547 "eth_syncing" "")
        if [ ! -z "$SYNC_INFO" ]; then
            IS_SYNCING=$(echo "$SYNC_INFO" | jq -r '.result' 2>/dev/null)
            if [ "$IS_SYNCING" = "false" ]; then
                print_success "Mumbai is fully synced"
                BLOCK=$(rpc_call 8547 "eth_blockNumber" "" | jq -r '.result' 2>/dev/null)
                BLOCK_DEC=$(hex_to_dec "$BLOCK")
                echo "  Current block: $BLOCK_DEC"
            else
                CURRENT=$(echo "$SYNC_INFO" | jq -r '.result.currentBlock' 2>/dev/null)
                HIGHEST=$(echo "$SYNC_INFO" | jq -r '.result.highestBlock' 2>/dev/null)
                CURRENT_DEC=$(hex_to_dec "$CURRENT")
                HIGHEST_DEC=$(hex_to_dec "$HIGHEST")
                print_warning "Syncing: $CURRENT_DEC / $HIGHEST_DEC"
            fi
        else
            print_warning "Mumbai node starting or not responding"
        fi
    else
        print_warning "Mumbai node not running"
    fi
}

check_blocks() {
    print_header

    echo -e "${BLUE}Polygon Mainnet Block Height:${NC}"
    MAINNET_BLOCK_HEX=$(rpc_call 8545 "eth_blockNumber" "" | jq -r '.result' 2>/dev/null)
    MAINNET_BLOCK=$(hex_to_dec "$MAINNET_BLOCK_HEX")
    echo "  Block: $MAINNET_BLOCK"
    echo ""

    echo -e "${BLUE}Polygon Mumbai Block Height:${NC}"
    MUMBAI_BLOCK_HEX=$(rpc_call 8547 "eth_blockNumber" "" | jq -r '.result' 2>/dev/null)
    MUMBAI_BLOCK=$(hex_to_dec "$MUMBAI_BLOCK_HEX")
    echo "  Block: $MUMBAI_BLOCK"
}

check_peers() {
    print_header

    echo -e "${BLUE}Polygon Mainnet Peers:${NC}"
    MAINNET_PEERS_HEX=$(rpc_call 8545 "net_peerCount" "" | jq -r '.result' 2>/dev/null)
    MAINNET_PEERS=$(hex_to_dec "$MAINNET_PEERS_HEX")
    if [ "$MAINNET_PEERS" -gt 0 ]; then
        print_success "$MAINNET_PEERS peers connected"
    else
        print_warning "No peers connected"
    fi
    echo ""

    echo -e "${BLUE}Polygon Mumbai Peers:${NC}"
    MUMBAI_PEERS_HEX=$(rpc_call 8547 "net_peerCount" "" | jq -r '.result' 2>/dev/null)
    MUMBAI_PEERS=$(hex_to_dec "$MUMBAI_PEERS_HEX")
    if [ "$MUMBAI_PEERS" -gt 0 ]; then
        print_success "$MUMBAI_PEERS peers connected"
    else
        print_warning "No peers connected"
    fi
}

view_logs() {
    print_header
    if [ "$1" == "mainnet" ]; then
        print_info "Showing Polygon Mainnet logs (Ctrl+C to exit)..."
        docker logs -f polygon-mainnet-monitor
    elif [ "$1" == "mumbai" ]; then
        print_info "Showing Polygon Mumbai logs (Ctrl+C to exit)..."
        docker logs -f polygon-mumbai-monitor
    else
        print_error "Please specify 'mainnet' or 'mumbai'"
        echo "Usage: $0 logs [mainnet|mumbai]"
    fi
}

check_resources() {
    print_header
    print_info "Resource Usage:"
    docker stats --no-stream polygon-mainnet-monitor polygon-mumbai-monitor 2>/dev/null || print_warning "Nodes not running"
}

test_rpc() {
    print_header

    echo -e "${BLUE}Testing Polygon Mainnet RPC:${NC}"
    VERSION=$(rpc_call 8545 "net_version" "" | jq -r '.result' 2>/dev/null)
    if [ "$VERSION" == "137" ]; then
        print_success "RPC responding (Chain ID: $VERSION)"
        BLOCK_HEX=$(rpc_call 8545 "eth_blockNumber" "" | jq -r '.result' 2>/dev/null)
        BLOCK=$(hex_to_dec "$BLOCK_HEX")
        echo "  Block: $BLOCK"
        GAS_PRICE=$(rpc_call 8545 "eth_gasPrice" "" | jq -r '.result' 2>/dev/null)
        GAS_GWEI=$(printf "%.2f" "$(echo "scale=9; $(hex_to_dec $GAS_PRICE) / 1000000000" | bc)")
        echo "  Gas Price: $GAS_GWEI Gwei"
    else
        print_error "RPC not responding or wrong chain"
    fi
    echo ""

    echo -e "${BLUE}Testing Polygon Mumbai RPC:${NC}"
    VERSION=$(rpc_call 8547 "net_version" "" | jq -r '.result' 2>/dev/null)
    if [ "$VERSION" == "80001" ]; then
        print_success "RPC responding (Chain ID: $VERSION)"
        BLOCK_HEX=$(rpc_call 8547 "eth_blockNumber" "" | jq -r '.result' 2>/dev/null)
        BLOCK=$(hex_to_dec "$BLOCK_HEX")
        echo "  Block: $BLOCK"
        GAS_PRICE=$(rpc_call 8547 "eth_gasPrice" "" | jq -r '.result' 2>/dev/null)
        GAS_GWEI=$(printf "%.2f" "$(echo "scale=9; $(hex_to_dec $GAS_PRICE) / 1000000000" | bc)")
        echo "  Gas Price: $GAS_GWEI Gwei"
    else
        print_error "RPC not responding or wrong chain"
    fi
}

status() {
    print_header
    print_info "Service Status:"
    docker compose ps
    echo ""
    check_blocks
}

show_help() {
    print_header
    echo "Usage: $0 [command]"
    echo ""
    echo "Available commands:"
    echo "  start           - Start all services (Polygon nodes + monitoring)"
    echo "  start-nodes     - Start only Polygon nodes (no monitoring)"
    echo "  stop            - Stop all services"
    echo "  status          - Show status of all services"
    echo "  sync            - Check sync status"
    echo "  blocks          - Check block height"
    echo "  peers           - Check peer count"
    echo "  logs [network]  - View logs (mainnet|mumbai)"
    echo "  resources       - Show resource usage"
    echo "  test-rpc        - Test RPC endpoints"
    echo "  help            - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 sync"
    echo "  $0 logs mainnet"
    echo "  $0 test-rpc"
    echo "  $0 peers"
}

check_docker

case "$1" in
    start) start_all ;;
    start-nodes) start_nodes ;;
    stop) stop_all ;;
    status) status ;;
    sync) check_sync ;;
    blocks) check_blocks ;;
    peers) check_peers ;;
    logs) view_logs "$2" ;;
    resources) check_resources ;;
    test-rpc) test_rpc ;;
    help|--help|-h) show_help ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
