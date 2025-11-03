#!/bin/bash

# Bitcoin Node Test Script
# Tests all endpoints to ensure everything is working

DOMAIN="node-btc.nyyu.io"
RPC_USER="${BTC_RPC_USER:-rpcuser}"
RPC_PASSWORD="${BTC_RPC_PASSWORD:-rpcpassword}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Bitcoin Node Testing                ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

test_rpc_endpoint() {
    local name=$1
    local url=$2
    local method=$3

    echo -e "${BLUE}Testing: ${name}${NC}"

    RESPONSE=$(curl -s --user "$RPC_USER:$RPC_PASSWORD" \
        --data-binary "{\"jsonrpc\":\"1.0\",\"id\":\"1\",\"method\":\"$method\",\"params\":[]}" \
        -H 'content-type: text/plain;' \
        --max-time 10 "$url")

    if [ $? -eq 0 ]; then
        if echo "$RESPONSE" | jq -e '.result' > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Success${NC}"
            echo "  Response: $(echo $RESPONSE | jq -r '.result' 2>/dev/null)"
        else
            ERROR=$(echo "$RESPONSE" | jq -r '.error.message' 2>/dev/null)
            if [ ! -z "$ERROR" ] && [ "$ERROR" != "null" ]; then
                echo -e "${YELLOW}⚠ Warning: $ERROR${NC}"
            else
                echo -e "${YELLOW}⚠ Warning: Unexpected response${NC}"
                echo "  Response: $RESPONSE"
            fi
        fi
    else
        echo -e "${RED}✗ Failed${NC}"
    fi
    echo ""
}

test_http_endpoint() {
    local name=$1
    local url=$2

    echo -e "${BLUE}Testing: ${name}${NC}"
    RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url")

    if [ "$RESPONSE" = "200" ]; then
        echo -e "${GREEN}✓ Success (HTTP $RESPONSE)${NC}"
    else
        echo -e "${YELLOW}⚠ Warning (HTTP $RESPONSE)${NC}"
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
test_http_endpoint "Nginx Health" "https://$DOMAIN/health"

# Test Bitcoin Mainnet RPC
echo -e "${BLUE}3. Testing Bitcoin Mainnet RPC${NC}"
test_rpc_endpoint "Block Count" "https://$DOMAIN/mainnet/rpc" "getblockcount"
test_rpc_endpoint "Connection Count" "https://$DOMAIN/mainnet/rpc" "getconnectioncount"
test_rpc_endpoint "Blockchain Info" "https://$DOMAIN/mainnet/rpc" "getblockchaininfo"
test_rpc_endpoint "Network Info" "https://$DOMAIN/mainnet/rpc" "getnetworkinfo"

# Test Bitcoin Testnet RPC
echo -e "${BLUE}4. Testing Bitcoin Testnet RPC${NC}"
test_rpc_endpoint "Block Count" "https://$DOMAIN/testnet/rpc" "getblockcount"
test_rpc_endpoint "Connection Count" "https://$DOMAIN/testnet/rpc" "getconnectioncount"
test_rpc_endpoint "Blockchain Info" "https://$DOMAIN/testnet/rpc" "getblockchaininfo"

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
echo "  • Bitcoin Mainnet RPC:  https://$DOMAIN/mainnet/rpc"
echo "  • Bitcoin Testnet RPC:  https://$DOMAIN/testnet/rpc"
echo "  • Grafana:              https://$DOMAIN/grafana/"
echo "  • Prometheus:           https://$DOMAIN/prometheus/"
echo ""
echo "RPC Credentials:"
echo "  • Username: $RPC_USER"
echo "  • Password: [hidden]"
echo ""
