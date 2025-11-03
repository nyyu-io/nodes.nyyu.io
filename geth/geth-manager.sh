#!/bin/bash

# Geth Node Manager Script
# Provides easy commands for managing Geth monitoring nodes

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
    echo -e "${BLUE}║   Geth Monitoring Node Manager        ║${NC}"
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
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
    print_info "Starting all Geth monitoring services..."
    docker compose up -d
    print_success "All services started!"
    echo ""
    print_info "Access points:"
    echo "  • Mainnet RPC:  http://localhost:8545"
    echo "  • Mainnet WS:   ws://localhost:8546"
    echo "  • Sepolia RPC:  http://localhost:8547"
    echo "  • Sepolia WS:   ws://localhost:8548"
    echo "  • Grafana:      http://localhost:3001 (admin/admin)"
    echo "  • Prometheus:   http://localhost:9091"
}

# Start only geth nodes
start_nodes() {
    print_header
    print_info "Starting Geth nodes and Lighthouse (no monitoring)..."
    docker compose up -d geth-mainnet geth-sepolia lighthouse-mainnet lighthouse-sepolia
    print_success "Geth nodes and Lighthouse started!"
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

    echo -e "${BLUE}Mainnet Sync Status:${NC}"
    curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        http://localhost:8545 | jq -r '.result' || print_warning "Mainnet node not running"
    echo ""

    echo -e "${BLUE}Sepolia Sync Status:${NC}"
    curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
        http://localhost:8547 | jq -r '.result' || print_warning "Sepolia node not running"
    echo ""

    print_info "Note: 'false' means fully synced"
}

# Check peer count
check_peers() {
    print_header

    echo -e "${BLUE}Mainnet Peers:${NC}"
    MAINNET_PEERS=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        http://localhost:8545 | jq -r '.result' | xargs printf "%d\n" 2>/dev/null || echo "0")
    echo "  Geth Peers: $MAINNET_PEERS"

    MAINNET_LH_PEERS=$(curl -s http://localhost:5052/eth/v1/node/peer_count 2>/dev/null | jq -r '.data.connected' 2>/dev/null || echo "N/A")
    echo "  Lighthouse Peers: $MAINNET_LH_PEERS"
    echo ""

    echo -e "${BLUE}Sepolia Peers:${NC}"
    SEPOLIA_PEERS=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' \
        http://localhost:8547 | jq -r '.result' | xargs printf "%d\n" 2>/dev/null || echo "0")
    echo "  Geth Peers: $SEPOLIA_PEERS"

    SEPOLIA_LH_PEERS=$(curl -s http://localhost:5053/eth/v1/node/peer_count 2>/dev/null | jq -r '.data.connected' 2>/dev/null || echo "N/A")
    echo "  Lighthouse Peers: $SEPOLIA_LH_PEERS"
    echo ""

    if [ "$MAINNET_PEERS" -lt 5 ] || [ "$SEPOLIA_PEERS" -lt 5 ]; then
        print_warning "Low peer count detected. Consider checking your network/firewall."
    fi
}

# Check Lighthouse sync status
check_lighthouse() {
    print_header

    echo -e "${BLUE}Mainnet Lighthouse Status:${NC}"
    curl -s http://localhost:5052/eth/v1/node/syncing 2>/dev/null | jq -r 'if .data.is_syncing then "Syncing: \(.data.sync_distance) slots behind" else "✓ Synced" end' || print_warning "Lighthouse not running"
    echo ""

    echo -e "${BLUE}Sepolia Lighthouse Status:${NC}"
    curl -s http://localhost:5053/eth/v1/node/syncing 2>/dev/null | jq -r 'if .data.is_syncing then "Syncing: \(.data.sync_distance) slots behind" else "✓ Synced" end' || print_warning "Lighthouse not running"
}

# Check block height
check_blocks() {
    print_header

    echo -e "${BLUE}Mainnet Block Height:${NC}"
    MAINNET_BLOCK=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8545 | jq -r '.result' | xargs printf "%d\n" 2>/dev/null || echo "0")
    echo "  Block: $MAINNET_BLOCK"
    echo ""

    echo -e "${BLUE}Sepolia Block Height:${NC}"
    SEPOLIA_BLOCK=$(curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8547 | jq -r '.result' | xargs printf "%d\n" 2>/dev/null || echo "0")
    echo "  Block: $SEPOLIA_BLOCK"
}

# View logs
view_logs() {
    print_header

    if [ "$1" == "mainnet" ]; then
        print_info "Showing Mainnet Geth logs (Ctrl+C to exit)..."
        docker logs -f geth-mainnet-monitor
    elif [ "$1" == "sepolia" ]; then
        print_info "Showing Sepolia Geth logs (Ctrl+C to exit)..."
        docker logs -f geth-sepolia-monitor
    elif [ "$1" == "lighthouse-mainnet" ]; then
        print_info "Showing Mainnet Lighthouse logs (Ctrl+C to exit)..."
        docker logs -f lighthouse-mainnet
    elif [ "$1" == "lighthouse-sepolia" ]; then
        print_info "Showing Sepolia Lighthouse logs (Ctrl+C to exit)..."
        docker logs -f lighthouse-sepolia
    else
        print_error "Please specify a service: mainnet, sepolia, lighthouse-mainnet, lighthouse-sepolia"
        echo "Usage: $0 logs [mainnet|sepolia|lighthouse-mainnet|lighthouse-sepolia]"
    fi
}

# Resource usage
check_resources() {
    print_header
    print_info "Resource Usage:"
    docker stats --no-stream geth-mainnet-monitor geth-sepolia-monitor 2>/dev/null || print_warning "Nodes not running"
}

# Geth console
attach_console() {
    print_header

    if [ "$1" == "mainnet" ]; then
        print_info "Attaching to Mainnet console (type 'exit' to quit)..."
        docker exec -it geth-mainnet-monitor geth attach http://localhost:8545
    elif [ "$1" == "sepolia" ]; then
        print_info "Attaching to Sepolia console (type 'exit' to quit)..."
        docker exec -it geth-sepolia-monitor geth attach http://localhost:8545
    else
        print_error "Please specify 'mainnet' or 'sepolia'"
        echo "Usage: $0 console [mainnet|sepolia]"
    fi
}

# Test RPC
test_rpc() {
    print_header

    echo -e "${BLUE}Testing Mainnet RPC:${NC}"
    curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8545 | jq || print_error "Mainnet RPC not responding"
    echo ""

    echo -e "${BLUE}Testing Sepolia RPC:${NC}"
    curl -s -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
        http://localhost:8547 | jq || print_error "Sepolia RPC not responding"
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
    echo "  start           - Start all services (Geth + Lighthouse + monitoring)"
    echo "  start-nodes     - Start only Geth and Lighthouse nodes (no monitoring)"
    echo "  stop            - Stop all services"
    echo "  status          - Show status of all services"
    echo "  sync            - Check Geth sync status"
    echo "  lighthouse      - Check Lighthouse sync status"
    echo "  peers           - Check peer count (Geth + Lighthouse)"
    echo "  blocks          - Check block height"
    echo "  logs [service]  - View logs (mainnet|sepolia|lighthouse-mainnet|lighthouse-sepolia)"
    echo "  resources       - Show resource usage"
    echo "  console [net]   - Attach to Geth console (mainnet|sepolia)"
    echo "  test-rpc        - Test RPC endpoints"
    echo "  help            - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 sync"
    echo "  $0 lighthouse"
    echo "  $0 logs mainnet"
    echo "  $0 logs lighthouse-mainnet"
    echo "  $0 console sepolia"
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
    lighthouse)
        check_lighthouse
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
