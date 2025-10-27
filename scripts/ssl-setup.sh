#!/bin/bash

# SSL Certificate Setup Script using Let's Encrypt
# Run this after your domain is pointing to your Lightsail instance

set -e

echo "🔒 Setting up SSL Certificate with Let's Encrypt"
echo "================================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if domain is provided
if [ -z "$1" ]; then
    print_error "Please provide your domain name"
    echo "Usage: $0 <your-domain.com>"
    echo "Example: $0 myapp.example.com"
    exit 1
fi

DOMAIN=$1
EMAIL="admin@$DOMAIN"  # Change this to your email

print_status "Setting up SSL for domain: $DOMAIN"

# Ask for email
read -p "Enter your email for Let's Encrypt notifications [$EMAIL]: " input_email
if [ ! -z "$input_email" ]; then
    EMAIL=$input_email
fi

# Install Certbot
print_status "Installing Certbot..."
sudo apt update
sudo apt install -y certbot python3-certbot-nginx
print_success "Certbot installed"

# Stop the application temporarily
print_status "Stopping application for certificate generation..."
cd ~/userapp || { print_error "Application directory not found"; exit 1; }
sudo docker-compose down
print_success "Application stopped"

# Create nginx configuration for SSL
print_status "Creating SSL-enabled nginx configuration..."

# Update the frontend nginx config for SSL
cat << EOF > frontend/nginx-ssl.conf
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS server
server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    # SSL configuration
    ssl_certificate /etc/letsencrypt/live/$DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$DOMAIN/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;

    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private must-revalidate auth;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Handle React routing
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # API proxy to backend
    location /api/ {
        proxy_pass http://backend:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }

    # Static assets caching
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Error pages
    error_page 404 /index.html;
}
EOF

# Update docker-compose.yml for SSL
print_status "Updating Docker Compose configuration for SSL..."
cat << EOF > docker-compose-ssl.yml
version: '3.8'

services:
  # MongoDB Database
  mongodb:
    image: mongo:7.0
    container_name: userapp-mongodb
    restart: unless-stopped
    environment:
      - MONGO_INITDB_DATABASE=userapp
    volumes:
      - mongodb_data:/data/db
      - ./mongo-init.js:/docker-entrypoint-initdb.d/mongo-init.js:ro
    networks:
      - userapp-network
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Backend API Service
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    container_name: userapp-backend
    restart: unless-stopped
    environment:
      - NODE_ENV=production
      - PORT=5000
      - MONGODB_URI=mongodb://mongodb:27017/userapp
    depends_on:
      - mongodb
    networks:
      - userapp-network
    healthcheck:
      test: ["CMD", "node", "healthcheck.js"]
      interval: 30s
      timeout: 10s
      retries: 3

  # Frontend Service with SSL
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: userapp-frontend
    restart: unless-stopped
    depends_on:
      - backend
    networks:
      - userapp-network
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /etc/letsencrypt:/etc/letsencrypt:ro
      - ./frontend/nginx-ssl.conf:/etc/nginx/conf.d/default.conf:ro
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  mongodb_data:
    driver: local

networks:
  userapp-network:
    driver: bridge
EOF

# Generate SSL certificate
print_status "Generating SSL certificate..."
sudo certbot certonly --standalone --non-interactive --agree-tos --email $EMAIL -d $DOMAIN

if [ $? -eq 0 ]; then
    print_success "SSL certificate generated successfully"
else
    print_error "Failed to generate SSL certificate"
    exit 1
fi

# Start application with SSL
print_status "Starting application with SSL configuration..."
sudo docker-compose -f docker-compose-ssl.yml up --build -d

# Wait for services to start
print_status "Waiting for services to start..."
sleep 30

# Test SSL
print_status "Testing SSL configuration..."
if curl -f -s "https://$DOMAIN/api/health" > /dev/null; then
    print_success "SSL is working correctly!"
else
    print_warning "SSL test failed, but certificate may still be valid"
fi

# Set up automatic renewal
print_status "Setting up automatic SSL renewal..."
echo "0 12 * * * /usr/bin/certbot renew --quiet && cd ~/userapp && sudo docker-compose -f docker-compose-ssl.yml restart frontend" | sudo crontab -

print_success "SSL setup completed!"

echo ""
echo "🎉 Your application is now secured with SSL!"
echo ""
echo "🌐 Your application is available at: https://$DOMAIN"
echo ""
echo "SSL Certificate Information:"
echo "  - Domain: $DOMAIN"
echo "  - Certificate expires: $(sudo certbot certificates | grep "Expiry Date" | head -1)"
echo "  - Auto-renewal: Configured (daily check at 12:00 PM)"
echo ""
echo "Management Commands:"
echo "  Check certificate status: sudo certbot certificates"
echo "  Test renewal: sudo certbot renew --dry-run"
echo "  View application logs: cd ~/userapp && sudo docker-compose logs -f"
echo ""
echo "Security Notes:"
echo "  ✅ HTTPS enforced (HTTP redirects to HTTPS)"
echo "  ✅ Security headers configured"
echo "  ✅ Modern SSL protocols (TLS 1.2+)"
echo "  ✅ Automatic certificate renewal"