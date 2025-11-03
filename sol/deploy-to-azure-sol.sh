#!/bin/bash

# Deploy Solana Monitoring to Azure Server with SSL Support
# This script will copy files and set up Solana on the remote server

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   Solana Azure Deployment Script      ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Configuration prompts
prompt_configuration() {
    print_header

    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}           Configuration Setup                         ${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""

    # Server configuration
    read -p "Enter Azure Server IP [node-sol.nyyu.io]: " AZURE_HOST
    AZURE_HOST=${AZURE_HOST:-node-sol.nyyu.io}

    read -p "Enter SSH username [azureuser]: " AZURE_USER
    AZURE_USER=${AZURE_USER:-azureuser}

    read -p "Enter SSH key path [./rcp_eth.pem]: " SSH_KEY
    SSH_KEY=${SSH_KEY:-./rcp_eth.pem}

    read -p "Enter remote directory [/home/azureuser/sol-monitoring]: " REMOTE_DIR
    REMOTE_DIR=${REMOTE_DIR:-/home/azureuser/sol-monitoring}

    echo ""

    # SSL Configuration
    read -p "Do you want to configure SSL/HTTPS? (y/n) [n]: " USE_SSL
    USE_SSL=${USE_SSL:-n}

    if [[ "$USE_SSL" =~ ^[Yy]$ ]]; then
        read -p "Enter your domain name (e.g., sol.yourdomain.com): " DOMAIN

        if [ -z "$DOMAIN" ]; then
            print_error "Domain name is required for SSL"
            exit 1
        fi

        echo ""
        echo "Select SSL provider:"
        echo "  1) Let's Encrypt (Free, automatic renewal)"
        echo "  2) Cloudflare (Generate new certificate with API)"
        echo "  3) Use existing certificates (I already have SSL certificates)"
        read -p "Enter choice [3]: " SSL_PROVIDER
        SSL_PROVIDER=${SSL_PROVIDER:-3}

        if [ "$SSL_PROVIDER" == "2" ]; then
            read -p "Enter Cloudflare API Token: " CF_API_TOKEN
            read -p "Enter Cloudflare Zone ID: " CF_ZONE_ID

            if [ -z "$CF_API_TOKEN" ] || [ -z "$CF_ZONE_ID" ]; then
                print_error "Cloudflare credentials are required"
                exit 1
            fi
            read -p "Enter email for SSL certificate notifications: " SSL_EMAIL
        elif [ "$SSL_PROVIDER" == "3" ]; then
            echo ""
            print_info "Using existing SSL certificates"
            read -p "Path to your certificate file (fullchain.pem) [./fullchain.pem]: " CERT_FILE
            CERT_FILE=${CERT_FILE:-./fullchain.pem}

            read -p "Path to your private key file (privkey.pem) [./privkey.pem]: " KEY_FILE
            KEY_FILE=${KEY_FILE:-./privkey.pem}

            if [ ! -f "$CERT_FILE" ]; then
                print_error "Certificate file not found: $CERT_FILE"
                exit 1
            fi

            if [ ! -f "$KEY_FILE" ]; then
                print_error "Private key file not found: $KEY_FILE"
                exit 1
            fi
        else
            # Let's Encrypt
            read -p "Enter email for SSL certificate notifications: " SSL_EMAIL
            if [ -z "$SSL_EMAIL" ]; then
                print_error "Email is required for SSL certificate"
                exit 1
            fi
        fi
    else
        DOMAIN=""
        SSL_PROVIDER="none"
    fi

    echo ""
    read -p "Enter Grafana admin password [admin]: " GRAFANA_PASSWORD
    GRAFANA_PASSWORD=${GRAFANA_PASSWORD:-admin}

    echo ""
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}           Configuration Summary                       ${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  Server: $AZURE_USER@$AZURE_HOST"
    echo "  SSH Key: $SSH_KEY"
    echo "  Remote Directory: $REMOTE_DIR"

    if [ "$USE_SSL" == "y" ] || [ "$USE_SSL" == "Y" ]; then
        echo "  SSL: Enabled"
        echo "  Domain: $DOMAIN"
        if [ "$SSL_PROVIDER" == "1" ]; then
            echo "  Provider: Let's Encrypt"
            echo "  Email: $SSL_EMAIL"
        elif [ "$SSL_PROVIDER" == "2" ]; then
            echo "  Provider: Cloudflare (Auto-generate)"
            echo "  Email: $SSL_EMAIL"
        else
            echo "  Provider: Existing Certificates"
            echo "  Certificate: $CERT_FILE"
            echo "  Private Key: $KEY_FILE"
        fi
    else
        echo "  SSL: Disabled"
    fi

    echo "  Grafana Password: ${GRAFANA_PASSWORD//?/*}"
    echo ""

    read -p "Proceed with deployment? (y/n) [y]: " PROCEED
    PROCEED=${PROCEED:-y}

    if [[ ! "$PROCEED" =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled"
        exit 0
    fi

    echo ""
}

# Check if SSH key exists
check_ssh_key() {
    if [ ! -f "$SSH_KEY" ]; then
        print_error "SSH key not found: $SSH_KEY"
        exit 1
    fi

    chmod 600 "$SSH_KEY"
    print_success "SSH key permissions set"
}

# Test SSH connection
test_ssh_connection() {
    print_info "Testing SSH connection to Azure server..."
    if ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$AZURE_USER@$AZURE_HOST" "echo 'Connection successful'" > /dev/null 2>&1; then
        print_success "SSH connection successful"
    else
        print_error "Cannot connect to Azure server. Please check your credentials."
        exit 1
    fi
}

# Create .env file
create_env_file() {
    print_info "Creating environment configuration..."

    cat > .env.deploy << EOF
# Solana Monitoring Configuration
GRAFANA_PASSWORD=$GRAFANA_PASSWORD
DOMAIN=${DOMAIN:-localhost}
GRAFANA_ROOT_URL=${DOMAIN:+https://$DOMAIN/grafana/}
SSL_ENABLED=${USE_SSL}
SSL_PROVIDER=${SSL_PROVIDER}
SSL_EMAIL=${SSL_EMAIL:-}
CF_API_TOKEN=${CF_API_TOKEN:-}
CF_ZONE_ID=${CF_ZONE_ID:-}
EOF

    print_success "Environment file created"
}

# Copy files to Azure server
copy_files() {
    print_info "Preparing remote directory..."
    ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" << ENDSSH
# Remove old directory if exists and recreate
sudo rm -rf $REMOTE_DIR
mkdir -p $REMOTE_DIR
ENDSSH
    print_success "Remote directory prepared"

    print_info "Copying files to Azure server..."
    rsync -avz --progress -e "ssh -i $SSH_KEY" \
        --exclude 'rcp_eth.pem' \
        --exclude 'Azure-NYYU.pem' \
        --exclude '.git' \
        --exclude 'deploy-to-azure-sol.sh' \
        --exclude '.env.deploy' \
        ./ "$AZURE_USER@$AZURE_HOST:$REMOTE_DIR/"

    # Copy .env file
    scp -i "$SSH_KEY" .env.deploy "$AZURE_USER@$AZURE_HOST:$REMOTE_DIR/.env"
    rm .env.deploy

    print_success "Files copied successfully"
}

# Install Docker and dependencies
install_docker() {
    print_info "Setting up Docker on Azure server..."
    ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" << 'ENDSSH'
set -e

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."

    # Update package index
    sudo apt-get update

    # Install prerequisites
    sudo apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        jq

    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # Set up the repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Add user to docker group
    sudo usermod -aG docker $USER

    echo "Docker installed successfully!"
else
    echo "Docker is already installed"
fi

# Check if user is in docker group
if ! groups | grep -q docker; then
    echo "Adding user to docker group..."
    sudo usermod -aG docker $USER
fi

# Enable and start Docker
sudo systemctl enable docker
sudo systemctl start docker

echo "Docker setup complete!"
ENDSSH
    print_success "Docker setup complete"
}

# Configure firewall
configure_firewall() {
    print_info "Configuring firewall..."
    ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" << ENDSSH
set -e

# Check if UFW is installed
if ! command -v ufw &> /dev/null; then
    echo "Installing UFW..."
    sudo apt-get install -y ufw
fi

echo "Configuring UFW firewall..."

# Allow SSH (important!)
sudo ufw allow 22/tcp

# Allow Solana P2P and Gossip ports
sudo ufw allow 8001:8015/tcp
sudo ufw allow 8001:8015/udp

# Allow HTTP/HTTPS if SSL is enabled
if [ "$USE_SSL" == "y" ] || [ "$USE_SSL" == "Y" ]; then
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
else
    # Allow direct RPC access if no SSL
    sudo ufw allow 8899/tcp
    sudo ufw allow 8898/tcp
    sudo ufw allow 8900/tcp
    sudo ufw allow 8901/tcp
    sudo ufw allow 3005/tcp
    sudo ufw allow 9095/tcp
fi

# Enable UFW if not already enabled
sudo ufw --force enable

echo "Firewall rules configured"
ENDSSH
    print_success "Firewall configured"
}

# Setup SSL certificates
setup_ssl() {
    if [[ ! "$USE_SSL" =~ ^[Yy]$ ]]; then
        return
    fi

    print_info "Setting up SSL certificates..."

    if [ "$SSL_PROVIDER" == "1" ]; then
        # Let's Encrypt
        ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" << ENDSSH
set -e
cd $REMOTE_DIR

# Install certbot
if ! command -v certbot &> /dev/null; then
    echo "Installing Certbot..."
    sudo apt-get update
    sudo apt-get install -y certbot
fi

# Create nginx directories
mkdir -p nginx/ssl nginx/conf.d nginx/acme-challenge

# Obtain certificate
echo "Obtaining SSL certificate from Let's Encrypt..."
sudo certbot certonly --standalone \
    --non-interactive \
    --keep-until-expiring \
    --email $SSL_EMAIL \
    --agree-tos \
    --no-eff-email \
    --preferred-challenges http \
    -d $DOMAIN

# Copy certificates
echo "Copying SSL certificates..."
sudo cp -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem nginx/ssl/fullchain.pem
sudo cp -f /etc/letsencrypt/live/$DOMAIN/privkey.pem nginx/ssl/privkey.pem
sudo chown -R azureuser:azureuser nginx/ssl/
chmod 600 nginx/ssl/*.pem

echo "SSL certificates copied successfully!"

# Setup auto-renewal
echo "Setting up auto-renewal..."
(sudo crontab -l 2>/dev/null | grep -v "certbot renew"; echo "0 0 * * * certbot renew --quiet && cp -f /etc/letsencrypt/live/$DOMAIN/fullchain.pem $REMOTE_DIR/nginx/ssl/ && cp -f /etc/letsencrypt/live/$DOMAIN/privkey.pem $REMOTE_DIR/nginx/ssl/ && cd $REMOTE_DIR && docker compose restart nginx") | sudo crontab -

echo "Let's Encrypt SSL certificate installed!"
ENDSSH
    elif [ "$SSL_PROVIDER" == "2" ]; then
        # Cloudflare API
        ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" << ENDSSH
set -e
cd $REMOTE_DIR

# Create nginx directories
mkdir -p nginx/ssl nginx/conf.d nginx/acme-challenge

# Install acme.sh
if [ ! -d ~/.acme.sh ]; then
    echo "Installing acme.sh..."
    curl https://get.acme.sh | sh -s email=$SSL_EMAIL
fi

# Export Cloudflare credentials
export CF_Token="$CF_API_TOKEN"
export CF_Zone_ID="$CF_ZONE_ID"

# Obtain certificate using Cloudflare DNS
echo "Obtaining SSL certificate from Let's Encrypt via Cloudflare..."
~/.acme.sh/acme.sh --issue --dns dns_cf -d $DOMAIN

# Install certificate
~/.acme.sh/acme.sh --install-cert -d $DOMAIN \
    --key-file $REMOTE_DIR/nginx/ssl/privkey.pem \
    --fullchain-file $REMOTE_DIR/nginx/ssl/fullchain.pem \
    --reloadcmd "cd $REMOTE_DIR && docker compose restart nginx"

echo "Cloudflare SSL certificate installed!"
ENDSSH
    else
        # Existing certificates
        print_info "Uploading existing SSL certificates..."

        # Create remote SSL directory
        ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" "mkdir -p $REMOTE_DIR/nginx/ssl $REMOTE_DIR/nginx/conf.d $REMOTE_DIR/nginx/acme-challenge"

        # Copy certificate files
        scp -i "$SSH_KEY" "$CERT_FILE" "$AZURE_USER@$AZURE_HOST:$REMOTE_DIR/nginx/ssl/fullchain.pem"
        scp -i "$SSH_KEY" "$KEY_FILE" "$AZURE_USER@$AZURE_HOST:$REMOTE_DIR/nginx/ssl/privkey.pem"

        # Set proper permissions
        ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" "chmod 600 $REMOTE_DIR/nginx/ssl/*.pem"

        print_success "Existing SSL certificates uploaded"
    fi

    print_success "SSL certificates configured"
}

# Generate nginx configuration
generate_nginx_config() {
    if [[ ! "$USE_SSL" =~ ^[Yy]$ ]]; then
        return
    fi

    print_info "Generating nginx configuration..."

    ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" << ENDSSH
set -e
cd $REMOTE_DIR

# Create nginx directories
mkdir -p nginx/conf.d

# Main nginx config
cat > nginx/nginx.conf << 'NGINX_MAIN_EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    tcp_nopush on;
    keepalive_timeout 65;
    gzip on;

    # Increase buffer sizes for Solana RPC responses
    proxy_buffer_size 128k;
    proxy_buffers 4 256k;
    proxy_busy_buffers_size 256k;
    client_max_body_size 10m;

    include /etc/nginx/conf.d/*.conf;
}
NGINX_MAIN_EOF

# Health check endpoint
cat > nginx/conf.d/health.conf << 'NGINX_HEALTH_EOF'
server {
    listen 80 default_server;
    server_name _;

    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
}
NGINX_HEALTH_EOF

# Main server config
cat > nginx/conf.d/sol.conf << NGINX_SOL_EOF
# HTTP to HTTPS redirect
server {
    listen 80;
    server_name $DOMAIN;

    location /.well-known/acme-challenge/ {
        root /var/www/acme-challenge;
    }

    location / {
        return 301 https://\\\$server_name\\\$request_uri;
    }
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name $DOMAIN;

    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Mainnet RPC
    location /mainnet/rpc {
        proxy_pass http://sol-mainnet:8899/;
        proxy_http_version 1.1;
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
        proxy_read_timeout 60s;
        proxy_connect_timeout 30s;

        # CORS headers
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type" always;

        if (\\\$request_method = OPTIONS) {
            return 204;
        }
    }

    # Mainnet WebSocket
    location /mainnet/ws {
        proxy_pass http://sol-mainnet:8900/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \\\$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
        proxy_read_timeout 86400;
    }

    # Devnet RPC
    location /devnet/rpc {
        proxy_pass http://sol-devnet:8899/;
        proxy_http_version 1.1;
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
        proxy_read_timeout 60s;
        proxy_connect_timeout 30s;

        # CORS headers
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods "GET, POST, OPTIONS" always;
        add_header Access-Control-Allow-Headers "Content-Type" always;

        if (\\\$request_method = OPTIONS) {
            return 204;
        }
    }

    # Devnet WebSocket
    location /devnet/ws {
        proxy_pass http://sol-devnet:8900/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \\\$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
        proxy_read_timeout 86400;
    }

    # Grafana
    location /grafana/ {
        proxy_pass http://grafana:3000;
        proxy_http_version 1.1;
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
    }

    # Prometheus
    location /prometheus/ {
        proxy_pass http://prometheus:9090/;
        proxy_http_version 1.1;
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
    }

    # Root redirect
    location / {
        return 301 /grafana/;
    }
}
NGINX_SOL_EOF

echo "Nginx configuration generated!"
ENDSSH

    print_success "Nginx configuration created"
}

# Fix Grafana permissions
fix_grafana_permissions() {
    print_info "Fixing Grafana directory permissions..."
    ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" << ENDSSH
cd $REMOTE_DIR

# Grafana runs as user ID 472 inside the container
# Set ownership to 472:472 and permissions to 755
sudo chown -R 472:472 grafana/
sudo chmod -R 755 grafana/

echo "Grafana permissions fixed"
ENDSSH
    print_success "Grafana permissions configured"
}

# Start services
start_services() {
    print_info "Starting Solana monitoring services..."

    if [[ "$USE_SSL" =~ ^[Yy]$ ]]; then
        ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" << ENDSSH
cd $REMOTE_DIR

# Load environment
source .env

# Pull latest images
docker compose pull

# Start services with SSL
docker compose --profile ssl up -d

echo ""
echo "Waiting for services to start..."
sleep 10

# Show status
docker compose ps

echo ""
echo "Services started successfully with SSL!"
ENDSSH
    else
        ssh -i "$SSH_KEY" "$AZURE_USER@$AZURE_HOST" << ENDSSH
cd $REMOTE_DIR

# Pull latest images
docker compose pull

# Start services without SSL
docker compose up -d

echo ""
echo "Waiting for services to start..."
sleep 10

# Show status
docker compose ps

echo ""
echo "Services started successfully!"
ENDSSH
    fi

    print_success "Services started"
}

# Print deployment summary
print_summary() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║         Deployment Completed Successfully!             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ "$USE_SSL" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Access Points (HTTPS):${NC}"
        echo "  • Solana Mainnet RPC:  https://$DOMAIN/mainnet/rpc"
        echo "  • Solana Mainnet WS:   wss://$DOMAIN/mainnet/ws"
        echo "  • Solana Devnet RPC:   https://$DOMAIN/devnet/rpc"
        echo "  • Solana Devnet WS:    wss://$DOMAIN/devnet/ws"
        echo "  • Grafana:             https://$DOMAIN/grafana/"
        echo "  • Prometheus:          https://$DOMAIN/prometheus/"
    else
        echo -e "${BLUE}Access Points (HTTP):${NC}"
        echo "  • Solana Mainnet RPC:  http://$AZURE_HOST:8899"
        echo "  • Solana Mainnet WS:   ws://$AZURE_HOST:8900"
        echo "  • Solana Devnet RPC:   http://$AZURE_HOST:8898"
        echo "  • Solana Devnet WS:    ws://$AZURE_HOST:8901"
        echo "  • Grafana:             http://$AZURE_HOST:3005 (admin/$GRAFANA_PASSWORD)"
        echo "  • Prometheus:          http://$AZURE_HOST:9095"
    fi

    echo ""
    echo -e "${YELLOW}Important Notes:${NC}"
    echo "  1. Initial sync will take 2-6 hours with snapshot download (mainnet)"
    echo "  2. Devnet sync is faster (~30min - 2 hours)"
    echo "  3. Solana nodes require high-performance hardware (see README.md)"
    echo "  4. Monitor sync: ssh -i $SSH_KEY $AZURE_USER@$AZURE_HOST 'cd $REMOTE_DIR && ./sol-manager.sh sync'"
    echo "  5. View logs: ssh -i $SSH_KEY $AZURE_USER@$AZURE_HOST 'cd $REMOTE_DIR && ./sol-manager.sh logs mainnet'"
    echo "  6. Check status: ssh -i $SSH_KEY $AZURE_USER@$AZURE_HOST 'cd $REMOTE_DIR && ./sol-manager.sh status'"

    if [[ "$USE_SSL" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${BLUE}DNS Configuration Required:${NC}"
        echo "  Point your domain '$DOMAIN' to $AZURE_HOST"
        echo "  Example A record: $DOMAIN → $AZURE_HOST"
    fi

    echo ""
    echo -e "${BLUE}Next Steps:${NC}"
    echo "  1. Ensure Azure NSG allows ports 8001-8015 (P2P/Gossip)"
    if [[ "$USE_SSL" =~ ^[Yy]$ ]]; then
        echo "  2. Configure DNS to point $DOMAIN to $AZURE_HOST"
        echo "  3. Wait for SSL certificate to be issued"
        echo "  4. Update your application's RPC URLs to use https://$DOMAIN"
    else
        echo "  2. Optionally configure SSL later by re-running with SSL options"
        echo "  3. Update your application's RPC URLs to use $AZURE_HOST"
    fi

    echo ""
    echo -e "${BLUE}Test RPC Endpoints:${NC}"
    if [[ "$USE_SSL" =~ ^[Yy]$ ]]; then
        echo "  curl -X POST https://$DOMAIN/mainnet/rpc -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getHealth\"}'"
        echo "  curl -X POST https://$DOMAIN/devnet/rpc -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getHealth\"}'"
    else
        echo "  curl -X POST http://$AZURE_HOST:8899 -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getHealth\"}'"
        echo "  curl -X POST http://$AZURE_HOST:8898 -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"getHealth\"}'"
    fi

    echo ""
    print_success "Deployment complete!"
}

# Main execution
main() {
    prompt_configuration
    check_ssh_key
    test_ssh_connection
    create_env_file
    copy_files
    fix_grafana_permissions
    install_docker
    configure_firewall

    if [[ "$USE_SSL" =~ ^[Yy]$ ]]; then
        setup_ssl
        generate_nginx_config
    fi

    start_services
    print_summary
}

# Run main function
main
