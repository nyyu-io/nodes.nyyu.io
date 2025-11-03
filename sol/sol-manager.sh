#!/bin/bash

# Solana Node Manager Script
# Provides easy commands for managing Solana RPC nodes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Solana RPC Node Manager             ║${NC}"
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

start_all() {
    print_header
    print_info "Starting all Solana RPC services..."
    docker compose up -d
    print_success "All services started!"
    echo ""
    print_info "Access points:"
    echo "  • Solana Mainnet RPC:  http://localhost:8899"
    echo "  • Solana Devnet RPC:   http://localhost:8898"
    echo "  • Grafana:             http://localhost:3005 (admin/admin)"
    echo "  • Prometheus:          http://localhost:9095"
}

start_nodes() {
    print_header
    print_info "Starting Solana nodes only (no monitoring)..."
    docker compose up -d sol-mainnet sol-devnet
    print_success "Solana nodes started!"
}

stop_all() {
    print_header
    print_info "Stopping all services..."
    docker compose down
    print_success "All services stopped!"
}

check_sync() {
    print_header

    echo -e "${BLUE}Solana Mainnet Sync Status:${NC}"
    if docker ps --format '{{.Names}}' | grep -q sol-mainnet-monitor; then
        MAINNET_INFO=$(curl -s -X POST http://localhost:8899 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getEpochInfo"}' 2>/dev/null)
        if [ $? -eq 0 ]; then
            SLOT=$(echo "$MAINNET_INFO" | jq -r '.result.absoluteSlot' 2>/dev/null || echo "0")
            EPOCH=$(echo "$MAINNET_INFO" | jq -r '.result.epoch' 2>/dev/null || echo "0")
            echo "  Current slot: $SLOT"
            echo "  Current epoch: $EPOCH"
        else
            print_warning "Mainnet node starting or not responding"
        fi
    else
        print_warning "Mainnet node not running"
    fi
    echo ""

    echo -e "${BLUE}Solana Devnet Sync Status:${NC}"
    if docker ps --format '{{.Names}}' | grep -q sol-devnet-monitor; then
        DEVNET_INFO=$(curl -s -X POST http://localhost:8898 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getEpochInfo"}' 2>/dev/null)
        if [ $? -eq 0 ]; then
            SLOT=$(echo "$DEVNET_INFO" | jq -r '.result.absoluteSlot' 2>/dev/null || echo "0")
            EPOCH=$(echo "$DEVNET_INFO" | jq -r '.result.epoch' 2>/dev/null || echo "0")
            echo "  Current slot: $SLOT"
            echo "  Current epoch: $EPOCH"
        else
            print_warning "Devnet node starting or not responding"
        fi
    else
        print_warning "Devnet node not running"
    fi
}

check_slots() {
    print_header

    echo -e "${BLUE}Solana Mainnet Slot:${NC}"
    MAINNET_SLOT=$(curl -s -X POST http://localhost:8899 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' 2>/dev/null | jq -r '.result' 2>/dev/null || echo "0")
    echo "  Slot: $MAINNET_SLOT"
    echo ""

    echo -e "${BLUE}Solana Devnet Slot:${NC}"
    DEVNET_SLOT=$(curl -s -X POST http://localhost:8898 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}' 2>/dev/null | jq -r '.result' 2>/dev/null || echo "0")
    echo "  Slot: $DEVNET_SLOT"
}

view_logs() {
    print_header
    if [ "$1" == "mainnet" ]; then
        print_info "Showing Solana Mainnet logs (Ctrl+C to exit)..."
        docker logs -f sol-mainnet-monitor
    elif [ "$1" == "devnet" ]; then
        print_info "Showing Solana Devnet logs (Ctrl+C to exit)..."
        docker logs -f sol-devnet-monitor
    else
        print_error "Please specify 'mainnet' or 'devnet'"
        echo "Usage: $0 logs [mainnet|devnet]"
    fi
}

check_resources() {
    print_header
    print_info "Resource Usage:"
    docker stats --no-stream sol-mainnet-monitor sol-devnet-monitor 2>/dev/null || print_warning "Nodes not running"
}

test_rpc() {
    print_header

    echo -e "${BLUE}Testing Solana Mainnet RPC:${NC}"
    RESULT=$(curl -s -X POST http://localhost:8899 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' 2>/dev/null)
    if [ ! -z "$RESULT" ]; then
        print_success "RPC responding"
        VERSION=$(curl -s -X POST http://localhost:8899 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getVersion"}' 2>/dev/null | jq -r '.result["solana-core"]' 2>/dev/null)
        echo "  Version: $VERSION"
    else
        print_error "RPC not responding"
    fi
    echo ""

    echo -e "${BLUE}Testing Solana Devnet RPC:${NC}"
    RESULT=$(curl -s -X POST http://localhost:8898 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}' 2>/dev/null)
    if [ ! -z "$RESULT" ]; then
        print_success "RPC responding"
        VERSION=$(curl -s -X POST http://localhost:8898 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getVersion"}' 2>/dev/null | jq -r '.result["solana-core"]' 2>/dev/null)
        echo "  Version: $VERSION"
    else
        print_error "RPC not responding"
    fi
}

validator_info() {
    print_header
    if [ "$1" == "mainnet" ]; then
        echo -e "${BLUE}Solana Mainnet Validator Info:${NC}"
        curl -s -X POST http://localhost:8899 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getEpochInfo"}' | jq '.'
    elif [ "$1" == "devnet" ]; then
        echo -e "${BLUE}Solana Devnet Validator Info:${NC}"
        curl -s -X POST http://localhost:8898 -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","id":1,"method":"getEpochInfo"}' | jq '.'
    else
        print_error "Please specify 'mainnet' or 'devnet'"
        echo "Usage: $0 info [mainnet|devnet]"
    fi
}

status() {
    print_header
    print_info "Service Status:"
    docker compose ps
    echo ""
    check_slots
}

show_help() {
    print_header
    echo "Usage: $0 [command]"
    echo ""
    echo "Available commands:"
    echo "  start           - Start all services (Solana nodes + monitoring)"
    echo "  start-nodes     - Start only Solana nodes (no monitoring)"
    echo "  stop            - Stop all services"
    echo "  status          - Show status of all services"
    echo "  sync            - Check sync status"
    echo "  slots           - Check slot height"
    echo "  logs [network]  - View logs (mainnet|devnet)"
    echo "  resources       - Show resource usage"
    echo "  test-rpc        - Test RPC endpoints"
    echo "  info [network]  - Show validator info (mainnet|devnet)"
    echo "  help            - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 sync"
    echo "  $0 logs mainnet"
    echo "  $0 test-rpc"
    echo "  $0 info mainnet"
}

check_docker

case "$1" in
    start) start_all ;;
    start-nodes) start_nodes ;;
    stop) stop_all ;;
    status) status ;;
    sync) check_sync ;;
    slots) check_slots ;;
    logs) view_logs "$2" ;;
    resources) check_resources ;;
    test-rpc) test_rpc ;;
    info) validator_info "$2" ;;
    help|--help|-h) show_help ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
