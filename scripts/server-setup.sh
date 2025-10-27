#!/bin/bash

# AWS Lightsail Server Setup Script
# This script sets up a fresh Ubuntu instance for Docker deployment

set -e

echo "🚀 Setting up AWS Lightsail instance for User Management App"
echo "============================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Update system
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y
print_success "System updated"

# Install essential packages
print_status "Installing essential packages..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    ufw \
    htop \
    git \
    wget \
    unzip
print_success "Essential packages installed"

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    print_success "Docker installed"
else
    print_warning "Docker already installed"
fi

# Install Docker Compose
print_status "Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    # Get latest version
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
    
    # Download and install
    sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for compatibility
    sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    
    print_success "Docker Compose installed"
else
    print_warning "Docker Compose already installed"
fi

# Configure firewall
print_status "Configuring firewall..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw --force enable
print_success "Firewall configured"

# Optimize system for MongoDB
print_status "Optimizing system for MongoDB..."
echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/enabled > /dev/null
echo 'never' | sudo tee /sys/kernel/mm/transparent_hugepage/defrag > /dev/null

# Make the setting permanent
cat << 'EOF' | sudo tee /etc/rc.local > /dev/null
#!/bin/bash
echo 'never' > /sys/kernel/mm/transparent_hugepage/enabled
echo 'never' > /sys/kernel/mm/transparent_hugepage/defrag
exit 0
EOF
sudo chmod +x /etc/rc.local
print_success "MongoDB optimizations applied"

# Set up log rotation for Docker
print_status "Setting up Docker log rotation..."
sudo mkdir -p /etc/docker
cat << 'EOF' | sudo tee /etc/docker/daemon.json > /dev/null
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF
print_success "Docker log rotation configured"

# Restart Docker to apply settings
sudo systemctl restart docker
sudo systemctl enable docker

# Create swap file (recommended for small instances)
print_status "Setting up swap file..."
if [ ! -f /swapfile ]; then
    sudo fallocate -l 1G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab > /dev/null
    print_success "1GB swap file created"
else
    print_warning "Swap file already exists"
fi

# Install monitoring tools
print_status "Installing monitoring tools..."
sudo apt install -y htop iotop nethogs

# Set up automatic security updates
print_status "Configuring automatic security updates..."
sudo apt install -y unattended-upgrades
echo 'Unattended-Upgrade::Automatic-Reboot "false";' | sudo tee -a /etc/apt/apt.conf.d/50unattended-upgrades > /dev/null

print_success "Server setup completed!"

echo ""
echo "🎉 AWS Lightsail instance is ready for deployment!"
echo ""
echo "Server Information:"
echo "  - Docker version: $(docker --version)"
echo "  - Docker Compose version: $(docker-compose --version)"
echo "  - Available memory: $(free -h | grep Mem | awk '{print $2}')"
echo "  - Available disk: $(df -h / | grep / | awk '{print $4}')"
echo ""
echo "Next Steps:"
echo "1. Exit and reconnect to apply group changes: exit && ssh ubuntu@your-server"
echo "2. Test Docker: docker run hello-world"
echo "3. Deploy your application using: ./deploy.sh <server-ip>"
echo ""
echo "Security Notes:"
echo "- Change default SSH port if needed"
echo "- Set up SSL certificates after deployment"
echo "- Consider setting up automated backups"
echo "- Monitor system resources regularly"