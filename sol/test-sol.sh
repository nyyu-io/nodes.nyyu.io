#!/bin/bash

# Solana Node Test Script
# Tests all endpoints to ensure everything is working

DOMAIN="node-sol.nyyu.io"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Solana Node Testing                 ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

test_rpc_endpoint() {
    local name=$1
    local url=$2
    local method=$3

    echo -e "${BLUE}Testing: ${name}${NC}"
    RESPONSE=$(curl -s --max-time 10 -X POST "$url" -H "Content-Type: application/json" -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"$method\"}")

    if [ $? -eq 0 ] && [ ! -z "$RESPONSE" ]; then
        echo -e "${GREEN}✓ Success${NC}"
        echo "  Response: $(echo $RESPONSE | jq -r '.result.absoluteSlot // .result // .' 2>/dev/null | head -1)"
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

echo -e "${BLUE}3. Testing Solana Mainnet RPC${NC}"
test_rpc_endpoint "Get Health" "https://$DOMAIN/mainnet/rpc" "getHealth"
test_rpc_endpoint "Get Version" "https://$DOMAIN/mainnet/rpc" "getVersion"
test_rpc_endpoint "Get Slot" "https://$DOMAIN/mainnet/rpc" "getSlot"
test_rpc_endpoint "Get Epoch Info" "https://$DOMAIN/mainnet/rpc" "getEpochInfo"

echo -e "${BLUE}4. Testing Solana Devnet RPC${NC}"
test_rpc_endpoint "Get Health" "https://$DOMAIN/devnet/rpc" "getHealth"
test_rpc_endpoint "Get Version" "https://$DOMAIN/devnet/rpc" "getVersion"
test_rpc_endpoint "Get Slot" "https://$DOMAIN/devnet/rpc" "getSlot"
test_rpc_endpoint "Get Epoch Info" "https://$DOMAIN/devnet/rpc" "getEpochInfo"

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
echo "  • Solana Mainnet RPC:  https://$DOMAIN/mainnet/rpc"
echo "  • Solana Devnet RPC:   https://$DOMAIN/devnet/rpc"
echo "  • Grafana:             https://$DOMAIN/grafana/"
echo ""
