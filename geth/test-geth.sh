#!/bin/bash

# Geth Node Test Script
# Tests all endpoints to ensure everything is working

DOMAIN="node-eth.nyyu.io"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Geth Node Testing                    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

test_endpoint() {
    local name=$1
    local url=$2
    local method=$3

    echo -e "${BLUE}Testing: ${name}${NC}"

    if [ -z "$method" ]; then
        # Simple GET test
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url")
    else
        # JSON-RPC test
        RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
            --data "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":[],\"id\":1}" \
            --max-time 10 "$url")
    fi

    if [ $? -eq 0 ]; then
        if [ -z "$method" ]; then
            if [ "$RESPONSE" = "200" ]; then
                echo -e "${GREEN}✓ Success (HTTP $RESPONSE)${NC}"
            else
                echo -e "${YELLOW}⚠ Warning (HTTP $RESPONSE)${NC}"
            fi
        else
            if echo "$RESPONSE" | grep -q "result"; then
                echo -e "${GREEN}✓ Success${NC}"
                echo "  Response: $(echo $RESPONSE | jq -r '.result' 2>/dev/null || echo $RESPONSE)"
            else
                echo -e "${YELLOW}⚠ Warning: No result${NC}"
                echo "  Response: $RESPONSE"
            fi
        fi
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
    echo ""
}

print_header

echo "Testing domain: $DOMAIN"
echo ""

# Test SSL Certificate
echo -e "${BLUE}1. Testing SSL Certificate${NC}"
openssl s_client -connect $DOMAIN:443 -servername $DOMAIN < /dev/null 2>/dev/null | grep -A2 "Certificate chain"
echo ""

# Test Nginx Health
echo -e "${BLUE}2. Testing Nginx Health${NC}"
test_endpoint "Nginx Health" "https://$DOMAIN/health"

# Test Mainnet RPC
echo -e "${BLUE}3. Testing Mainnet RPC${NC}"
test_endpoint "Block Number" "https://$DOMAIN/mainnet/rpc" "eth_blockNumber"
test_endpoint "Peer Count" "https://$DOMAIN/mainnet/rpc" "net_peerCount"
test_endpoint "Sync Status" "https://$DOMAIN/mainnet/rpc" "eth_syncing"

# Test Sepolia RPC
echo -e "${BLUE}4. Testing Sepolia RPC${NC}"
test_endpoint "Block Number" "https://$DOMAIN/sepolia/rpc" "eth_blockNumber"
test_endpoint "Peer Count" "https://$DOMAIN/sepolia/rpc" "net_peerCount"
test_endpoint "Sync Status" "https://$DOMAIN/sepolia/rpc" "eth_syncing"

# Test Grafana
echo -e "${BLUE}5. Testing Grafana${NC}"
GRAFANA_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$DOMAIN/grafana/api/health")
if [ "$GRAFANA_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Grafana is accessible${NC}"
else
    echo -e "${YELLOW}⚠ Grafana returned HTTP $GRAFANA_RESPONSE${NC}"
fi
echo ""

# Test Prometheus
echo -e "${BLUE}6. Testing Prometheus${NC}"
PROM_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "https://$DOMAIN/prometheus/-/healthy")
if [ "$PROM_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Prometheus is accessible${NC}"
else
    echo -e "${YELLOW}⚠ Prometheus returned HTTP $PROM_RESPONSE${NC}"
fi
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Testing Complete!                              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Access URLs:"
echo "  • Mainnet RPC:  https://$DOMAIN/mainnet/rpc"
echo "  • Mainnet WS:   wss://$DOMAIN/mainnet/ws"
echo "  • Sepolia RPC:  https://$DOMAIN/sepolia/rpc"
echo "  • Sepolia WS:   wss://$DOMAIN/sepolia/ws"
echo "  • Grafana:      https://$DOMAIN/grafana/"
echo "  • Prometheus:   https://$DOMAIN/prometheus/"
echo ""
