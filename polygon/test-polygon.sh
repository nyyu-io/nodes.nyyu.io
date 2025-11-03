#!/bin/bash

# Polygon Node Test Script
# Tests all endpoints to ensure everything is working

DOMAIN="node-polygon.nyyu.io"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Polygon Node Testing                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

test_rpc_endpoint() {
    local name=$1
    local url=$2
    local method=$3
    local expected_chain=$4

    echo -e "${BLUE}Testing: ${name}${NC}"
    RESPONSE=$(curl -s --max-time 10 -X POST "$url" -H "Content-Type: application/json" -d "{\"jsonrpc\":\"2.0\",\"method\":\"$method\",\"params\":[],\"id\":1}")

    if [ $? -eq 0 ] && [ ! -z "$RESPONSE" ]; then
        RESULT=$(echo "$RESPONSE" | jq -r '.result' 2>/dev/null)
        if [ "$method" == "net_version" ]; then
            if [ "$RESULT" == "$expected_chain" ]; then
                echo -e "${GREEN}✓ Success (Chain ID: $RESULT)${NC}"
            else
                echo -e "${RED}✗ Wrong chain ID: $RESULT (expected: $expected_chain)${NC}"
            fi
        elif [ "$method" == "eth_blockNumber" ]; then
            BLOCK_DEC=$(printf "%d" "$RESULT" 2>/dev/null)
            echo -e "${GREEN}✓ Success${NC}"
            echo "  Block: $BLOCK_DEC"
        else
            echo -e "${GREEN}✓ Success${NC}"
            echo "  Response: $(echo "$RESPONSE" | jq -r '.result' 2>/dev/null | head -1)"
        fi
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
    echo ""
}

print_header

echo "Testing domain: $DOMAIN"
echo ""

echo -e "${BLUE}1. Testing SSL Certificate${NC}"
openssl s_client -connect $DOMAIN:443 -servername $DOMAIN < /dev/null 2>/dev/null | grep -A2 "Certificate chain"
echo ""

echo -e "${BLUE}2. Testing Nginx Health${NC}"
curl -s -o /dev/null -w "%{http_code}\n" "https://$DOMAIN/health"
echo ""

echo -e "${BLUE}3. Testing Polygon Mainnet RPC${NC}"
test_rpc_endpoint "Chain ID" "https://$DOMAIN/mainnet/rpc" "net_version" "137"
test_rpc_endpoint "Block Number" "https://$DOMAIN/mainnet/rpc" "eth_blockNumber" ""
test_rpc_endpoint "Gas Price" "https://$DOMAIN/mainnet/rpc" "eth_gasPrice" ""
test_rpc_endpoint "Peer Count" "https://$DOMAIN/mainnet/rpc" "net_peerCount" ""

echo -e "${BLUE}4. Testing Polygon Mumbai RPC${NC}"
test_rpc_endpoint "Chain ID" "https://$DOMAIN/mumbai/rpc" "net_version" "80001"
test_rpc_endpoint "Block Number" "https://$DOMAIN/mumbai/rpc" "eth_blockNumber" ""
test_rpc_endpoint "Gas Price" "https://$DOMAIN/mumbai/rpc" "eth_gasPrice" ""
test_rpc_endpoint "Peer Count" "https://$DOMAIN/mumbai/rpc" "net_peerCount" ""

echo -e "${BLUE}5. Testing Grafana${NC}"
GRAFANA_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "https://$DOMAIN/grafana/api/health")
if [ "$GRAFANA_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ Grafana is accessible${NC}"
else
    echo -e "${YELLOW}⚠ Grafana returned HTTP $GRAFANA_RESPONSE${NC}"
fi
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║         Testing Complete!                              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Access URLs:"
echo "  • Polygon Mainnet RPC:  https://$DOMAIN/mainnet/rpc"
echo "  • Polygon Mainnet WS:   wss://$DOMAIN/mainnet/ws"
echo "  • Polygon Mumbai RPC:   https://$DOMAIN/mumbai/rpc"
echo "  • Polygon Mumbai WS:    wss://$DOMAIN/mumbai/ws"
echo "  • Grafana:              https://$DOMAIN/grafana/"
echo ""
