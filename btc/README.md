# Bitcoin Node Monitoring Setup

Complete setup for running and monitoring Bitcoin Core nodes on Azure with SSL support.

## Features

- **Bitcoin Mainnet** node with RPC endpoints
- **Bitcoin Testnet** node with RPC endpoints
- **Prometheus** metrics collection via Bitcoin exporter
- **Grafana** dashboards for visualization
- **Nginx** reverse proxy with SSL/HTTPS support
- Docker-based deployment
- Automated deployment scripts
- ZMQ notifications for real-time updates

## Quick Start

### 1. Prerequisites

- Azure VM (recommended: 8 vCPU, 16GB RAM, 1TB SSD for pruned, 2TB for full node)
- SSH key for Azure access
- Domain name (e.g., node-btc.nyyu.io)
- Docker installed on Azure VM

### 2. Deploy to Azure

```bash
./deploy-to-azure-btc.sh
```

Follow the prompts to configure:
- Azure server details
- Node type (pruned or full)
- SSL certificates (Let's Encrypt, Cloudflare, or existing)
- RPC authentication credentials
- Grafana password

### 3. Access Points

After deployment:
- **Bitcoin Mainnet RPC**: https://node-btc.nyyu.io/mainnet/rpc
- **Bitcoin Testnet RPC**: https://node-btc.nyyu.io/testnet/rpc
- **Grafana**: https://node-btc.nyyu.io/grafana/
- **Prometheus**: https://node-btc.nyyu.io/prometheus/

## Management Commands

### Check Status
```bash
ssh -i ./Azure-NYYU.pem azureuser@node-btc.nyyu.io 'cd /home/azureuser/btc-monitoring && ./btc-manager.sh status'
```

### View Logs
```bash
# Bitcoin Mainnet logs
./btc-manager.sh logs mainnet

# Bitcoin Testnet logs
./btc-manager.sh logs testnet
```

### Check Sync Progress
```bash
./btc-manager.sh sync
```

### Check Peer Connections
```bash
./btc-manager.sh peers
```

### Check Block Height
```bash
./btc-manager.sh blocks
```

### Test RPC Endpoints
```bash
./btc-manager.sh test-rpc
```

### Get Blockchain Info
```bash
./btc-manager.sh info
```

## Architecture

### Bitcoin Mainnet
- **Ports**: 8332 (RPC), 8333 (P2P), 28332 (ZMQ)
- **Network**: mainnet
- **Pruning**: Configurable (pruned: ~100GB, full: ~600GB+)
- **Cache**: 4GB

### Bitcoin Testnet
- **Ports**: 18332 (RPC), 18333 (P2P), 28333 (ZMQ)
- **Network**: testnet3
- **Pruning**: Configurable (pruned: ~30GB, full: ~50GB+)
- **Cache**: 2GB

### Monitoring
- **Prometheus**: Port 9093
- **Grafana**: Port 3003
- **Bitcoin Exporter**: Ports 9332 (mainnet), 9333 (testnet)

## Configuration Files

- `docker-compose.yml` - Container orchestration
- `prometheus.yml` - Metrics collection config
- `grafana/datasources/prometheus.yml` - Grafana datasource
- `config/mainnet/bitcoin.conf` - Bitcoin Mainnet config
- `config/testnet/bitcoin.conf` - Bitcoin Testnet config

## Sync Time

### Initial Block Download (IBD)
- **Pruned node**: 12-24 hours (downloads all blocks, keeps only recent)
- **Full node**: 3-7 days (stores entire blockchain history)
- **Testnet**: 2-6 hours

### Disk Space Requirements
- **Mainnet Pruned**: ~100-150GB
- **Mainnet Full**: ~600GB+ (and growing)
- **Testnet Pruned**: ~30GB
- **Testnet Full**: ~50GB

## RPC Commands

### Using curl
```bash
# Get blockchain info
curl --user rpcuser:rpcpassword --data-binary '{"jsonrpc":"1.0","id":"1","method":"getblockchaininfo","params":[]}' \
  -H 'content-type: text/plain;' https://node-btc.nyyu.io/mainnet/rpc

# Get block count
curl --user rpcuser:rpcpassword --data-binary '{"jsonrpc":"1.0","id":"1","method":"getblockcount","params":[]}' \
  -H 'content-type: text/plain;' https://node-btc.nyyu.io/mainnet/rpc

# Get network info
curl --user rpcuser:rpcpassword --data-binary '{"jsonrpc":"1.0","id":"1","method":"getnetworkinfo","params":[]}' \
  -H 'content-type: text/plain;' https://node-btc.nyyu.io/mainnet/rpc
```

### Using bitcoin-cli
```bash
# Inside container
docker exec btc-mainnet-monitor bitcoin-cli -conf=/etc/bitcoin/bitcoin.conf getblockchaininfo
docker exec btc-mainnet-monitor bitcoin-cli -conf=/etc/bitcoin/bitcoin.conf getpeerinfo
docker exec btc-mainnet-monitor bitcoin-cli -conf=/etc/bitcoin/bitcoin.conf getmempoolinfo
```

## Troubleshooting

### Check if services are running
```bash
docker ps
```

### View container logs
```bash
docker logs btc-mainnet-monitor
docker logs btc-testnet-monitor
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
curl --user rpcuser:rpcpassword --data-binary '{"jsonrpc":"1.0","id":"1","method":"getblockcount","params":[]}' \
  -H 'content-type: text/plain;' http://localhost:8332
```

### Low peer count
- Check firewall allows ports 8333 and 18333
- Verify Azure NSG settings
- Check Bitcoin Core logs for connection errors

### Slow sync
- Ensure fast internet connection (25+ Mbps)
- Use SSD/NVMe storage (HDD is too slow)
- Increase dbcache if more RAM available
- Check if ISP is blocking P2P ports

## Security Considerations

### Production Deployment
For production use:

1. **Use strong RPC credentials**: Change default username/password
2. **Restrict RPC access**: Don't expose RPC to internet without authentication
3. **Use SSL/HTTPS**: Always use encrypted connections
4. **Whitelist RPC methods**: Disable wallet RPC if not needed
5. **Regular updates**: Keep Bitcoin Core updated

### Network Security
```conf
# In bitcoin.conf
rpcbind=127.0.0.1          # Only bind to localhost
rpcallowip=127.0.0.1       # Only allow local connections
```

## Pruned vs Full Node

### Pruned Node (Recommended for most users)
- **Pros**: Less disk space (~100GB vs 600GB+)
- **Cons**: Cannot serve full blockchain history to other nodes
- **Use case**: Running RPC endpoints, monitoring blockchain

### Full Node
- **Pros**: Complete blockchain history, can serve data to other nodes
- **Cons**: Large disk space requirement, longer sync time
- **Use case**: Blockchain explorers, historical data analysis

To switch between modes, modify `config/mainnet/bitcoin.conf`:
```conf
# For pruned node (keeps ~100GB)
prune=100000

# For full node (comment out prune)
# prune=100000
```

## Monitoring Features

The Grafana dashboard includes:
- Block height and sync progress
- Peer connections count
- Memory pool size and transactions
- Network traffic (incoming/outgoing)
- CPU and memory usage
- Blockchain size
- Verification progress
- Average block time

## Cleanup

To stop services and optionally remove data:
```bash
./cleanup-azure.sh
```

## Testing

To test all endpoints:
```bash
./test-btc.sh
```

## Integration Example

Update your application to use the Bitcoin RPC endpoints:

```javascript
// Node.js example with axios
const axios = require('axios');

const btcRpc = axios.create({
  baseURL: 'https://node-btc.nyyu.io/mainnet/rpc',
  auth: {
    username: 'rpcuser',
    password: 'rpcpassword'
  },
  headers: {
    'Content-Type': 'text/plain'
  }
});

async function getBlockHeight() {
  const response = await btcRpc.post('', {
    jsonrpc: '1.0',
    id: '1',
    method: 'getblockcount',
    params: []
  });
  return response.data.result;
}
```

```python
# Python example with requests
import requests
from requests.auth import HTTPBasicAuth

def get_block_height():
    url = 'https://node-btc.nyyu.io/mainnet/rpc'
    auth = HTTPBasicAuth('rpcuser', 'rpcpassword')
    payload = {
        'jsonrpc': '1.0',
        'id': '1',
        'method': 'getblockcount',
        'params': []
    }
    response = requests.post(url, json=payload, auth=auth)
    return response.json()['result']
```

## Support

For Bitcoin Core specific issues, visit:
- [Bitcoin Core Documentation](https://bitcoin.org/en/bitcoin-core/)
- [Bitcoin Core GitHub](https://github.com/bitcoin/bitcoin)
- [Bitcoin Stack Exchange](https://bitcoin.stackexchange.com/)

## License

This setup is provided as-is for monitoring Bitcoin nodes.
