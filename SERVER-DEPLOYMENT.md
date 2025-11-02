# 🖥️ Server-Side Deployment Guide

Simple deployment that runs directly on your Lightsail server - no SSH key issues!

## 🚀 Quick Deployment (Easiest Method)

### Step 1: Create Lightsail Instance
1. Go to [AWS Lightsail Console](https://lightsail.aws.amazon.com/)
2. Create **Ubuntu 22.04 LTS** instance 
3. Choose **$10/month** plan (2GB RAM recommended)
4. Attach **static IP**
5. Configure firewall: **SSH (22), HTTP (80), HTTPS (443)**

### Step 2: Connect to Server
```bash
# Use Lightsail browser-based SSH (easiest)
# OR connect via terminal:
ssh ubuntu@YOUR_LIGHTSAIL_IP
```

### Step 3: One-Line Deployment
```bash
# Copy and paste this single command:
curl -fsSL https://raw.githubusercontent.com/akr1809/sample_deploy/add-users-app/scripts/quick-deploy.sh | bash
```

**That's it!** ✨ Your app will be live at `http://YOUR_LIGHTSAIL_IP`

---

## 🔧 Advanced Server Deployment

### Method 1: Download and Run Script
```bash
# On your Lightsail server:
wget https://raw.githubusercontent.com/akr1809/sample_deploy/add-users-app/scripts/server-deploy.sh
chmod +x server-deploy.sh
./server-deploy.sh
```

### Method 2: Clone Repository
```bash
# On your Lightsail server:
git clone -b add-users-app https://github.com/akr1809/sample_deploy.git userapp
cd userapp
./scripts/server-deploy.sh
```

---

## ✨ What This Does Automatically

### 🐳 **Docker Installation**
- Installs Docker Engine
- Installs Docker Compose
- Configures user permissions
- Sets up log rotation

### 📦 **Application Setup**
- Clones your application code
- Creates production environment file
- Builds Docker containers:
  - **Frontend**: React + Nginx
  - **Backend**: Node.js + Express
  - **Database**: MongoDB

### 🌐 **Network Configuration**
- Nginx proxy setup
- Port configuration (80, 443)
- Health checks
- Service discovery

---

## 📊 Management Commands

Once deployed, use these commands on your server:

### **Application Status**
```bash
# Check if all services are running
sudo docker-compose ps

# View real-time logs
sudo docker-compose logs -f

# Check individual service
sudo docker-compose logs backend
sudo docker-compose logs frontend
sudo docker-compose logs mongodb
```

### **Application Control**
```bash
# Restart application
sudo docker-compose restart

# Stop application
sudo docker-compose down

# Start application
sudo docker-compose up -d

# Rebuild and restart
sudo docker-compose up --build -d
```

### **Updates & Maintenance**
```bash
# Update to latest code
cd ~/userapp
git pull origin add-users-app
sudo docker-compose up --build -d

# Or re-run deployment script
./server-deploy.sh
```

---

## 🔒 SSL Setup (Optional)

### Step 1: Point Domain to Server
Update your domain's DNS A record:
```
Type: A
Name: @ (or subdomain)
Value: YOUR_LIGHTSAIL_IP
```

### Step 2: Install SSL Certificate
```bash
# On your server
cd ~/userapp
./scripts/ssl-setup.sh yourdomain.com
```

---

## 🛠️ Troubleshooting

### **If Deployment Fails**

1. **Check Docker Installation**
   ```bash
   docker --version
   docker-compose --version
   ```

2. **Check User Permissions**
   ```bash
   groups $USER  # Should include 'docker'
   
   # If not in docker group:
   sudo usermod -aG docker $USER
   # Then logout and login again
   ```

3. **Check Service Status**
   ```bash
   sudo docker-compose ps
   sudo docker-compose logs
   ```

### **Common Issues**

| Issue | Solution |
|-------|----------|
| "Permission denied" | `sudo usermod -aG docker $USER`, then re-login |
| "Port already in use" | `sudo docker-compose down` first |
| "Cannot connect to daemon" | `sudo systemctl start docker` |
| "No space left" | `sudo docker system prune -a` |

### **Service Not Starting**
```bash
# Check logs for specific service
sudo docker-compose logs mongodb
sudo docker-compose logs backend
sudo docker-compose logs frontend

# Restart specific service
sudo docker-compose restart backend
```

---

## 💾 Database Management

### **Access MongoDB**
```bash
# MongoDB shell
sudo docker-compose exec mongodb mongosh userapp

# View users
sudo docker-compose exec mongodb mongosh userapp --eval "db.users.find().pretty()"

# Backup database
sudo docker-compose exec mongodb mongodump --db userapp --out /backup
sudo docker cp userapp-mongodb:/backup ./mongodb-backup-$(date +%Y%m%d)
```

### **Use MongoDB Management Script**
```bash
cd ~/userapp
./scripts/mongo-manage.sh status    # Check MongoDB status
./scripts/mongo-manage.sh backup    # Create backup
./scripts/mongo-manage.sh shell     # Access MongoDB shell
./scripts/mongo-manage.sh users     # View application users
```

---

## 📈 Monitoring & Maintenance

### **Resource Monitoring**
```bash
# System resources
htop                    # CPU, memory usage
df -h                   # Disk space
free -h                 # Memory usage

# Docker resources
sudo docker stats       # Container resource usage
sudo docker system df   # Docker disk usage
```

### **Log Management**
```bash
# Application logs
sudo docker-compose logs -f --tail=100

# System logs
sudo journalctl -f

# Clean old logs
sudo docker system prune -a
```

### **Automated Backups**
```bash
# Create backup script
cat << 'EOF' > ~/backup-app.sh
#!/bin/bash
cd ~/userapp
sudo docker-compose exec -T mongodb mongodump --db userapp --archive | gzip > ~/backups/userapp-$(date +%Y%m%d).gz
find ~/backups -name "userapp-*.gz" -mtime +7 -delete
EOF

chmod +x ~/backup-app.sh

# Schedule daily backups
echo "0 2 * * * /home/ubuntu/backup-app.sh" | crontab -
```

---

## 🎯 Benefits of Server-Side Deployment

✅ **No SSH Key Issues** - No need to manage SSH keys locally  
✅ **Simpler Process** - Just connect and run one command  
✅ **Direct Control** - Run commands directly on server  
✅ **Easier Troubleshooting** - Debug issues on the server itself  
✅ **Faster Updates** - Pull updates directly from Git  
✅ **Better Security** - No need to transfer files over network  

---

## 📞 Quick Reference

### **Deploy Application**
```bash
ssh ubuntu@YOUR_LIGHTSAIL_IP
curl -fsSL https://raw.githubusercontent.com/akr1809/sample_deploy/add-users-app/scripts/quick-deploy.sh | bash
```

### **Check Status**
```bash
sudo docker-compose ps
```

### **View Logs**
```bash
sudo docker-compose logs -f
```

### **Update Application**
```bash
cd ~/userapp && ./server-deploy.sh
```

### **Setup SSL**
```bash
cd ~/userapp && ./scripts/ssl-setup.sh yourdomain.com
```

**Your app will be live at:** `http://YOUR_LIGHTSAIL_IP` 🎉