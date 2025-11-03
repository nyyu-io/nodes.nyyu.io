# Solana Node Monitoring Infrastructure

Complete Docker-based monitoring solution for Solana RPC nodes with Prometheus and Grafana.

## Overview

This setup provides:
- **Solana Mainnet-beta** RPC node (non-validating)
- **Solana Devnet** RPC node for testing
- **Prometheus** for metrics collection
- **Grafana** for visualization and monitoring
- **Optional Nginx** reverse proxy with SSL/HTTPS support

## Quick Start

### Local Deployment

1. Start all services:
```bash
./sol-manager.sh start
```

2. Access the services:
- Solana Mainnet RPC: http://localhost:8899
- Solana Devnet RPC: http://localhost:8898
- Grafana Dashboard: http://localhost:3005 (admin/admin)
- Prometheus: http://localhost:9095

3. Check sync status:
```bash
./sol-manager.sh sync
```

### Azure Deployment

Deploy to Azure with one command:
```bash
./deploy-to-azure-sol.sh
```

The script will guide you through:
- Server configuration
- SSL setup (Let's Encrypt, Cloudflare, or existing certs)
- Automated deployment

## Architecture

### Mainnet Node
- **Network**: Mainnet-beta
- **Type**: RPC Node (non-validating)
- **RPC Port**: 8899
- **WebSocket Port**: 8900
- **Storage**: ~200GB (with snapshot, grows over time)
- **RAM**: 128GB+ recommended (64GB minimum)
- **CPU**: 12+ cores recommended

### Devnet Node
- **Network**: Devnet
- **Type**: RPC Node (non-validating)
- **RPC Port**: 8898
- **WebSocket Port**: 8901
- **Storage**: ~50GB
- **RAM**: 32GB+ recommended
- **CPU**: 8+ cores recommended

### Monitoring Stack
- **Prometheus**: Scrapes metrics from Solana nodes
- **Grafana**: Pre-configured dashboards for visualization
- **Node Exporter**: System metrics (optional)

## Configuration Files

### Mainnet Configuration
`config/mainnet/validator.sh` - Mainnet RPC node startup script
- Connected to Mainnet-beta cluster
- Configured for optimal RPC performance
- Snapshot download enabled for faster sync

### Devnet Configuration
`config/devnet/validator.sh` - Devnet RPC node startup script
- Connected to Devnet cluster
- Lighter resource requirements
- Ideal for testing and development

## Management Commands

The `sol-manager.sh` script provides easy management:

```bash
# Start all services
./sol-manager.sh start

# Start only Solana nodes (no monitoring)
./sol-manager.sh start-nodes

# Stop all services
./sol-manager.sh stop

# View service status
./sol-manager.sh status

# Check sync status
./sol-manager.sh sync

# Check slot height
./sol-manager.sh slots

# View logs
./sol-manager.sh logs mainnet
./sol-manager.sh logs devnet

# Check resource usage
./sol-manager.sh resources

# Test RPC endpoints
./sol-manager.sh test-rpc

# Show validator info
./sol-manager.sh info mainnet
```

## API Examples

### Get Slot Height
```bash
curl -X POST http://localhost:8899 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getSlot"}'
```

### Get Recent Blockhash
```bash
curl -X POST http://localhost:8899 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getRecentBlockhash"}'
```

### Get Version
```bash
curl -X POST http://localhost:8899 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getVersion"}'
```

### Get Epoch Info
```bash
curl -X POST http://localhost:8899 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getEpochInfo"}'
```

### Get Health
```bash
curl -X POST http://localhost:8899 \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"getHealth"}'
```

## Storage Requirements

### Mainnet
- **Initial sync**: Downloads ~150GB snapshot
- **Growing ledger**: ~200GB total (increases over time)
- **Accounts DB**: ~100GB
- **Recommend**: 500GB+ SSD for future growth

### Devnet
- **Initial sync**: Downloads ~30GB snapshot
- **Total storage**: ~50GB
- **Recommend**: 100GB SSD

## Network Requirements

### Ports to Open
- **8899**: Mainnet RPC (HTTP)
- **8900**: Mainnet WebSocket
- **8898**: Devnet RPC (HTTP)
- **8901**: Devnet WebSocket
- **8001-8012**: Gossip and other P2P (TCP/UDP)

### Bandwidth
- **Mainnet**: 300 Mbps+ recommended
- **Devnet**: 100 Mbps+ recommended
- High bandwidth is crucial for keeping up with the network

## Sync Time

### Mainnet
- **With snapshot**: 2-6 hours (depending on bandwidth and CPU)
- **Without snapshot**: Not recommended (would take days)
- Node automatically downloads latest snapshot on first start

### Devnet
- **With snapshot**: 30 minutes - 2 hours
- Faster sync due to smaller chain size

## Monitoring & Metrics

### Grafana Dashboards
Access Grafana at `http://localhost:3005` (or your configured domain)

Default credentials:
- Username: `admin`
- Password: `admin` (change on first login)

### Key Metrics to Monitor
- Slot height and sync status
- Transaction throughput
- RPC request latency
- CPU and memory usage
- Disk I/O and space
- Network bandwidth

## Troubleshooting

### Node not syncing
```bash
# Check if node is running
./sol-manager.sh status

# Check logs for errors
./sol-manager.sh logs mainnet

# Verify RPC is responding
./sol-manager.sh test-rpc
```

### Out of disk space
Solana ledger grows continuously. Solutions:
1. Increase disk size
2. Configure ledger pruning (limit ledger size)
3. Monitor and clean old snapshots

### High CPU/Memory usage
RPC nodes are resource-intensive:
1. Ensure minimum requirements are met
2. Limit RPC traffic if needed
3. Consider using a dedicated server

### Slot falling behind
Node can't keep up with the network:
1. Check CPU usage (may be maxed out)
2. Verify network bandwidth
3. Check disk I/O performance
4. May need better hardware

## SSL/HTTPS Configuration

### Option 1: Let's Encrypt (Automatic)
```bash
./deploy-to-azure-sol.sh
# Select option 1 for SSL
# Provide domain and email
```

### Option 2: Cloudflare
```bash
./deploy-to-azure-sol.sh
# Select option 2 for SSL
# Provide Cloudflare API token and zone ID
```

### Option 3: Existing Certificates
```bash
./deploy-to-azure-sol.sh
# Select option 3 for SSL
# Provide paths to fullchain.pem and privkey.pem
```

## Hardware Recommendations

### Production Mainnet Node
- **CPU**: AMD Ryzen 5950X or Intel Xeon (16+ cores)
- **RAM**: 256GB (128GB minimum)
- **Storage**: 1TB+ NVMe SSD
- **Network**: 1 Gbps dedicated
- **OS**: Ubuntu 22.04 LTS

### Development/Devnet Node
- **CPU**: 8+ cores
- **RAM**: 64GB (32GB minimum)
- **Storage**: 250GB SSD
- **Network**: 300 Mbps
- **OS**: Ubuntu 22.04 LTS

## Security Best Practices

1. **Firewall**: Only expose necessary ports (8899, 8898)
2. **Rate Limiting**: Implement rate limits on RPC endpoints
3. **Authentication**: Add authentication for public RPC access
4. **SSL/TLS**: Always use HTTPS for production
5. **Updates**: Keep Solana version updated
6. **Monitoring**: Set up alerts for anomalies
7. **Backup**: Regular backup of validator identity (if applicable)

## Performance Tuning

### Optimize RPC Performance
Edit `config/mainnet/validator.sh`:
```bash
# Increase RPC thread count
--rpc-threads 16

# Enable RPC transaction history
--enable-rpc-transaction-history

# Limit account index (reduces memory)
--account-index program-id
```

### Limit Ledger Size
```bash
# Keep only recent ledger data
--limit-ledger-size 200000000  # ~200GB
```

## Cost Estimates

### Azure VM Recommendations
- **Mainnet**: Standard_E16s_v4 (16 vCPU, 128GB RAM) - ~$1,200/month
- **Devnet**: Standard_E8s_v4 (8 vCPU, 64GB RAM) - ~$600/month
- **Storage**: Premium SSD 1TB - ~$150/month

### AWS EC2 Recommendations
- **Mainnet**: r6i.4xlarge (16 vCPU, 128GB RAM) - ~$1,100/month
- **Devnet**: r6i.2xlarge (8 vCPU, 64GB RAM) - ~$550/month
- **Storage**: gp3 1TB - ~$100/month

## Backup & Recovery

### Important Data to Backup
- Node configuration files
- Prometheus data (optional)
- Grafana dashboards (optional)

### Disaster Recovery
Solana RPC nodes can be rebuilt from scratch using snapshots. No critical data loss if node fails - just re-sync from network.

## Updates

### Update Solana Version
```bash
# Edit docker-compose.yml
# Change image version: solanalabs/solana:v1.18.x

# Pull new image
docker compose pull

# Restart services
docker compose restart
```

## Support & Resources

- Solana Documentation: https://docs.solana.com/
- Solana Discord: https://discord.gg/solana
- RPC API Reference: https://docs.solana.com/api
- Validator Guide: https://docs.solana.com/running-validator

## License

This monitoring infrastructure is provided as-is for educational and development purposes.
