# 🚀 AWS Lightsail Deployment Guide

Complete step-by-step guide to deploy your Full-Stack User Management App on AWS Lightsail.

## 📋 Prerequisites

- AWS account with Lightsail access
- SSH key pair (we'll create this)
- Domain name (optional, for SSL)
- Local machine with SSH client

## 🛠️ Step 1: Create AWS Lightsail Instance

### 1.1 Launch Instance
1. Go to [AWS Lightsail Console](https://lightsail.aws.amazon.com/)
2. Click **"Create instance"**
3. **Platform**: Linux/Unix
4. **Blueprint**: OS Only → Ubuntu 22.04 LTS
5. **Instance plan**: 
   - **$10/month** (2 GB RAM, 1 vCPU, 60 GB SSD) - **Recommended**
   - **$5/month** (1 GB RAM) - Minimum for testing
6. **Instance name**: `userapp-server` (or your choice)
7. Click **"Create instance"**

### 1.2 Configure Networking
1. Wait for instance to be **Running**
2. Click on your instance name
3. Go to **"Networking"** tab
4. **Static IP**: Click **"Create static IP"** → **"Attach"**
5. **Firewall**: Add these rules:
   ```
   SSH    TCP  22    (Already present)
   HTTP   TCP  80    ✓ Add this
   HTTPS  TCP  443   ✓ Add this
   ```

### 1.3 Set Up SSH Access
1. Go to **"Connect"** tab
2. **Download default SSH key** (lightsail-key.pem)
3. **Or use your own key**:
   - Go to **Account** → **SSH Keys**
   - Upload your public key
   - Select it when creating instance

## 🔑 Step 2: Connect to Your Server

### 2.1 Connect via SSH
```bash
# If using Lightsail default key
chmod 600 lightsail-key.pem
ssh -i lightsail-key.pem ubuntu@YOUR_STATIC_IP

# If using your own key
ssh ubuntu@YOUR_STATIC_IP
```

### 2.2 Verify Connection
```bash
# Check system info
uname -a
whoami
pwd
```

## ⚙️ Step 3: Set Up the Server

### 3.1 Run Server Setup Script
```bash
# Download and run the setup script
wget https://raw.githubusercontent.com/yourusername/sample_deploy/main/scripts/server-setup.sh
chmod +x server-setup.sh
./server-setup.sh
```

**Or manually copy the script:**
1. Copy the contents of `scripts/server-setup.sh`
2. Create the file: `nano server-setup.sh`
3. Paste the contents and save (Ctrl+X, Y, Enter)
4. Make executable: `chmod +x server-setup.sh`
5. Run: `./server-setup.sh`

### 3.2 Reconnect After Setup
```bash
# Exit and reconnect to apply Docker group changes
exit
ssh ubuntu@YOUR_STATIC_IP
```

### 3.3 Test Docker Installation
```bash
# Test Docker
docker --version
docker run hello-world

# Test Docker Compose
docker-compose --version
```

## 📦 Step 4: Deploy the Application

### 4.1 Option A: Automated Deployment (Recommended)
From your **local machine** (where you have the code):

```bash
# Make deployment script executable
chmod +x scripts/deploy.sh

# Deploy to your server
./scripts/deploy.sh YOUR_STATIC_IP
```

### 4.2 Option B: Manual Deployment
If automated deployment fails, deploy manually:

```bash
# On your local machine, create deployment package
tar -czf userapp.tar.gz \
  backend/ frontend/ docker-compose.yml \
  mongo-init.js .env.production scripts/

# Upload to server
scp userapp.tar.gz ubuntu@YOUR_STATIC_IP:~/

# On server
ssh ubuntu@YOUR_STATIC_IP
tar -xzf userapp.tar.gz
cd userapp/

# Copy environment file
cp .env.production .env

# Build and start
sudo docker-compose up --build -d
```

### 4.3 Verify Deployment
```bash
# Check running containers
sudo docker-compose ps

# Check logs
sudo docker-compose logs -f

# Test the application
curl http://YOUR_STATIC_IP/api/health
```

## 🌐 Step 5: Access Your Application

Open your browser and go to:
- **Application**: `http://YOUR_STATIC_IP`
- **API Health**: `http://YOUR_STATIC_IP/api/health`

## 🔒 Step 6: Set Up SSL (Optional but Recommended)

### 6.1 Point Domain to Server
1. **Buy a domain** (from Namecheap, GoDaddy, etc.)
2. **Add DNS records**:
   ```
   Type: A
   Name: @ (or subdomain)
   Value: YOUR_STATIC_IP
   ```
3. **Wait for propagation** (5-60 minutes)

### 6.2 Install SSL Certificate
```bash
# On server, run SSL setup
cd ~/userapp
./ssl-setup.sh yourdomain.com
```

### 6.3 Access Secure Application
- **HTTPS**: `https://yourdomain.com`
- **HTTP redirects** to HTTPS automatically

## 📊 Step 7: Monitor and Maintain

### 7.1 Essential Commands
```bash
# Check application status
sudo docker-compose ps

# View logs
sudo docker-compose logs -f

# Restart services
sudo docker-compose restart

# Stop application
sudo docker-compose down

# Update application
sudo docker-compose pull
sudo docker-compose up --build -d

# Check server resources
htop
df -h
free -h
```

### 7.2 Backup Database
```bash
# Create MongoDB backup
sudo docker-compose exec mongodb mongodump --out /backup
sudo docker cp userapp-mongodb:/backup ./mongodb-backup-$(date +%Y%m%d)
```

### 7.3 Update Application
```bash
# When you have new code
git pull origin main  # or download new code
sudo docker-compose down
sudo docker-compose up --build -d
```

## 🔧 Troubleshooting

### Common Issues

#### 1. "Connection refused"
```bash
# Check if services are running
sudo docker-compose ps

# Check firewall
sudo ufw status

# Check if ports are listening
sudo netstat -tlnp | grep :80
```

#### 2. "Docker permission denied"
```bash
# Add user to docker group
sudo usermod -aG docker $USER
# Logout and login again
```

#### 3. "MongoDB connection failed"
```bash
# Check MongoDB logs
sudo docker-compose logs mongodb

# Check if MongoDB is healthy
sudo docker-compose exec mongodb mongosh --eval "db.adminCommand('ping')"
```

#### 4. "SSL certificate failed"
```bash
# Check domain DNS
nslookup yourdomain.com

# Test certificate manually
sudo certbot certificates

# Renew certificate
sudo certbot renew --force-renewal
```

### Logs and Debugging
```bash
# Application logs
sudo docker-compose logs -f

# System logs
sudo journalctl -f

# Check disk space
df -h

# Check memory usage
free -h

# Check running processes
ps aux
```

## 💰 Cost Estimation

### Lightsail Costs
- **$5/month**: 1 GB RAM, 1 vCPU, 40 GB SSD
- **$10/month**: 2 GB RAM, 1 vCPU, 60 GB SSD (recommended)
- **$20/month**: 4 GB RAM, 2 vCPU, 80 GB SSD

### Additional Costs
- **Domain**: $10-15/year
- **Backup storage**: ~$1-2/month (optional)

## 🔐 Security Best Practices

1. **Update regularly**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Monitor failed login attempts**:
   ```bash
   sudo tail /var/log/auth.log
   ```

3. **Set up fail2ban** (optional):
   ```bash
   sudo apt install fail2ban
   ```

4. **Regular backups**:
   - Set up automated database backups
   - Store backups off-site

5. **SSL certificate renewal**:
   - Automatic renewal is configured
   - Test with: `sudo certbot renew --dry-run`

## 📞 Support

If you encounter issues:

1. **Check logs**: `sudo docker-compose logs -f`
2. **Restart services**: `sudo docker-compose restart`
3. **Check server resources**: `htop` and `df -h`
4. **Review firewall**: `sudo ufw status`

## 🎉 Success!

Your Full-Stack User Management App is now live on AWS Lightsail!

- ✅ **Scalable**: Easy to upgrade instance size
- ✅ **Secure**: HTTPS, firewall, security headers
- ✅ **Monitored**: Health checks, logs
- ✅ **Maintainable**: Docker containers, easy updates