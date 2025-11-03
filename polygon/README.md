# Polygon (MATIC) Node Monitoring Infrastructure

Complete Docker-based monitoring solution for Polygon RPC nodes with Prometheus and Grafana.

## Overview

This setup provides:
- **Polygon Mainnet** RPC node (Bor client)
- **Polygon Mumbai Testnet** RPC node for testing
- **Prometheus** for metrics collection
- **Grafana** for visualization and monitoring
- **Optional Nginx** reverse proxy with SSL/HTTPS support

## Quick Start

### Local Deployment

1. Start all services:
```bash
./polygon-manager.sh start
```

2. Access the services:
- Polygon Mainnet RPC: http://localhost:8545
- Polygon Mumbai RPC: http://localhost:8546
- Grafana Dashboard: http://localhost:3006 (admin/admin)
- Prometheus: http://localhost:9096

3. Check sync status:
```bash
./polygon-manager.sh sync
```

### Azure Deployment

Deploy to Azure with one command:
```bash
./deploy-to-azure-polygon.sh
```

The script will guide you through:
- Server configuration
- SSL setup (Let's Encrypt, Cloudflare, or existing certs)
- Automated deployment

## Architecture

### Mainnet Node (Bor)
- **Network**: Polygon Mainnet
- **Chain ID**: 137
- **Type**: Full Node (pruned)
- **RPC Port**: 8545
- **WebSocket Port**: 8546
- **Storage**: ~500GB (pruned), ~2TB (archive)
- **RAM**: 16GB+ recommended
- **CPU**: 8+ cores recommended

### Mumbai Testnet Node
- **Network**: Mumbai Testnet
- **Chain ID**: 80001
- **Type**: Full Node (pruned)
- **RPC Port**: 8546 (mapped to 8547 on host)
- **WebSocket Port**: 8547 (mapped to 8548 on host)
- **Storage**: ~200GB
- **RAM**: 8GB+ recommended
- **CPU**: 4+ cores recommended

### Monitoring Stack
- **Prometheus**: Scrapes metrics from Polygon nodes
- **Grafana**: Pre-configured dashboards for visualization
- **Node Exporter**: System metrics (optional)

## Configuration Files

### Mainnet Configuration
`config/mainnet/config.toml` - Mainnet Bor node configuration
- Optimized for RPC performance
- Snap sync enabled for faster initial sync
- Pruning enabled to reduce storage

### Mumbai Configuration
`config/mumbai/config.toml` - Mumbai testnet Bor node configuration
- Lighter resource requirements
- Ideal for testing and development

## Management Commands

The `polygon-manager.sh` script provides easy management:

```bash
# Start all services
./polygon-manager.sh start

# Start only Polygon nodes (no monitoring)
./polygon-manager.sh start-nodes

# Stop all services
./polygon-manager.sh stop

# View service status
./polygon-manager.sh status

# Check sync status
./polygon-manager.sh sync

# Check block height
./polygon-manager.sh blocks

# View logs
./polygon-manager.sh logs mainnet
./polygon-manager.sh logs mumbai

# Check resource usage
./polygon-manager.sh resources

# Test RPC endpoints
./polygon-manager.sh test-rpc

# Check peer count
./polygon-manager.sh peers
```

## API Examples

### Get Latest Block Number
```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}'
```

### Get Network Version
```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"net_version","params":[],"id":1}'
```

### Get Balance
```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_getBalance","params":["0x742d35Cc6634C0532925a3b844Bc9e7595f0bEb","latest"],"id":1}'
```

### Get Gas Price
```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_gasPrice","params":[],"id":1}'
```

### Get Chain ID
```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}'
```

### Check Syncing Status
```bash
curl -X POST http://localhost:8545 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'
```

## Storage Requirements

### Mainnet
- **Pruned node**: ~500GB (recommended)
- **Archive node**: ~2TB+
- **Growth rate**: ~50GB/month
- **Recommend**: 1TB SSD minimum

### Mumbai Testnet
- **Pruned node**: ~200GB
- **Archive node**: ~500GB
- **Recommend**: 500GB SSD

## Network Requirements

### Ports to Open
- **8545**: Mainnet RPC (HTTP)
- **8546**: Mainnet WebSocket / Mumbai RPC
- **8547**: Mumbai WebSocket
- **30303**: P2P (TCP/UDP) - Mainnet
- **30304**: P2P (TCP/UDP) - Mumbai

### Bandwidth
- **Mainnet**: 200 Mbps+ recommended
- **Mumbai**: 100 Mbps+ recommended

## Sync Time

### Mainnet
- **Snap sync (pruned)**: 4-8 hours (depending on hardware and network)
- **Full sync**: 12-24 hours
- **Archive sync**: Several days

### Mumbai Testnet
- **Snap sync**: 1-3 hours
- **Full sync**: 3-6 hours

## Monitoring & Metrics

### Grafana Dashboards
Access Grafana at `http://localhost:3006` (or your configured domain)

Default credentials:
- Username: `admin`
- Password: `admin` (change on first login)

### Key Metrics to Monitor
- Block height and sync status
- Peer count
- Transaction pool size
- RPC request rate
- CPU and memory usage
- Disk I/O and space
- Network bandwidth

## Troubleshooting

### Node not syncing
```bash
# Check if node is running
./polygon-manager.sh status

# Check logs for errors
./polygon-manager.sh logs mainnet

# Verify RPC is responding
./polygon-manager.sh test-rpc

# Check peer count
./polygon-manager.sh peers
```

### Out of disk space
```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -a

# Consider switching to pruned mode or increasing disk size
```

### Sync is very slow
Possible causes:
1. Slow disk I/O (use SSD/NVMe)
2. Insufficient CPU/RAM
3. Network bandwidth limitations
4. Many peers disconnecting

Solutions:
- Use snap sync (enabled by default)
- Increase `--cache` parameter
- Ensure fast storage

### High CPU/Memory usage
This is normal during initial sync. After sync:
- Average CPU: 20-40%
- Average RAM: 8-16GB

If consistently higher:
- Check for many RPC requests
- Verify no runaway processes
- Consider upgrading hardware

## SSL/HTTPS Configuration

### Option 1: Let's Encrypt (Automatic)
```bash
./deploy-to-azure-polygon.sh
# Select option 1 for SSL
# Provide domain and email
```

### Option 2: Cloudflare
```bash
./deploy-to-azure-polygon.sh
# Select option 2 for SSL
# Provide Cloudflare API token and zone ID
```

### Option 3: Existing Certificates
```bash
./deploy-to-azure-polygon.sh
# Select option 3 for SSL
# Provide paths to fullchain.pem and privkey.pem
```

## Hardware Recommendations

### Production Mainnet Node
- **CPU**: 8+ cores (16+ for archive)
- **RAM**: 32GB (64GB+ for archive)
- **Storage**: 1TB NVMe SSD (2TB+ for archive)
- **Network**: 500 Mbps dedicated
- **OS**: Ubuntu 22.04 LTS

### Development/Mumbai Node
- **CPU**: 4+ cores
- **RAM**: 16GB
- **Storage**: 500GB SSD
- **Network**: 200 Mbps
- **OS**: Ubuntu 22.04 LTS

## Polygon vs Ethereum Differences

- **Block time**: ~2 seconds (vs 12 seconds for Ethereum)
- **Gas costs**: Much lower than Ethereum mainnet
- **Consensus**: Proof of Stake (PoS)
- **Architecture**: Uses Bor (execution) + Heimdall (consensus)
- **Storage**: Smaller than Ethereum (~500GB vs ~1TB+ for pruned)
- **Compatibility**: Fully EVM compatible

## Security Best Practices

1. **Firewall**: Only expose necessary ports (8545, 8546)
2. **Rate Limiting**: Implement rate limits on RPC endpoints
3. **Authentication**: Add authentication for public RPC access
4. **SSL/TLS**: Always use HTTPS for production
5. **Updates**: Keep Bor client updated
6. **Monitoring**: Set up alerts for anomalies
7. **CORS**: Configure CORS properly for RPC access

## Performance Tuning

### Optimize RPC Performance
Edit `config/mainnet/config.toml`:
```toml
[jsonrpc]
  [jsonrpc.http]
    enabled = true
    port = 8545
    host = "0.0.0.0"
    api = ["eth", "net", "web3", "txpool", "bor"]
    vhosts = ["*"]
    corsdomain = ["*"]

[cache]
  cache = 8192  # Increase for better performance
  gc = 50
```

### Database Optimization
```toml
[database]
  ancient = "/polygon/ancient"  # Separate ancient data
```

## Cost Estimates

### Azure VM Recommendations
- **Mainnet**: Standard_D8s_v4 (8 vCPU, 32GB RAM) - ~$350/month
- **Mumbai**: Standard_D4s_v4 (4 vCPU, 16GB RAM) - ~$175/month
- **Storage**: Premium SSD 1TB - ~$150/month

### AWS EC2 Recommendations
- **Mainnet**: m6i.2xlarge (8 vCPU, 32GB RAM) - ~$330/month
- **Mumbai**: m6i.xlarge (4 vCPU, 16GB RAM) - ~$165/month
- **Storage**: gp3 1TB - ~$100/month

## Backup & Recovery

### Important Data to Backup
- Node configuration files
- Prometheus data (optional)
- Grafana dashboards (optional)

### Disaster Recovery
Polygon nodes can be rebuilt from scratch relatively quickly using snap sync. No critical data loss if node fails.

## Updates

### Update Bor Version
```bash
# Edit docker-compose.yml
# Change image version: 0xpolygon/bor:v1.x.x

# Pull new image
docker compose pull

# Restart services
docker compose restart
```

## Useful Resources

- Polygon Documentation: https://docs.polygon.technology/
- Polygon Discord: https://discord.gg/polygon
- JSON-RPC API: https://docs.polygon.technology/api/
- Bor GitHub: https://github.com/maticnetwork/bor
- Network Stats: https://polygonscan.com/

## Common Use Cases

### DeFi Applications
- Token swaps and trading
- Lending/borrowing protocols
- Yield farming

### NFT Platforms
- Minting and trading NFTs
- Gaming items
- Digital collectibles

### dApp Development
- Deploy and test smart contracts
- Build Web3 applications
- Integrate with wallets

## License

This monitoring infrastructure is provided as-is for educational and development purposes.
