# Tron Node Monitoring Setup

Complete setup for running and monitoring Tron (TRX) nodes on Azure with SSL support.

## Features

- **Tron Mainnet** node with HTTP API and gRPC endpoints
- **Tron Nile Testnet** node with HTTP API and gRPC endpoints
- **Prometheus** metrics collection via JMX exporter
- **Grafana** dashboards for visualization
- **Nginx** reverse proxy with SSL/HTTPS support
- Docker-based deployment
- Automated deployment scripts

## Quick Start

### 1. Prerequisites

- Azure VM (recommended: 16 vCPU, 32GB RAM, 2TB SSD for full node)
- SSH key for Azure access
- Domain name (e.g., node-tron.nyyu.io)
- Docker installed on Azure VM

### 2. Deploy to Azure

```bash
./deploy-to-azure-tron.sh
```

Follow the prompts to configure:
- Azure server details
- Node type (full or lite)
- SSL certificates (Let's Encrypt, Cloudflare, or existing)
- Grafana password

### 3. Access Points

After deployment:
- **Tron Mainnet HTTP API**: https://node-tron.nyyu.io/mainnet/api
- **Tron Nile HTTP API**: https://node-tron.nyyu.io/nile/api
- **Grafana**: https://node-tron.nyyu.io/grafana/
- **Prometheus**: https://node-tron.nyyu.io/prometheus/

## Management Commands

### Check Status
```bash
ssh -i ./Azure-NYYU.pem azureuser@node-tron.nyyu.io 'cd /home/azureuser/tron-monitoring && ./tron-manager.sh status'
```

### View Logs
```bash
# Tron Mainnet logs
./tron-manager.sh logs mainnet

# Tron Nile logs
./tron-manager.sh logs nile
```

### Check Sync Progress
```bash
./tron-manager.sh sync
```

### Check Block Height
```bash
./tron-manager.sh blocks
```

### Test API Endpoints
```bash
./tron-manager.sh test-api
```

## Architecture

### Tron Mainnet
- **Ports**: 8090 (HTTP API), 50051 (gRPC), 18888 (P2P)
- **Network**: mainnet
- **Storage**: ~1.5TB for full node, ~500GB for lite node
- **Java Heap**: 12GB

### Tron Nile Testnet
- **Ports**: 8091 (HTTP API), 50052 (gRPC), 18889 (P2P)
- **Network**: nile (testnet)
- **Storage**: ~300GB for full node, ~100GB for lite node
- **Java Heap**: 8GB

### Monitoring
- **Prometheus**: Port 9094
- **Grafana**: Port 3004
- **JMX Exporter**: Ports 9100 (mainnet), 9101 (nile)

## Configuration Files

- `docker-compose.yml` - Container orchestration
- `prometheus.yml` - Metrics collection config
- `grafana/datasources/prometheus.yml` - Grafana datasource
- `config/mainnet/config.conf` - Tron Mainnet config
- `config/nile/config.conf` - Tron Nile config

## Sync Time

### Initial Block Download
- **Full node**: 2-4 days (downloads entire blockchain)
- **Lite node**: 6-12 hours (only recent blocks)
- **Nile testnet**: 4-8 hours

### Disk Space Requirements
- **Mainnet Full**: ~1.5TB+ (and growing ~20GB/month)
- **Mainnet Lite**: ~500GB
- **Nile Full**: ~300GB
- **Nile Lite**: ~100GB

## API Endpoints

### HTTP API Examples

```bash
# Get current block
curl https://node-tron.nyyu.io/mainnet/api/wallet/getnowblock

# Get account info
curl -X POST https://node-tron.nyyu.io/mainnet/api/wallet/getaccount \
  -d '{"address":"TRX_ADDRESS_HERE"}'

# Get chain parameters
curl https://node-tron.nyyu.io/mainnet/api/wallet/getchainparameters

# Get block by number
curl -X POST https://node-tron.nyyu.io/mainnet/api/wallet/getblockbynum \
  -d '{"num":1000}'
```

### gRPC Endpoints

```bash
# Using grpcurl (install: brew install grpcurl)
grpcurl -plaintext node-tron.nyyu.io:50051 protocol.Wallet/GetNowBlock
```

## Troubleshooting

### Check if services are running
```bash
docker ps
```

### View container logs
```bash
docker logs tron-mainnet-monitor
docker logs tron-nile-monitor
```

### Restart services
```bash
docker compose restart
```

### Check disk space
```bash
df -h
```

### Test API locally
```bash
curl http://localhost:8090/wallet/getnowblock
```

### Low peer count
- Check firewall allows ports 18888 and 18889
- Verify Azure NSG settings
- Check Tron node logs for connection errors

### Slow sync
- Ensure fast internet connection (100+ Mbps recommended)
- Use SSD/NVMe storage (HDD is too slow)
- Increase Java heap size if more RAM available
- Consider using lite node mode

## Security Considerations

### Production Deployment
For production use:

1. **Restrict API access**: Don't expose API to internet without authentication
2. **Use SSL/HTTPS**: Always use encrypted connections
3. **Firewall rules**: Only allow necessary ports
4. **Rate limiting**: Implement rate limiting on API endpoints
5. **Regular updates**: Keep Tron node updated

### Network Security
```conf
# In config.conf
node.http {
  fullNodeEnable = true
  solidityEnable = true
}

# Restrict RPC
rpc {
  port = 50051
  # Only bind to localhost if behind proxy
}
```

## Full Node vs Lite Node

### Full Node (Recommended for production)
- **Pros**: Complete blockchain history, can validate all transactions
- **Cons**: Large disk space requirement (~1.5TB+), longer sync time
- **Use case**: Blockchain explorers, full API access, historical data

### Lite Node
- **Pros**: Less disk space (~500GB), faster sync
- **Cons**: Limited historical data, may not serve all API queries
- **Use case**: Development, testing, basic API access

To switch between modes, modify `config/mainnet/config.conf`:
```conf
# Full node
storage {
  db.version = 2,
  db.engine = "LEVELDB",
}

# Lite node (prune old data)
storage {
  db.version = 2,
  db.engine = "LEVELDB",
  needToUpdateAsset = true

  properties = [
    {
      name = "block.needSyncCheck"
      value = true
    },
    {
      name = "block.maintenanceTimeInterval"
      value = 21600000
    }
  ]
}
```

## Monitoring Features

The Grafana dashboard includes:
- Block height and sync progress
- Peer connections count
- Transaction pool size
- CPU and memory usage
- JVM metrics (heap, GC)
- API response times
- Network traffic

## Cleanup

To stop services and optionally remove data:
```bash
./cleanup-azure.sh
```

## Testing

To test all endpoints:
```bash
./test-tron.sh
```

## Integration Example

Update your application to use the Tron API endpoints:

```javascript
// Node.js example with axios
const axios = require('axios');

const tronApi = axios.create({
  baseURL: 'https://node-tron.nyyu.io/mainnet/api'
});

async function getCurrentBlock() {
  const response = await tronApi.get('/wallet/getnowblock');
  return response.data;
}

async function getAccount(address) {
  const response = await tronApi.post('/wallet/getaccount', {
    address: address,
    visible: true
  });
  return response.data;
}
```

```python
# Python example with requests
import requests

def get_current_block():
    url = 'https://node-tron.nyyu.io/mainnet/api/wallet/getnowblock'
    response = requests.get(url)
    return response.json()

def get_account(address):
    url = 'https://node-tron.nyyu.io/mainnet/api/wallet/getaccount'
    data = {
        'address': address,
        'visible': True
    }
    response = requests.post(url, json=data)
    return response.json()
```

## Support

For Tron-specific issues, visit:
- [Tron Documentation](https://developers.tron.network/)
- [Tron GitHub](https://github.com/tronprotocol/java-tron)
- [Tron Developer Forum](https://forum.tron.network/)

## License

This setup is provided as-is for monitoring Tron nodes.
