# Lightweight Geth Monitoring Setup

This directory contains a lightweight Geth (Go Ethereum) setup optimized for monitoring blockchain networks. It includes configurations for both Ethereum Mainnet and Sepolia Testnet with built-in monitoring via Prometheus and Grafana.

## Features

- **Lightweight Configuration**: Uses snap sync mode and pruning to minimize disk usage
- **Dual Network Support**: Ethereum Mainnet and Sepolia Testnet
- **Full RPC Access**: HTTP and WebSocket RPC endpoints
- **Built-in Monitoring**: Prometheus metrics and Grafana dashboards
- **Low Resource Usage**: Optimized cache sizes and peer limits
- **Docker-based**: Easy deployment and management

## Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Geth Mainnet   │────▶│   Prometheus    │
│   (Port 8545)   │     │   (Port 9091)   │
└─────────────────┘     └─────────────────┘
                               │
┌─────────────────┐            │
│  Geth Sepolia   │────────────┤
│   (Port 8547)   │            │
└─────────────────┘            ▼
                        ┌─────────────────┐
                        │    Grafana      │
                        │   (Port 3001)   │
                        └─────────────────┘
```

## Directory Structure

```
geth/
├── docker-compose.yml           # Main Docker Compose configuration
├── prometheus.yml               # Prometheus scraping configuration
├── grafana/
│   ├── datasources/
│   │   └── prometheus.yml      # Grafana datasource config
│   └── dashboards/
│       ├── dashboards.yml      # Dashboard provisioning config
│       └── geth-monitoring.json # Main monitoring dashboard
└── README.md                    # This file
```

## Quick Start

### 1. Start All Services

```bash
cd geth
docker-compose up -d
```

This will start:
- Geth Mainnet node (syncing in background)
- Geth Sepolia node (syncing in background)
- Prometheus (collecting metrics)
- Grafana (visualizing metrics)

### 2. Start Only Geth Nodes (No Monitoring)

```bash
docker-compose up -d geth-mainnet geth-sepolia
```

### 3. Start Specific Network

```bash
# Only Mainnet
docker-compose up -d geth-mainnet

# Only Sepolia
docker-compose up -d geth-sepolia
```

## RPC Endpoints

### Ethereum Mainnet
- **HTTP RPC**: `http://localhost:8545`
- **WebSocket**: `ws://localhost:8546`
- **Metrics**: `http://localhost:6060/debug/metrics`

### Sepolia Testnet
- **HTTP RPC**: `http://localhost:8547`
- **WebSocket**: `ws://localhost:8548`
- **Metrics**: `http://localhost:6060/debug/metrics`

### Example RPC Calls

```bash
# Get current block number (Mainnet)
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8545

# Get current block number (Sepolia)
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://localhost:8547

# Check sync status
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://localhost:8545
```

## Monitoring

### Grafana Dashboard
Access Grafana at: `http://localhost:3001`
- **Username**: `admin`
- **Password**: `admin`

The dashboard includes:
- Block height for both networks
- Peer count
- Block processing rate
- Transaction pool status
- Memory usage
- Goroutine count

### Prometheus
Access Prometheus at: `http://localhost:9091`

Available metrics:
- `chain_head_block` - Current block height
- `p2p_peers` - Number of connected peers
- `txpool_pending` - Pending transactions
- `txpool_queued` - Queued transactions
- `go_memstats_alloc_bytes` - Memory allocation

## Configuration Details

### Sync Mode: Snap Sync
- **Fast Initial Sync**: Downloads state snapshots instead of processing all blocks
- **Reduced Storage**: Only recent state is kept, old state is pruned
- **Sync Time**:
  - Mainnet: ~6-12 hours (depending on hardware)
  - Sepolia: ~1-2 hours

### Garbage Collection Mode: Full
- **Pruning Enabled**: Old state data is automatically pruned
- **Storage Savings**: ~70% less storage compared to archive mode
- **Storage Requirements**:
  - Mainnet: ~800GB-1TB (and growing)
  - Sepolia: ~50GB-100GB

### Cache Settings
- **Mainnet**: 2048 MB cache
- **Sepolia**: 1024 MB cache

### Peer Limits
- **Max Peers**: 25 (reduced from default 50 to save bandwidth)

### Transaction Lookup Limit
- **Value**: 10,000 blocks
- **Purpose**: Only keep transaction indices for recent blocks to save disk space

## Monitoring Sync Progress

### Check Sync Status
```bash
# Mainnet
docker exec -it geth-mainnet-monitor geth attach --exec "eth.syncing"

# Sepolia
docker exec -it geth-sepolia-monitor geth attach --exec "eth.syncing"
```

If syncing, you'll see output like:
```javascript
{
  currentBlock: 18500000,
  highestBlock: 18600000,
  startingBlock: 18400000
}
```

If fully synced:
```javascript
false
```

### Check Peer Count
```bash
# Mainnet
docker exec -it geth-mainnet-monitor geth attach --exec "net.peerCount"

# Sepolia
docker exec -it geth-sepolia-monitor geth attach --exec "net.peerCount"
```

### View Logs
```bash
# Mainnet logs
docker logs -f geth-mainnet-monitor

# Sepolia logs
docker logs -f geth-sepolia-monitor
```

## Resource Requirements

### Minimum Hardware
- **CPU**: 4 cores
- **RAM**: 8 GB (16 GB recommended)
- **Storage**: 1 TB SSD (NVMe recommended for better performance)
- **Network**: 25 Mbps download, 10 Mbps upload

### Recommended Hardware
- **CPU**: 8+ cores
- **RAM**: 16 GB+
- **Storage**: 2 TB NVMe SSD
- **Network**: 100 Mbps symmetrical

## Integration with Your Application

Update your `seed_evm_networks.go` RPC URLs to use local Geth:

```go
// Ethereum Mainnet
{
    Network:  "ethereum",
    RPCURL:   "http://localhost:8545",
    WSRPCUrl: strPtr("ws://localhost:8546"),
    // ... other fields
},

// Ethereum Sepolia Testnet
{
    Network:  "sepolia",
    RPCURL:   "http://localhost:8547",
    WSRPCUrl: strPtr("ws://localhost:8548"),
    // ... other fields
},
```

## Management Commands

### Stop All Services
```bash
docker-compose down
```

### Stop Services and Remove Volumes (CAUTION: Deletes blockchain data)
```bash
docker-compose down -v
```

### Restart a Service
```bash
docker-compose restart geth-mainnet
```

### View Resource Usage
```bash
docker stats geth-mainnet-monitor geth-sepolia-monitor
```

### Update Geth to Latest Version
```bash
docker-compose pull
docker-compose up -d
```

## Troubleshooting

### Node Not Syncing
1. Check peer count: Should be > 5
2. Check firewall: Ensure ports 30303 and 30304 are open
3. Check logs for errors: `docker logs geth-mainnet-monitor`

### High Memory Usage
- Reduce cache size in docker-compose.yml
- Reduce maxpeers to 10-15

### Slow Sync Speed
- Ensure you have a fast internet connection
- Use NVMe SSD storage
- Increase cache size if you have more RAM

### RPC Connection Errors
- Ensure the node is running: `docker ps`
- Check if sync is complete: Syncing nodes may timeout on some RPC calls
- Verify firewall settings

## Security Considerations

### Production Deployment
For production use, you should:

1. **Restrict RPC Access**: Don't expose RPC ports to the internet
   ```yaml
   ports:
     - "127.0.0.1:8545:8545"  # Only localhost
   ```

2. **Use Authentication**: Add JWT authentication for RPC
3. **Enable Firewall**: Only allow necessary ports
4. **Use Reverse Proxy**: Put nginx/traefik in front
5. **Monitor Metrics**: Set up alerts for sync issues

### Network Security
```yaml
# Add to docker-compose.yml under geth services
command: >
  ...
  --http.addr 127.0.0.1  # Only allow local connections
  --ws.addr 127.0.0.1
  --http.api eth,net,web3  # Remove txpool from production
```

## Backup and Restore

### Backup Geth Data
```bash
# Stop the node first
docker-compose stop geth-mainnet

# Backup the volume
docker run --rm -v geth_geth-mainnet-data:/data -v $(pwd)/backup:/backup \
  alpine tar czf /backup/geth-mainnet-backup.tar.gz -C /data .

# Start the node
docker-compose start geth-mainnet
```

### Restore from Backup
```bash
# Stop and remove existing node
docker-compose stop geth-mainnet
docker volume rm geth_geth-mainnet-data

# Create new volume
docker volume create geth_geth-mainnet-data

# Restore data
docker run --rm -v geth_geth-mainnet-data:/data -v $(pwd)/backup:/backup \
  alpine tar xzf /backup/geth-mainnet-backup.tar.gz -C /data

# Start the node
docker-compose start geth-mainnet
```

## Cost Comparison

### Running Your Own Node
- **Pros**:
  - No rate limits
  - Full control
  - Privacy (your queries aren't tracked)
  - No monthly fees
- **Cons**:
  - Initial setup time
  - Hardware/hosting costs
  - Maintenance required
  - Storage requirements

### Using Third-party RPC (like dRPC)
- **Pros**:
  - Instant availability
  - No maintenance
  - Scalable
- **Cons**:
  - Rate limits
  - Monthly costs can be high
  - Privacy concerns
  - Potential downtime

## Next Steps

1. Wait for initial sync to complete
2. Update your application's RPC URLs
3. Set up monitoring alerts in Grafana
4. Configure backups
5. Consider running a load balancer between your own nodes and third-party RPCs for redundancy

## Support

For Geth-specific issues, visit:
- Geth Documentation: https://geth.ethereum.org/docs
- Geth GitHub: https://github.com/ethereum/go-ethereum
- Ethereum Stack Exchange: https://ethereum.stackexchange.com

For monitoring issues:
- Prometheus Docs: https://prometheus.io/docs
- Grafana Docs: https://grafana.com/docs
