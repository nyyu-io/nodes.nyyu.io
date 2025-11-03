# Azure Deployment Guide

This guide will help you deploy the lightweight Geth monitoring setup to your Azure server.

## Server Details

- **Hostname**: 20.66.47.188
- **Username**: azureuser
- **SSH Key**: Azure-NYYU.pem (located in this directory)

## Quick Start

### 1. Deploy to Azure

```bash
cd geth
./deploy-to-azure.sh
```

This script will:

1. Test SSH connection
2. Copy all necessary files to the Azure server
3. Install Docker and Docker Compose
4. Configure firewall rules
5. Start Geth monitoring services

### 2. Configure Azure Network Security Group

After deployment, you need to configure Azure NSG to allow traffic:

#### Required Ports (P2P - for blockchain sync)

- **30303** (TCP/UDP) - Ethereum Mainnet P2P
- **30304** (TCP/UDP) - Ethereum Sepolia P2P

#### Optional Ports (RPC Access)

If you want to access RPC from outside the server:

- **8545** (TCP) - Mainnet HTTP RPC
- **8546** (TCP) - Mainnet WebSocket
- **8547** (TCP) - Sepolia HTTP RPC
- **8548** (TCP) - Sepolia WebSocket

#### Monitoring Ports

- **3001** (TCP) - Grafana Dashboard
- **9091** (TCP) - Prometheus

**Steps to configure NSG:**

1. Go to Azure Portal
2. Navigate to your VM → Networking → Network Security Group
3. Click "Add inbound port rule"
4. Add rules for the ports listed above

Example rule for P2P:

- **Priority**: 100
- **Name**: Geth-P2P
- **Port**: 30303-30304
- **Protocol**: Any
- **Source**: Any
- **Destination**: Any
- **Action**: Allow

## Management Commands

### SSH into the Server

```bash
ssh -i geth/Azure-NYYU.pem azureuser@node-eth.nyyu.io
```

### Remote Management (from your local machine)

```bash
# Check sync status
ssh -i geth/Azure-NYYU.pem azureuser@node-eth.nyyu.io 'cd geth-monitoring && ./geth-manager.sh sync'

# Check peers
ssh -i geth/Azure-NYYU.pem azureuser@node-eth.nyyu.io 'cd geth-monitoring && ./geth-manager.sh peers'

# Check status
ssh -i geth/Azure-NYYU.pem azureuser@node-eth.nyyu.io 'cd geth-monitoring && ./geth-manager.sh status'

# View mainnet logs
ssh -i geth/Azure-NYYU.pem azureuser@node-eth.nyyu.io 'cd geth-monitoring && ./geth-manager.sh logs mainnet'

# View sepolia logs
ssh -i geth/Azure-NYYU.pem azureuser@node-eth.nyyu.io 'cd geth-monitoring && ./geth-manager.sh logs sepolia'
```

### On-Server Management

After SSH'ing into the server:

```bash
cd geth-monitoring

# Check sync status
./geth-manager.sh sync

# Check all status
./geth-manager.sh status

# View logs
./geth-manager.sh logs mainnet
./geth-manager.sh logs sepolia

# Check resources
./geth-manager.sh resources

# Test RPC
./geth-manager.sh test-rpc

# Stop services
./geth-manager.sh stop

# Start services
./geth-manager.sh start
```

## Monitoring Sync Progress

### Check Sync Status

```bash
# Via SSH
ssh -i geth/Azure-NYYU.pem azureuser@20.66.47.188 'cd geth-monitoring && docker exec geth-mainnet-monitor geth attach --exec "eth.syncing"'
```

Output when syncing:

```javascript
{
  currentBlock: 18500000,
  highestBlock: 18600000,
  startingBlock: 18400000,
  pulledStates: 5000000,
  knownStates: 10000000
}
```

Output when synced:

```javascript
false;
```

### Monitor via Grafana

Open in your browser: `http://20.66.47.188:3001`

- **Username**: admin
- **Password**: admin

You'll see:

- Current block height for both networks
- Peer count
- Sync progress
- Memory usage
- Transaction pool status

## Testing RPC Endpoints

### From Local Machine

```bash
# Test Mainnet
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://20.66.47.188:8545

# Test Sepolia
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://20.66.47.188:8547
```

### Check Sync Status via RPC

```bash
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}' \
  http://20.66.47.188:8545
```

## Update Configuration

### Update Your Application

Update `internal/migrations/seed_evm_networks.go`:

```go
// Ethereum Mainnet
{
    Network:             "ethereum",
    DisplayName:         "Ethereum Mainnet",
    IsEnabled:           true,
    IsActive:            true,
    IsTestnet:           false,
    RPCURL:              "http://20.66.47.188:8545",
    WSRPCUrl:            strPtr("ws://20.66.47.188:8546"),
    ChainID:             int64Ptr(1),
    // ... rest of config
},

// Ethereum Sepolia Testnet
{
    Network:             "sepolia",
    DisplayName:         "Ethereum Sepolia Testnet",
    IsEnabled:           true,
    IsActive:            true,
    IsTestnet:           true,
    RPCURL:              "http://20.66.47.188:8547",
    WSRPCUrl:            strPtr("ws://20.66.47.188:8548"),
    ChainID:             int64Ptr(11155111),
    // ... rest of config
},
```

### Fallback Configuration (Recommended)

For production, use both your own node and a fallback:

```go
// Primary RPC: Your Azure Geth node
RPCURL: "http://20.66.47.188:8545",

// Fallback RPC: Keep using dRPC or other providers
// Implement retry logic in your application to fallback if primary fails
```

## Updating the Deployment

### Update Files

```bash
# From your local machine
cd geth
./deploy-to-azure.sh
```

This will sync any changes you made to the configuration.

### Update Geth Version

```bash
# SSH into server
ssh -i geth/Azure-NYYU.pem azureuser@20.66.47.188

# Navigate to directory
cd geth-monitoring

# Pull latest Geth image
docker compose pull

# Restart services
docker compose up -d
```

## Storage Management

### Check Disk Usage

```bash
ssh -i geth/Azure-NYYU.pem azureuser@20.66.47.188 'df -h'
```

### Check Geth Data Size

```bash
ssh -i geth/Azure-NYYU.pem azureuser@20.66.47.188 'docker system df -v'
```

### Expand Disk if Needed

If you're running out of space:

1. Go to Azure Portal
2. Navigate to your VM → Disks
3. Select the OS disk
4. Click "Size + performance"
5. Select a larger size
6. Save and reboot VM
7. Expand the partition:

```bash
# SSH into server
sudo growpart /dev/sda 1
sudo resize2fs /dev/sda1
```

## Troubleshooting

### Services Not Starting

```bash
# Check Docker status
ssh -i geth/Azure-NYYU.pem azureuser@20.66.47.188 'sudo systemctl status docker'

# View Docker logs
ssh -i geth/Azure-NYYU.pem azureuser@20.66.47.188 'cd geth-monitoring && docker compose logs'
```

### Low Peer Count

1. Check Azure NSG allows ports 30303-30304
2. Check firewall: `sudo ufw status`
3. Restart nodes: `cd geth-monitoring && ./geth-manager.sh stop && ./geth-manager.sh start`

### Slow Sync

1. Check disk I/O: `iostat -x 1`
2. Check if using SSD (not HDD)
3. Consider upgrading Azure VM size
4. Increase cache size in docker-compose.yml

### Out of Memory

1. Check available memory: `free -h`
2. Reduce cache size in docker-compose.yml
3. Reduce maxpeers
4. Upgrade Azure VM size

### RPC Not Responding

1. Check if node is synced: `./geth-manager.sh sync`
2. Check if service is running: `docker compose ps`
3. Check Azure NSG allows the RPC ports
4. Test locally first: `curl http://localhost:8545`

## Security Best Practices

### 1. Restrict RPC Access

By default, RPC is exposed to the internet. For production, restrict it:

**Option A: Use Azure NSG to allow only specific IPs**

```
Source: Your application server IP
Destination port: 8545-8548
```

**Option B: Use SSH tunneling**

```bash
# From your application server
ssh -i key.pem -L 8545:localhost:8545 azureuser@20.66.47.188 -N
# Then connect to localhost:8545 from your app
```

**Option C: Modify docker-compose.yml**

```yaml
ports:
  - "127.0.0.1:8545:8545" # Only localhost
```

### 2. Regular Updates

```bash
# Update system packages
ssh -i geth/Azure-NYYU.pem azureuser@20.66.47.188 'sudo apt update && sudo apt upgrade -y'

# Update Docker images
ssh -i geth/Azure-NYYU.pem azureuser@20.66.47.188 'cd geth-monitoring && docker compose pull && docker compose up -d'
```

### 3. Enable Automatic Security Updates

```bash
ssh -i geth/Azure-NYYU.pem azureuser@20.66.47.188 'sudo apt install unattended-upgrades -y'
```

### 4. Set up Monitoring Alerts

Configure Grafana alerts for:

- Low peer count
- Sync issues
- High memory usage
- Disk space

## Cost Optimization

### Recommended Azure VM Sizes

**Minimum (Testing)**

- **Size**: Standard_D4s_v3
- **vCPUs**: 4
- **RAM**: 16 GB
- **Storage**: 256 GB Premium SSD
- **Cost**: ~$140/month

**Recommended (Production)**

- **Size**: Standard_D8s_v3
- **vCPUs**: 8
- **RAM**: 32 GB
- **Storage**: 1 TB Premium SSD
- **Cost**: ~$350/month

**Optimal (High Performance)**

- **Size**: Standard_D16s_v3
- **vCPUs**: 16
- **RAM**: 64 GB
- **Storage**: 2 TB Premium SSD
- **Cost**: ~$650/month

### Save Costs

1. Use Azure Reserved Instances (1-3 year commitment) for 40-60% discount
2. Use Standard SSD instead of Premium SSD (slower but cheaper)
3. Stop nodes during low-traffic periods (not recommended for production)
4. Use spot instances (risky, can be evicted)

## Backup Strategy

### Backup Geth Data

```bash
# SSH into server
ssh -i geth/Azure-NYYU.pem azureuser@20.66.47.188

# Stop node
cd geth-monitoring
./geth-manager.sh stop

# Create backup
sudo docker run --rm -v geth-monitoring_geth-mainnet-data:/data \
  -v /home/azureuser/backups:/backup \
  alpine tar czf /backup/geth-mainnet-$(date +%Y%m%d).tar.gz -C /data .

# Start node
./geth-manager.sh start
```

### Restore from Backup

```bash
# Stop and remove existing data
./geth-manager.sh stop
docker volume rm geth-monitoring_geth-mainnet-data

# Restore
docker volume create geth-monitoring_geth-mainnet-data
docker run --rm -v geth-monitoring_geth-mainnet-data:/data \
  -v /home/azureuser/backups:/backup \
  alpine tar xzf /backup/geth-mainnet-20241102.tar.gz -C /data

# Start node
./geth-manager.sh start
```

## Support

For issues specific to this deployment, check:

1. Azure Portal → Monitor → Logs
2. Geth logs: `./geth-manager.sh logs mainnet`
3. Docker logs: `docker compose logs`

For Geth issues:

- https://geth.ethereum.org/docs
- https://github.com/ethereum/go-ethereum
