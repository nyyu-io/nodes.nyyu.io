# BSC Node Monitoring Setup

Complete setup for running and monitoring BSC (Binance Smart Chain) nodes on Azure with SSL support.

## Features

- **BSC Mainnet** node with RPC and WebSocket endpoints
- **BSC Testnet** node with RPC and WebSocket endpoints
- **Prometheus** metrics collection
- **Grafana** dashboards for visualization
- **Nginx** reverse proxy with SSL/HTTPS support
- Docker-based deployment
- Automated deployment scripts

## Quick Start

### 1. Prerequisites

- Azure VM (recommended: 8 vCPU, 16GB RAM, 1TB SSD)
- SSH key for Azure access
- Domain name (e.g., node-bsc.nyyu.io)
- Docker installed on Azure VM

### 2. Deploy to Azure

```bash
./deploy-to-azure-bsc.sh
```

Follow the prompts to configure:
- Azure server details
- SSL certificates (Let's Encrypt, Cloudflare, or existing)
- Grafana password

### 3. Access Points

After deployment:
- **BSC Mainnet RPC**: https://node-bsc.nyyu.io/mainnet/rpc
- **BSC Mainnet WS**: wss://node-bsc.nyyu.io/mainnet/ws
- **BSC Testnet RPC**: https://node-bsc.nyyu.io/testnet/rpc
- **BSC Testnet WS**: wss://node-bsc.nyyu.io/testnet/ws
- **Grafana**: https://node-bsc.nyyu.io/grafana/
- **Prometheus**: https://node-bsc.nyyu.io/prometheus/

## Management Commands

### Check Status
```bash
ssh -i ./Azure-NYYU.pem azureuser@node-bsc.nyyu.io 'cd /home/azureuser/bsc-monitoring && ./bsc-manager.sh status'
```

### View Logs
```bash
# BSC Mainnet logs
./bsc-manager.sh logs mainnet

# BSC Testnet logs
./bsc-manager.sh logs testnet
```

### Check Sync Progress
```bash
./bsc-manager.sh sync
```

### Check Peer Connections
```bash
./bsc-manager.sh peers
```

### Check Block Height
```bash
./bsc-manager.sh blocks
```

### Test RPC Endpoints
```bash
./bsc-manager.sh test-rpc
```

## Architecture

### BSC Mainnet
- **Ports**: 8575 (RPC), 8576 (WS), 30313 (P2P)
- **Chain ID**: 56
- **Sync Mode**: Snap sync
- **Cache**: 8GB

### BSC Testnet
- **Ports**: 8577 (RPC), 8578 (WS), 30314 (P2P)
- **Chain ID**: 97
- **Sync Mode**: Snap sync
- **Cache**: 4GB

### Monitoring
- **Prometheus**: Port 9092
- **Grafana**: Port 3002
- **Metrics Endpoint**: :6060/debug/metrics/prometheus

## Configuration Files

- `docker-compose.yml` - Container orchestration
- `prometheus.yml` - Metrics collection config
- `grafana/datasources/prometheus.yml` - Grafana datasource
- `config/mainnet/config.toml` - BSC Mainnet config
- `config/testnet/config.toml` - BSC Testnet config

## Sync Time

- **Initial sync**: 4-8 hours for snap sync
- **Disk space**: ~600-800GB for full sync
- **BSC uses PoSA**: No consensus client (Lighthouse) needed

## Troubleshooting

### Check if services are running
```bash
docker ps
```

### View container logs
```bash
docker logs bsc-mainnet-monitor
docker logs bsc-testnet-monitor
```

### Restart services
```bash
docker compose restart
```

### Check disk space
```bash
df -h
```

### Test RPC locally
```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8575
```

## Security Considerations

- RPC endpoints are exposed with CORS enabled for development
- For production, configure firewall rules to restrict access
- Use SSL/HTTPS for all external connections
- Regularly update the BSC client

## Cleanup

To stop services and optionally remove data:
```bash
./cleanup-azure.sh
```

## Testing

To test all endpoints:
```bash
./test-bsc.sh
```

## Support

For issues or questions, check:
- [BSC Documentation](https://docs.bnbchain.org/)
- [BSC GitHub](https://github.com/bnb-chain/bsc)

## License

This setup is provided as-is for monitoring BSC nodes.
