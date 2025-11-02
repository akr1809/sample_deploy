#!/bin/bash

# Quick Server Deployment - Run this directly on your Lightsail server
# One-liner: curl -fsSL https://raw.githubusercontent.com/akr1809/sample_deploy/add-users-app/scripts/quick-deploy.sh | bash

set -e

echo "🚀 Quick Deploy - User Management App"
echo "====================================="

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Ensure we're on the server
if [[ "$HOME" != "/home/ubuntu" ]]; then
    print_error "This script must run on the Lightsail server as ubuntu user"
    echo "SSH to your server first: ssh ubuntu@YOUR_SERVER_IP"
    exit 1
fi

cd ~

# Install Docker if not present
if ! command -v docker >/dev/null 2>&1; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker ubuntu
    rm get-docker.sh
    print_warning "Please logout and login again, then re-run this script"
    exit 0
fi

# Install Docker Compose if not present
if ! command -v docker-compose >/dev/null 2>&1; then
    print_status "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
fi

# Clone/update repository
APP_DIR="$HOME/userapp"
if [ -d "$APP_DIR" ]; then
    print_status "Updating application..."
    cd "$APP_DIR"
    git pull origin add-users-app
else
    print_status "Cloning application..."
    git clone -b add-users-app https://github.com/akr1809/sample_deploy.git "$APP_DIR"
    cd "$APP_DIR"
fi

# Setup environment
if [ ! -f .env ]; then
    print_status "Creating environment file..."
    cat << 'EOF' > .env
NODE_ENV=production
PORT=5000
MONGODB_URI=mongodb://mongodb:27017/userapp
JWT_SECRET=super_secure_jwt_secret_$(date +%s)
BCRYPT_ROUNDS=12
EOF
fi

# Deploy
print_status "Deploying application..."
sudo docker-compose down 2>/dev/null || true
sudo docker-compose up --build -d

# Wait and test
print_status "Waiting for services..."
sleep 20

SERVER_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || echo "localhost")

if curl -s http://localhost/api/health >/dev/null 2>&1; then
    print_success "🎉 Deployment successful!"
    echo "Application: http://$SERVER_IP"
    echo "API Health: http://$SERVER_IP/api/health"
else
    print_warning "Deployment completed, checking logs..."
    sudo docker-compose logs --tail=10
fi

echo ""
echo "Management commands:"
echo "  sudo docker-compose ps       # Check status"
echo "  sudo docker-compose logs -f  # View logs"
echo "  sudo docker-compose restart  # Restart app"