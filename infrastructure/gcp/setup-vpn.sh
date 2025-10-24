#!/bin/bash

# Video AI Platform - Setup WireGuard VPN between GCP and Proxmox
# Establishes secure connection for Kafka and MinIO communication

set -e  # Exit on error

echo "=================================================="
echo "🔐 Setting up WireGuard VPN"
echo "=================================================="
echo ""

# Load environment variables
if [ -f .env ]; then
    echo "✓ Loading .env configuration..."
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ Error: .env file not found"
    exit 1
fi

# Validate required variables
required_vars=("GCP_ZONE" "INSTANCE_NAME" "PROXMOX_VPN_ENDPOINT")
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Error: $var is not set in .env"
        exit 1
    fi
done

echo "📋 Configuration:"
echo "   GCP Instance: $INSTANCE_NAME"
echo "   Proxmox Endpoint: $PROXMOX_VPN_ENDPOINT"
echo ""

# Check if WireGuard keys are set
if [ -z "$WG_PRIVATE_KEY" ] || [ "$WG_PRIVATE_KEY" = "generate_with_wg_genkey" ]; then
    echo "⚠️  WireGuard keys not configured in .env"
    echo ""
    echo "Generate keys with these commands:"
    echo "   # On GCP instance:"
    echo "   wg genkey | tee privatekey | wg pubkey > publickey"
    echo ""
    echo "   # On Proxmox:"
    echo "   wg genkey | tee proxmox-privatekey | wg pubkey > proxmox-publickey"
    echo ""
    echo "Then update .env with the keys and run this script again."
    exit 1
fi

# Get GCP instance external IP
EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$GCP_ZONE --format="get(networkInterfaces[0].accessConfigs[0].natIP)")

echo "🌐 GCP Instance External IP: $EXTERNAL_IP"
echo ""

# Create WireGuard config for GCP
echo "📝 Creating WireGuard configuration for GCP..."
cat > /tmp/wg0-gcp.conf <<EOF
[Interface]
PrivateKey = $WG_PRIVATE_KEY
Address = 10.100.0.2/24
ListenPort = 51820

[Peer]
PublicKey = $WG_PUBLIC_KEY
Endpoint = $PROXMOX_VPN_ENDPOINT:51820
AllowedIPs = 10.100.0.1/32, 192.168.1.0/24
PersistentKeepalive = 25
EOF

echo "✓ GCP config created"
echo ""

# Install and configure WireGuard on GCP instance
echo "🔧 Installing WireGuard on GCP instance..."
gcloud compute ssh $INSTANCE_NAME --zone=$GCP_ZONE --command='
    set -e
    echo "Installing WireGuard..."
    sudo apt-get update
    sudo apt-get install -y wireguard

    echo "Enabling IP forwarding..."
    sudo sysctl -w net.ipv4.ip_forward=1
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf

    echo "✓ WireGuard installed"
'

# Copy config to GCP instance
echo "📤 Uploading WireGuard config..."
gcloud compute scp /tmp/wg0-gcp.conf $INSTANCE_NAME:/tmp/wg0.conf --zone=$GCP_ZONE

# Configure WireGuard on GCP
gcloud compute ssh $INSTANCE_NAME --zone=$GCP_ZONE --command='
    set -e
    sudo mv /tmp/wg0.conf /etc/wireguard/wg0.conf
    sudo chmod 600 /etc/wireguard/wg0.conf

    # Start WireGuard
    sudo systemctl enable wg-quick@wg0
    sudo systemctl start wg-quick@wg0

    echo "✓ WireGuard started"

    # Show status
    sudo wg show
'

echo ""
echo "✅ WireGuard configured on GCP"
echo ""

# Create WireGuard config for Proxmox
echo "📝 Creating WireGuard configuration for Proxmox..."
cat > /tmp/wg0-proxmox.conf <<EOF
[Interface]
PrivateKey = <YOUR_PROXMOX_PRIVATE_KEY>
Address = 10.100.0.1/24
ListenPort = 51820

[Peer]
PublicKey = $WG_PUBLIC_KEY
Endpoint = $EXTERNAL_IP:51820
AllowedIPs = 10.100.0.2/32
PersistentKeepalive = 25
EOF

echo "✓ Proxmox config created at: /tmp/wg0-proxmox.conf"
echo ""

# Instructions for Proxmox setup
echo "=================================================="
echo "📋 Proxmox Setup Instructions"
echo "=================================================="
echo ""
echo "1. Copy the following config to your Proxmox host:"
echo "   /tmp/wg0-proxmox.conf"
echo ""
echo "2. SSH to Proxmox and run:"
echo ""
echo "   # Install WireGuard"
echo "   apt-get update && apt-get install -y wireguard"
echo ""
echo "   # Copy config"
echo "   cp wg0-proxmox.conf /etc/wireguard/wg0.conf"
echo "   chmod 600 /etc/wireguard/wg0.conf"
echo ""
echo "   # Enable IP forwarding"
echo "   sysctl -w net.ipv4.ip_forward=1"
echo "   echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf"
echo ""
echo "   # Start WireGuard"
echo "   systemctl enable wg-quick@wg0"
echo "   systemctl start wg-quick@wg0"
echo ""
echo "   # Check status"
echo "   wg show"
echo ""
echo "=================================================="
echo "🧪 Testing VPN Connection"
echo "=================================================="
echo ""
echo "From GCP instance, test Kafka connection:"
echo "   gcloud compute ssh $INSTANCE_NAME --zone=$GCP_ZONE --command='ping -c 4 192.168.1.23'"
echo ""
echo "From Proxmox, test GCP connection:"
echo "   ssh root@192.168.1.50"
echo "   ping -c 4 10.100.0.2"
echo ""
echo "✅ VPN setup complete!"
echo ""
