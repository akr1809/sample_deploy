# 🍃 MongoDB Docker Management on AWS Lightsail

Complete guide for running and managing MongoDB in Docker containers on your Lightsail server.

## 🚀 Quick Start - MongoDB is Already Running!

When you deploy your application using `./one-click-deploy.sh`, MongoDB automatically starts as part of the Docker Compose stack.

### Check if MongoDB is Running
```bash
# Connect to your server
ssh ubuntu@YOUR_LIGHTSAIL_IP

# Navigate to app directory
cd ~/userapp

# Check MongoDB status
sudo docker-compose ps mongodb
```

## 📋 MongoDB Management Commands

### Basic Container Management
```bash
# Check MongoDB container status
sudo docker-compose ps mongodb

# View MongoDB logs
sudo docker-compose logs mongodb
sudo docker-compose logs -f mongodb  # Follow logs

# Restart MongoDB only
sudo docker-compose restart mongodb

# Stop MongoDB
sudo docker-compose stop mongodb

# Start MongoDB
sudo docker-compose start mongodb
```

### Database Access and Queries
```bash
# Access MongoDB shell
sudo docker-compose exec mongodb mongosh userapp

# Quick database check
sudo docker-compose exec mongodb mongosh userapp --eval "db.users.find().pretty()"

# Count users
sudo docker-compose exec mongodb mongosh userapp --eval "db.users.countDocuments()"

# Show collections
sudo docker-compose exec mongodb mongosh userapp --eval "show collections"
```

## 💾 Backup and Restore

### Create Backup
```bash
# Create backup
sudo docker-compose exec mongodb mongodump --db userapp --out /backup

# Copy backup to host
sudo docker cp userapp-mongodb:/backup ./mongodb-backup-$(date +%Y%m%d)
```

### Restore Backup
```bash
# Copy backup to container
sudo docker cp ./mongodb-backup-20231102 userapp-mongodb:/tmp/

# Restore database
sudo docker-compose exec mongodb mongorestore --db userapp --drop /tmp/mongodb-backup-20231102/userapp
```

## 🔧 Running MongoDB Standalone (Alternative Method)

If you need MongoDB running independently of your application:

### Method 1: Standalone Container
```bash
# Run MongoDB as standalone container
sudo docker run -d \
  --name mongodb-standalone \
  -p 27017:27017 \
  -v mongodb_data:/data/db \
  -e MONGO_INITDB_DATABASE=userapp \
  mongo:7.0

# Access shell
sudo docker exec -it mongodb-standalone mongosh
```

### Method 2: Docker Compose Override
Create `docker-compose.override.yml`:
```yaml
version: '3.8'

services:
  mongodb:
    ports:
      - "27017:27017"  # Expose port for external access
    environment:
      - MONGO_INITDB_ROOT_USERNAME=admin
      - MONGO_INITDB_ROOT_PASSWORD=your_secure_password
```

## 🛠️ Advanced MongoDB Configuration

### Custom MongoDB Configuration
Create `mongod.conf`:
```yaml
# MongoDB Configuration File
storage:
  dbPath: /data/db
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

processManagement:
  timeZoneInfo: /usr/share/zoneinfo

security:
  authorization: enabled
```

### Update Docker Compose for Custom Config
```yaml
mongodb:
  image: mongo:7.0
  container_name: userapp-mongodb
  restart: unless-stopped
  environment:
    - MONGO_INITDB_DATABASE=userapp
    - MONGO_INITDB_ROOT_USERNAME=admin
    - MONGO_INITDB_ROOT_PASSWORD=secure_password_here
  volumes:
    - mongodb_data:/data/db
    - ./mongod.conf:/etc/mongod.conf:ro
    - ./mongo-init.js:/docker-entrypoint-initdb.d/mongo-init.js:ro
  command: mongod --config /etc/mongod.conf
  networks:
    - userapp-network
  ports:
    - "27017:27017"
```

## 🔒 Security Configuration

### Enable Authentication
```bash
# Access MongoDB shell as admin
sudo docker-compose exec mongodb mongosh admin

# Create admin user
db.createUser({
  user: "admin",
  pwd: "your_secure_password",
  roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]
})

# Create app user
use userapp
db.createUser({
  user: "appuser",
  pwd: "app_password",
  roles: [ { role: "readWrite", db: "userapp" } ]
})
```

### Update Backend Environment
```bash
# Update .env file
MONGODB_URI=mongodb://appuser:app_password@mongodb:27017/userapp?authSource=userapp
```

## 📊 Monitoring and Maintenance

### Health Checks
```bash
# Check MongoDB health
sudo docker-compose exec mongodb mongosh --eval "db.adminCommand('ping')"

# Check database stats
sudo docker-compose exec mongodb mongosh userapp --eval "db.stats()"

# Monitor connections
sudo docker-compose exec mongodb mongosh --eval "db.serverStatus().connections"
```

### Performance Monitoring
```bash
# Monitor real-time operations
sudo docker-compose exec mongodb mongosh --eval "db.currentOp()"

# Check slow operations
sudo docker-compose exec mongodb mongosh --eval "db.getProfilingStatus()"

# Enable profiling for slow queries (>100ms)
sudo docker-compose exec mongodb mongosh userapp --eval "db.setProfilingLevel(1, {slowms: 100})"
```

### Log Analysis
```bash
# View MongoDB logs
sudo docker-compose logs mongodb | tail -100

# Filter for errors
sudo docker-compose logs mongodb | grep -i error

# Monitor connections
sudo docker-compose logs mongodb | grep -i "connection"
```

## 🔄 Automated Backup Script

Create daily backup cron job:
```bash
#!/bin/bash
# /home/ubuntu/backup-mongodb.sh

BACKUP_DIR="/home/ubuntu/mongodb-backups"
DATE=$(date +%Y%m%d-%H%M%S)

mkdir -p $BACKUP_DIR

cd ~/userapp
sudo docker-compose exec -T mongodb mongodump --db userapp --archive | gzip > "$BACKUP_DIR/userapp-$DATE.gz"

# Keep only last 7 backups
find $BACKUP_DIR -name "userapp-*.gz" -mtime +7 -delete

echo "Backup completed: userapp-$DATE.gz"
```

Add to crontab:
```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * /home/ubuntu/backup-mongodb.sh >> /var/log/mongodb-backup.log 2>&1
```

## 🚨 Troubleshooting

### Common Issues

#### 1. MongoDB Won't Start
```bash
# Check logs
sudo docker-compose logs mongodb

# Check if port is already in use
sudo netstat -tlnp | grep :27017

# Remove and recreate container
sudo docker-compose down
sudo docker-compose up -d mongodb
```

#### 2. Connection Refused
```bash
# Check container is running
sudo docker ps | grep mongo

# Check network connectivity
sudo docker-compose exec backend ping mongodb

# Verify environment variables
sudo docker-compose exec backend printenv | grep MONGO
```

#### 3. Authentication Issues
```bash
# Reset authentication
sudo docker-compose down
sudo docker volume rm userapp_mongodb_data
sudo docker-compose up -d
```

#### 4. Performance Issues
```bash
# Check resource usage
sudo docker stats userapp-mongodb

# Increase container resources in docker-compose.yml
mongodb:
  deploy:
    resources:
      limits:
        memory: 1G
      reservations:
        memory: 512M
```

## 💡 Best Practices

### 1. Regular Backups
- Set up automated daily backups
- Test restore procedures regularly
- Store backups off-server (AWS S3, etc.)

### 2. Monitoring
- Monitor disk space: `df -h`
- Watch memory usage: `free -h`
- Check container health: `sudo docker-compose ps`

### 3. Security
- Use authentication in production
- Limit network access
- Regular security updates

### 4. Performance
- Monitor slow queries
- Index important fields
- Regular maintenance operations

## 🎯 Production Checklist

- [ ] MongoDB container running and healthy
- [ ] Authentication configured
- [ ] Backup strategy implemented
- [ ] Monitoring in place
- [ ] Security hardening complete
- [ ] Performance baseline established
- [ ] Disaster recovery plan documented

## 📞 Quick Commands Reference

```bash
# Status check
sudo docker-compose ps mongodb

# Access shell
sudo docker-compose exec mongodb mongosh userapp

# Create backup
sudo docker-compose exec mongodb mongodump --db userapp --out /backup

# View users
sudo docker-compose exec mongodb mongosh userapp --eval "db.users.find().pretty()"

# Restart MongoDB
sudo docker-compose restart mongodb

# Check logs
sudo docker-compose logs -f mongodb
```