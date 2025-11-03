#!/bin/bash

# Generate JWT secrets for Geth-Lighthouse communication
# This creates a random 32-byte hex string as required by both clients

echo "Generating JWT secrets for Geth-Lighthouse authentication..."

# Create jwt directories if they don't exist
mkdir -p ./jwt/mainnet
mkdir -p ./jwt/sepolia

# Generate JWT secret for mainnet (if it doesn't exist)
if [ ! -f ./jwt/mainnet/jwt.hex ]; then
    openssl rand -hex 32 > ./jwt/mainnet/jwt.hex
    echo "✓ Generated JWT secret for mainnet: ./jwt/mainnet/jwt.hex"
else
    echo "✓ JWT secret for mainnet already exists"
fi

# Generate JWT secret for sepolia (if it doesn't exist)
if [ ! -f ./jwt/sepolia/jwt.hex ]; then
    openssl rand -hex 32 > ./jwt/sepolia/jwt.hex
    echo "✓ Generated JWT secret for sepolia: ./jwt/sepolia/jwt.hex"
else
    echo "✓ JWT secret for sepolia already exists"
fi

# Set proper permissions
chmod 644 ./jwt/mainnet/jwt.hex
chmod 644 ./jwt/sepolia/jwt.hex

echo ""
echo "JWT secrets ready for use!"
