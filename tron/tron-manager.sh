#!/bin/bash

# Tron Node Manager Script
# Provides easy commands for managing Tron monitoring nodes

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Tron Monitoring Node Manager        ║${NC}"
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
    print_info "Starting all Tron monitoring services..."
    docker compose up -d
    print_success "All services started!"
    echo ""
    print_info "Access points:"
    echo "  • Tron Mainnet API:  http://localhost:8090"
    echo "  • Tron Nile API:     http://localhost:8091"
    echo "  • Grafana:           http://localhost:3004 (admin/admin)"
    echo "  • Prometheus:        http://localhost:9094"
}

start_nodes() {
    print_header
    print_info "Starting Tron nodes only (no monitoring)..."
    docker compose up -d tron-mainnet tron-nile
    print_success "Tron nodes started!"
}

stop_all() {
    print_header
    print_info "Stopping all services..."
    docker compose down
    print_success "All services stopped!"
}

check_sync() {
    print_header

    echo -e "${BLUE}Tron Mainnet Sync Status:${NC}"
    if docker ps --format '{{.Names}}' | grep -q tron-mainnet-monitor; then
        MAINNET_INFO=$(curl -s http://localhost:8090/wallet/getnowblock 2>/dev/null)
        if [ $? -eq 0 ]; then
            BLOCK=$(echo "$MAINNET_INFO" | jq -r '.block_header.raw_data.number' 2>/dev/null || echo "0")
            echo "  Current block: $BLOCK"
        else
            print_warning "Mainnet node starting or not responding"
        fi
    else
        print_warning "Mainnet node not running"
    fi
    echo ""

    echo -e "${BLUE}Tron Nile Sync Status:${NC}"
    if docker ps --format '{{.Names}}' | grep -q tron-nile-monitor; then
        NILE_INFO=$(curl -s http://localhost:8091/wallet/getnowblock 2>/dev/null)
        if [ $? -eq 0 ]; then
            BLOCK=$(echo "$NILE_INFO" | jq -r '.block_header.raw_data.number' 2>/dev/null || echo "0")
            echo "  Current block: $BLOCK"
        else
            print_warning "Nile node starting or not responding"
        fi
    else
        print_warning "Nile node not running"
    fi
}

check_blocks() {
    print_header

    echo -e "${BLUE}Tron Mainnet Block Height:${NC}"
    MAINNET_BLOCK=$(curl -s http://localhost:8090/wallet/getnowblock 2>/dev/null | jq -r '.block_header.raw_data.number' 2>/dev/null || echo "0")
    echo "  Block: $MAINNET_BLOCK"
    echo ""

    echo -e "${BLUE}Tron Nile Block Height:${NC}"
    NILE_BLOCK=$(curl -s http://localhost:8091/wallet/getnowblock 2>/dev/null | jq -r '.block_header.raw_data.number' 2>/dev/null || echo "0")
    echo "  Block: $NILE_BLOCK"
}

view_logs() {
    print_header
    if [ "$1" == "mainnet" ]; then
        print_info "Showing Tron Mainnet logs (Ctrl+C to exit)..."
        docker logs -f tron-mainnet-monitor
    elif [ "$1" == "nile" ]; then
        print_info "Showing Tron Nile logs (Ctrl+C to exit)..."
        docker logs -f tron-nile-monitor
    else
        print_error "Please specify 'mainnet' or 'nile'"
        echo "Usage: $0 logs [mainnet|nile]"
    fi
}

check_resources() {
    print_header
    print_info "Resource Usage:"
    docker stats --no-stream tron-mainnet-monitor tron-nile-monitor 2>/dev/null || print_warning "Nodes not running"
}

test_api() {
    print_header

    echo -e "${BLUE}Testing Tron Mainnet API:${NC}"
    RESULT=$(curl -s http://localhost:8090/wallet/getnowblock 2>/dev/null)
    if [ ! -z "$RESULT" ]; then
        print_success "API responding"
        echo "$RESULT" | jq '{block_number: .block_header.raw_data.number, timestamp: .block_header.raw_data.timestamp}'
    else
        print_error "API not responding"
    fi
    echo ""

    echo -e "${BLUE}Testing Tron Nile API:${NC}"
    RESULT=$(curl -s http://localhost:8091/wallet/getnowblock 2>/dev/null)
    if [ ! -z "$RESULT" ]; then
        print_success "API responding"
        echo "$RESULT" | jq '{block_number: .block_header.raw_data.number, timestamp: .block_header.raw_data.timestamp}'
    else
        print_error "API not responding"
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
    echo "  start           - Start all services (Tron nodes + monitoring)"
    echo "  start-nodes     - Start only Tron nodes (no monitoring)"
    echo "  stop            - Stop all services"
    echo "  status          - Show status of all services"
    echo "  sync            - Check sync status"
    echo "  blocks          - Check block height"
    echo "  logs [network]  - View logs (mainnet|nile)"
    echo "  resources       - Show resource usage"
    echo "  test-api        - Test API endpoints"
    echo "  help            - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 sync"
    echo "  $0 logs mainnet"
    echo "  $0 test-api"
}

check_docker

case "$1" in
    start) start_all ;;
    start-nodes) start_nodes ;;
    stop) stop_all ;;
    status) status ;;
    sync) check_sync ;;
    blocks) check_blocks ;;
    logs) view_logs "$2" ;;
    resources) check_resources ;;
    test-api) test_api ;;
    help|--help|-h) show_help ;;
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
