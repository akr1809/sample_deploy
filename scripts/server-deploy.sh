#!/bin/bash

# Server-Side Deployment Script for AWS Lightsail
# Run this script directly on your Lightsail server

set -e

echo "🚀 Starting server-side deployment..."
echo "====================================="

# Configuration
APP_NAME="userapp"
REPO_URL="https://github.com/akr1809/sample_deploy.git"
BRANCH="add-users-app"

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

# Check if running on server (not local machine)
if [[ "$HOME" != "/home/ubuntu" ]] && [[ "$USER" != "ubuntu" ]]; then
    print_error "This script should be run ON the Lightsail server, not locally"
    echo ""
    echo "To use this script:"
    echo "1. SSH into your Lightsail server: ssh ubuntu@YOUR_SERVER_IP"
    echo "2. Download this script: wget https://raw.githubusercontent.com/akr1809/sample_deploy/add-users-app/scripts/server-deploy.sh"
    echo "3. Make executable: chmod +x server-deploy.sh"
    echo "4. Run: ./server-deploy.sh"
    exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check prerequisites
print_status "Checking prerequisites..."

# Check if Docker is installed
if ! command_exists docker; then
    print_error "Docker not found. Please run server setup first:"
    echo "wget https://raw.githubusercontent.com/akr1809/sample_deploy/add-users-app/scripts/server-setup.sh"
    echo "chmod +x server-setup.sh && ./server-setup.sh"
    exit 1
fi

# Check if Docker Compose is installed
if ! command_exists docker-compose; then
    print_error "Docker Compose not found. Please run server setup first."
    exit 1
fi

# Check if user is in docker group
if ! groups | grep -q docker; then
    print_warning "User not in docker group. Adding to group..."
    sudo usermod -aG docker $USER
    print_warning "Please log out and log back in, then run this script again"
    exit 1
fi

print_success "Prerequisites check completed"

# Create application directory
print_status "Setting up application directory..."
cd ~
APP_DIR="$HOME/$APP_NAME"

# Stop existing application if running
if [ -d "$APP_DIR" ]; then
    print_status "Stopping existing application..."
    cd "$APP_DIR"
    sudo docker-compose down --remove-orphans 2>/dev/null || true
    cd ~
fi

# Clone or update repository
print_status "Getting latest application code..."
if [ -d "$APP_DIR" ]; then
    print_status "Updating existing repository..."
    cd "$APP_DIR"
    git fetch origin
    git reset --hard origin/$BRANCH
    cd ~
else
    print_status "Cloning repository..."
    git clone -b $BRANCH $REPO_URL $APP_DIR
fi

print_success "Application code ready"

# Navigate to app directory
cd "$APP_DIR"

# Setup environment file
print_status "Configuring environment..."
if [ ! -f .env ]; then
    if [ -f .env.production ]; then
        cp .env.production .env
        print_success "Environment file created from template"
    else
        print_status "Creating default environment file..."
        cat << EOF > .env
NODE_ENV=production
PORT=5000
MONGODB_URI=mongodb://mongodb:27017/userapp
JWT_SECRET=your_super_secure_jwt_secret_$(date +%s)
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
LOG_LEVEL=info
EOF
        print_success "Default environment file created"
    fi
else
    print_success "Environment file already exists"
fi

# Make scripts executable
print_status "Setting up scripts..."
if [ -d "scripts" ]; then
    chmod +x scripts/*.sh 2>/dev/null || true
fi

# Clean up any existing containers and images
print_status "Cleaning up existing containers..."
sudo docker-compose down --remove-orphans 2>/dev/null || true
sudo docker system prune -f 2>/dev/null || true

# Build and start application
print_status "Building and starting application..."
sudo docker-compose up --build -d

# Wait for services to start
print_status "Waiting for services to initialize..."
sleep 30

# Check service health
print_status "Checking service health..."
sudo docker-compose ps

# Verify each service is running
services=("mongodb" "backend" "frontend")
for service in "${services[@]}"; do
    if sudo docker-compose ps | grep -q "$service.*Up"; then
        print_success "$service is running"
    else
        print_error "$service failed to start"
        print_status "Checking $service logs:"
        sudo docker-compose logs $service | tail -10
    fi
done

# Test application health
print_status "Testing application health..."
sleep 10

# Get server IP
SERVER_IP=$(curl -s http://checkip.amazonaws.com 2>/dev/null || curl -s http://ipinfo.io/ip 2>/dev/null || echo "localhost")

# Test API endpoint
if curl -f -s "http://localhost:80/api/health" > /dev/null 2>&1; then
    print_success "Application is responding correctly!"
elif curl -f -s "http://localhost:5000/api/health" > /dev/null 2>&1; then
    print_success "Backend API is responding correctly!"
else
    print_warning "Application health check failed"
    print_status "Checking container logs..."
    sudo docker-compose logs --tail=20
fi

# Show deployment summary
print_success "Deployment completed!"

echo ""
echo "📊 Deployment Summary"
echo "===================="
echo "Server IP: $SERVER_IP"
echo "Application URL: http://$SERVER_IP"
echo "API Health: http://$SERVER_IP/api/health"
echo ""
echo "🔧 Management Commands:"
echo "Check status:    sudo docker-compose ps"
echo "View logs:       sudo docker-compose logs -f"
echo "Restart app:     sudo docker-compose restart"
echo "Stop app:        sudo docker-compose down"
echo "Update app:      ./server-deploy.sh"
echo ""

# Optional: Setup SSL if domain is provided
if [ ! -z "$1" ] && [[ "$1" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    DOMAIN="$1"
    print_status "Domain provided: $DOMAIN"
    
    # Check if domain points to this server
    DOMAIN_IP=$(nslookup $DOMAIN 2>/dev/null | grep -A1 "Name:" | tail -n1 | awk '{print $2}' 2>/dev/null || echo "")
    
    if [ "$DOMAIN_IP" = "$SERVER_IP" ]; then
        print_success "Domain correctly points to this server"
        
        if [ -f "scripts/ssl-setup.sh" ]; then
            read -p "Set up SSL certificate for $DOMAIN? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_status "Setting up SSL for $DOMAIN..."
                ./scripts/ssl-setup.sh $DOMAIN
            fi
        fi
    else
        print_warning "Domain $DOMAIN does not point to this server ($SERVER_IP)"
        print_status "Update your DNS records and run: ./scripts/ssl-setup.sh $DOMAIN"
    fi
fi

# Save deployment info
cat << EOF > deployment-info.txt
Deployment Date: $(date)
Server IP: $SERVER_IP
Application URL: http://$SERVER_IP
Repository: $REPO_URL
Branch: $BRANCH
Directory: $APP_DIR

Management Commands:
- Check status: sudo docker-compose ps
- View logs: sudo docker-compose logs -f
- Restart: sudo docker-compose restart
- Stop: sudo docker-compose down
- Update: cd $APP_DIR && git pull && sudo docker-compose up --build -d
EOF

print_success "Deployment information saved to deployment-info.txt"

echo ""
print_success "🎉 Your application is now live!"
echo "Visit: http://$SERVER_IP"