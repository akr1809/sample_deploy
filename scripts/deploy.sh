#!/bin/bash

# Deploy Full-Stack User App to AWS Lightsail
# This script automates the deployment process

set -e

echo "🚀 Starting deployment to AWS Lightsail..."
echo "==========================================="

# Configuration
APP_NAME="userapp"
DEPLOY_USER="ubuntu"
DEPLOY_HOST="" # Will be set via command line argument

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if host is provided
if [ -z "$1" ]; then
    print_error "Please provide the Lightsail instance IP address or domain"
    echo "Usage: $0 <lightsail-ip-or-domain>"
    echo "Example: $0 3.45.67.89"
    exit 1
fi

DEPLOY_HOST=$1

print_status "Deploying to: $DEPLOY_HOST"

# Check if we can connect to the server
print_status "Testing connection to server..."
if ! ssh -o ConnectTimeout=10 -o BatchMode=yes $DEPLOY_USER@$DEPLOY_HOST exit &>/dev/null; then
    print_error "Cannot connect to $DEPLOY_HOST"
    print_warning "Make sure:"
    echo "  1. Your SSH key is added to the server"
    echo "  2. The server is running"
    echo "  3. The IP address/domain is correct"
    exit 1
fi

print_success "Connection established!"

# Create deployment package
print_status "Creating deployment package..."
TEMP_DIR=$(mktemp -d)
APP_DIR="$TEMP_DIR/$APP_NAME"

# Copy application files
mkdir -p $APP_DIR
cp -r backend/ $APP_DIR/
cp -r frontend/ $APP_DIR/
cp docker-compose.yml $APP_DIR/
cp mongo-init.js $APP_DIR/
cp .env.production $APP_DIR/.env
cp scripts/server-setup.sh $APP_DIR/
cp scripts/ssl-setup.sh $APP_DIR/

# Remove development files
rm -rf $APP_DIR/backend/node_modules
rm -rf $APP_DIR/frontend/node_modules
rm -rf $APP_DIR/frontend/build

print_success "Deployment package created"

# Create tar archive
print_status "Creating archive..."
cd $TEMP_DIR
tar -czf ${APP_NAME}.tar.gz $APP_NAME
print_success "Archive created: ${APP_NAME}.tar.gz"

# Upload to server
print_status "Uploading application to server..."
scp ${APP_NAME}.tar.gz $DEPLOY_USER@$DEPLOY_HOST:~/
print_success "Upload completed"

# Deploy on server
print_status "Deploying application on server..."
ssh $DEPLOY_USER@$DEPLOY_HOST << EOF
    set -e
    
    echo "📦 Extracting application..."
    tar -xzf ${APP_NAME}.tar.gz
    
    echo "🔄 Stopping existing containers..."
    cd $APP_NAME
    sudo docker-compose down --remove-orphans || true
    
    echo "🏗️ Building and starting containers..."
    sudo docker-compose up --build -d
    
    echo "⏳ Waiting for services to start..."
    sleep 30
    
    echo "🔍 Checking service health..."
    sudo docker-compose ps
    
    echo "🎉 Deployment completed!"
    echo ""
    echo "Your application is now running at:"
    echo "  http://$(curl -s http://checkip.amazonaws.com)"
    echo ""
    echo "To check logs:"
    echo "  sudo docker-compose logs -f"
    echo ""
    echo "To stop the application:"
    echo "  sudo docker-compose down"
EOF

print_success "Deployment completed successfully!"

# Cleanup
rm -rf $TEMP_DIR

print_status "Testing deployed application..."
sleep 10

# Test the application
if curl -f -s "http://$DEPLOY_HOST/api/health" > /dev/null; then
    print_success "Application is responding correctly!"
    echo ""
    echo "🌐 Your application is live at: http://$DEPLOY_HOST"
    echo ""
    echo "Next steps:"
    echo "1. Set up SSL certificate (run ssl-setup.sh on server)"
    echo "2. Configure your domain name"
    echo "3. Set up monitoring and backups"
else
    print_warning "Application deployed but health check failed"
    echo "Check the logs with: ssh $DEPLOY_USER@$DEPLOY_HOST 'cd $APP_NAME && sudo docker-compose logs'"
fi