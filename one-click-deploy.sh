#!/bin/bash

# One-Click Deployment Script for AWS Lightsail
# This script guides you through the entire deployment process

set -e

echo "🚀 One-Click Deployment to AWS Lightsail"
echo "========================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() { echo -e "\n${CYAN}=== $1 ===${NC}"; }
print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Welcome message
cat << 'EOF'

   ┌─────────────────────────────────────────────────────────────┐
   │                                                             │
   │   🌟 Welcome to One-Click AWS Lightsail Deployment! 🌟      │
   │                                                             │
   │   This script will help you deploy your User Management    │
   │   App to AWS Lightsail with just a few simple steps.       │
   │                                                             │
   └─────────────────────────────────────────────────────────────┘

EOF

# Check prerequisites
print_header "Checking Prerequisites"

# Check if we're in the right directory
if [ ! -f "package.json" ] || [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    print_error "Please run this script from the project root directory"
    exit 1
fi

# Check if required files exist
required_files=("scripts/deploy.sh" "scripts/server-setup.sh" "docker-compose.yml")
for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "Required file missing: $file"
        exit 1
    fi
done

print_success "All required files found"

# Get deployment information
print_header "Deployment Configuration"

read -p "📍 Enter your Lightsail instance IP address: " LIGHTSAIL_IP
if [ -z "$LIGHTSAIL_IP" ]; then
    print_error "IP address is required"
    exit 1
fi

read -p "🌐 Enter your domain name (optional, press Enter to skip): " DOMAIN_NAME

read -p "📧 Enter your email for SSL notifications (if using domain): " SSL_EMAIL

echo ""
print_status "Deployment Configuration:"
echo "  Server IP: $LIGHTSAIL_IP"
echo "  Domain: ${DOMAIN_NAME:-"Not using domain (IP only)"}"
echo "  SSL Email: ${SSL_EMAIL:-"Not provided"}"
echo ""

read -p "Continue with deployment? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 1
fi

# Test SSH connection
print_header "Testing Server Connection"
print_status "Testing SSH connection to $LIGHTSAIL_IP..."

if ssh -o ConnectTimeout=10 -o BatchMode=yes ubuntu@$LIGHTSAIL_IP exit &>/dev/null; then
    print_success "SSH connection successful"
else
    print_error "Cannot connect to server. Please check:"
    echo "  1. Server is running and accessible"
    echo "  2. SSH key is properly configured"
    echo "  3. IP address is correct"
    echo "  4. Security group allows SSH (port 22)"
    exit 1
fi

# Check if server is already set up
print_status "Checking if server is already configured..."
if ssh ubuntu@$LIGHTSAIL_IP "command -v docker &> /dev/null && command -v docker-compose &> /dev/null"; then
    print_warning "Docker is already installed on server"
    read -p "Skip server setup? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        SKIP_SETUP=true
    else
        SKIP_SETUP=false
    fi
else
    SKIP_SETUP=false
fi

# Server setup
if [ "$SKIP_SETUP" != "true" ]; then
    print_header "Setting Up Server"
    print_status "Uploading and running server setup script..."
    
    scp scripts/server-setup.sh ubuntu@$LIGHTSAIL_IP:~/
    ssh ubuntu@$LIGHTSAIL_IP "chmod +x server-setup.sh && ./server-setup.sh"
    
    print_success "Server setup completed"
    print_warning "You may need to reconnect to the server for group changes to take effect"
    
    # Wait a moment for services to start
    sleep 5
fi

# Deploy application
print_header "Deploying Application"
print_status "Deploying application to server..."

chmod +x scripts/deploy.sh
./scripts/deploy.sh $LIGHTSAIL_IP

if [ $? -eq 0 ]; then
    print_success "Application deployed successfully!"
else
    print_error "Application deployment failed"
    exit 1
fi

# SSL setup if domain provided
if [ ! -z "$DOMAIN_NAME" ]; then
    print_header "Setting Up SSL Certificate"
    
    print_status "Checking if domain points to server..."
    DOMAIN_IP=$(nslookup $DOMAIN_NAME | grep -A1 "Name:" | tail -n1 | awk '{print $2}')
    
    if [ "$DOMAIN_IP" = "$LIGHTSAIL_IP" ]; then
        print_success "Domain correctly points to server"
        
        print_status "Setting up SSL certificate for $DOMAIN_NAME..."
        scp scripts/ssl-setup.sh ubuntu@$LIGHTSAIL_IP:~/userapp/
        ssh ubuntu@$LIGHTSAIL_IP "cd userapp && chmod +x ssl-setup.sh && echo '$SSL_EMAIL' | ./ssl-setup.sh $DOMAIN_NAME"
        
        if [ $? -eq 0 ]; then
            print_success "SSL certificate configured successfully!"
            FINAL_URL="https://$DOMAIN_NAME"
        else
            print_warning "SSL setup failed, but application is still accessible via HTTP"
            FINAL_URL="http://$DOMAIN_NAME"
        fi
    else
        print_warning "Domain does not point to server IP yet"
        print_status "Please update your DNS records and run SSL setup later:"
        echo "  ssh ubuntu@$LIGHTSAIL_IP"
        echo "  cd userapp && ./ssl-setup.sh $DOMAIN_NAME"
        FINAL_URL="http://$LIGHTSAIL_IP"
    fi
else
    FINAL_URL="http://$LIGHTSAIL_IP"
fi

# Final status check
print_header "Deployment Complete!"

print_status "Testing application..."
sleep 10

if curl -f -s "$FINAL_URL/api/health" > /dev/null; then
    print_success "Application is responding correctly!"
else
    print_warning "Application may still be starting up"
fi

# Summary
cat << EOF

┌─────────────────────────────────────────────────────────────────┐
│                    🎉 DEPLOYMENT SUCCESSFUL! 🎉                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  🌐 Your application is live at:                                │
│     $FINAL_URL                                   │
│                                                                 │
│  📊 Management URLs:                                            │
│     API Health: $FINAL_URL/api/health            │
│     Server IP:  $LIGHTSAIL_IP                                   │
│                                                                 │
│  🛠️  Management Commands (run on server):                       │
│     Connect:    ssh ubuntu@$LIGHTSAIL_IP                        │
│     Status:     sudo docker-compose ps                         │
│     Logs:       sudo docker-compose logs -f                    │
│     Restart:    sudo docker-compose restart                    │
│                                                                 │
│  📋 Next Steps:                                                 │
│     • Test all application features                            │
│     • Set up monitoring and backups                           │
│     • Configure custom domain (if not done)                   │
│     • Review security settings                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘

EOF

# Save deployment info
cat << EOF > deployment-info.txt
Deployment Date: $(date)
Server IP: $LIGHTSAIL_IP
Domain: ${DOMAIN_NAME:-"None"}
Application URL: $FINAL_URL
SSH Command: ssh ubuntu@$LIGHTSAIL_IP

Management Commands:
- Check status: sudo docker-compose ps
- View logs: sudo docker-compose logs -f  
- Restart: sudo docker-compose restart
- Stop: sudo docker-compose down
EOF

print_success "Deployment information saved to deployment-info.txt"

print_header "Useful Resources"
echo "📖 Detailed Documentation: ./DEPLOYMENT.md"
echo "✅ Quick Checklist: ./DEPLOYMENT-CHECKLIST.md"
echo "🔧 Troubleshooting: Check logs with 'sudo docker-compose logs -f'"
echo "💬 Support: Review the troubleshooting section in DEPLOYMENT.md"

echo ""
print_success "Deployment completed successfully! 🚀"