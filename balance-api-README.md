# Ethereum Balance API

A REST API to check Ethereum native and ERC-20 token balances.

## Installation

```bash
cd ~/balance-api
npm install
```

## Run

```bash
npm start
```

The API will start on port 3100.

## API Endpoints

### 1. Health Check
```bash
GET /

curl http://localhost:3100/
```

### 2. Get Native ETH Balance
```bash
GET /:network/balance/:address

# Example - Check ETH balance on Sepolia
curl http://localhost:3100/sepolia/balance/0x7BB7Bb9c681d06F7e188B0F410a34F9e50E4439A
```

**Response:**
```json
{
  "network": "sepolia",
  "address": "0x7BB7Bb9c681d06F7e188B0F410a34F9e50E4439A",
  "balance": {
    "wei": "0",
    "eth": "0"
  },
  "currency": "ETH"
}
```

### 3. Get ERC-20 Token Balance
```bash
GET /:network/token/:tokenAddress/balance/:address

# Example - Check USDT balance on Sepolia
curl http://localhost:3100/sepolia/token/0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0/balance/0x7BB7Bb9c681d06F7e188B0F410a34F9e50E4439A
```

**Response:**
```json
{
  "network": "sepolia",
  "address": "0x7BB7Bb9c681d06F7e188B0F410a34F9e50E4439A",
  "token": {
    "address": "0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0",
    "name": "Tether USD",
    "symbol": "USDT",
    "decimals": 6
  },
  "balance": {
    "raw": "0",
    "formatted": "0.000000"
  }
}
```

### 4. Get Token Info
```bash
GET /:network/token/:tokenAddress/info

# Example - Get USDT token info
curl http://localhost:3100/sepolia/token/0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0/info
```

**Response:**
```json
{
  "network": "sepolia",
  "address": "0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0",
  "name": "Tether USD",
  "symbol": "USDT",
  "decimals": 6,
  "totalSupply": {
    "raw": "1000000000000",
    "formatted": "1000000.000000"
  }
}
```

### 5. Get Multiple Balances (Native + Tokens)
```bash
POST /:network/balances
Content-Type: application/json

{
  "address": "0x7BB7Bb9c681d06F7e188B0F410a34F9e50E4439A",
  "tokens": [
    "0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0"
  ]
}

# Example
curl -X POST http://localhost:3100/sepolia/balances \
  -H "Content-Type: application/json" \
  -d '{"address":"0x7BB7Bb9c681d06F7e188B0F410a34F9e50E4439A","tokens":["0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0"]}'
```

**Response:**
```json
{
  "network": "sepolia",
  "address": "0x7BB7Bb9c681d06F7e188B0F410a34F9e50E4439A",
  "native": {
    "wei": "0",
    "eth": "0"
  },
  "tokens": [
    {
      "address": "0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0",
      "name": "Tether USD",
      "symbol": "USDT",
      "decimals": 6,
      "balance": {
        "raw": "0",
        "formatted": "0.000000"
      }
    }
  ]
}
```

## Supported Networks

- `sepolia` - Sepolia Testnet
- `mainnet` - Ethereum Mainnet

## Environment Variables

Create a `.env` file:

```env
PORT=3100
SEPOLIA_RPC=http://localhost:8547
MAINNET_RPC=http://localhost:8545
```

## Deploy with Docker (Optional)

Create `Dockerfile`:
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3100
CMD ["node", "server.js"]
```

Build and run:
```bash
docker build -t balance-api .
docker run -p 3100:3100 --env-file .env balance-api
```

## Common ERC-20 Tokens on Sepolia

- USDT: `0xaA8E23Fb1079EA71e0a56F48a2aA51851D8433D0`
- USDC: `0x1c7D4B196Cb0C7B01d743Fbc6116a902379C7238`
- DAI: `0x3e622317f8C93f7328350cF0B56d9eD4C620C5d6`

## Common ERC-20 Tokens on Mainnet

- USDT: `0xdAC17F958D2ee523a2206206994597C13D831ec7`
- USDC: `0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48`
- DAI: `0x6B175474E89094C44Da98b954EedeAC495271d0F`
- WETH: `0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2`

## Error Handling

All errors return:
```json
{
  "error": "Error message"
}
```

With appropriate HTTP status codes:
- `400` - Bad Request (invalid address, network, etc.)
- `500` - Server Error
