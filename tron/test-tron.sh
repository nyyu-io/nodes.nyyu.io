#!/bin/bash

# Tron Node Test Script
# Tests all endpoints to ensure everything is working

DOMAIN="node-tron.nyyu.io"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Tron Node Testing                    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

test_api_endpoint() {
    local name=$1
    local url=$2

    echo -e "${BLUE}Testing: ${name}${NC}"
    RESPONSE=$(curl -s --max-time 10 "$url")

    if [ $? -eq 0 ] && [ ! -z "$RESPONSE" ]; then
        echo -e "${GREEN}✓ Success${NC}"
        echo "  Response: $(echo $RESPONSE | jq -r '.block_header.raw_data.number // .Error // .' 2>/dev/null | head -1)"
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

echo -e "${BLUE}3. Testing Tron Mainnet API${NC}"
test_api_endpoint "Get Now Block" "https://$DOMAIN/mainnet/api/wallet/getnowblock"
test_api_endpoint "Get Chain Parameters" "https://$DOMAIN/mainnet/api/wallet/getchainparameters"

echo -e "${BLUE}4. Testing Tron Nile API${NC}"
test_api_endpoint "Get Now Block" "https://$DOMAIN/nile/api/wallet/getnowblock"
test_api_endpoint "Get Chain Parameters" "https://$DOMAIN/nile/api/wallet/getchainparameters"

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
echo "  • Tron Mainnet API:  https://$DOMAIN/mainnet/api"
echo "  • Tron Nile API:     https://$DOMAIN/nile/api"
echo "  • Grafana:           https://$DOMAIN/grafana/"
echo ""
