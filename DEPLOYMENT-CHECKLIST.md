# Quick Start Deployment Checklist

## ✅ Pre-Deployment Checklist

### AWS Lightsail Setup
- [ ] AWS account created
- [ ] Lightsail instance launched (Ubuntu 22.04 LTS)
- [ ] Instance size: $10/month (2GB RAM) minimum
- [ ] Static IP attached
- [ ] Firewall ports opened (22, 80, 443)
- [ ] SSH access configured

### Domain Setup (Optional)
- [ ] Domain purchased
- [ ] DNS A record pointing to static IP
- [ ] DNS propagation confirmed (`nslookup yourdomain.com`)

## 🚀 Deployment Steps

### Step 1: Server Setup
```bash
# Connect to server
ssh ubuntu@YOUR_STATIC_IP

# Run setup script
./server-setup.sh

# Reconnect after setup
exit && ssh ubuntu@YOUR_STATIC_IP
```

### Step 2: Deploy Application
```bash
# Option A: Automated (from local machine)
./scripts/deploy.sh YOUR_STATIC_IP

# Option B: Manual upload
scp userapp.tar.gz ubuntu@YOUR_STATIC_IP:~/
ssh ubuntu@YOUR_STATIC_IP
tar -xzf userapp.tar.gz && cd userapp
sudo docker-compose up --build -d
```

### Step 3: Verify Deployment
```bash
# Check services
sudo docker-compose ps

# Test application
curl http://YOUR_STATIC_IP/api/health
```

### Step 4: SSL Setup (If using domain)
```bash
# On server
./ssl-setup.sh yourdomain.com
```

## 📋 Post-Deployment Tasks

### Immediate
- [ ] Application accessible via HTTP
- [ ] API health check passes
- [ ] User registration/listing works
- [ ] SSL certificate installed (if domain used)

### Within 24 hours
- [ ] Monitor server resources (`htop`, `df -h`)
- [ ] Set up monitoring alerts
- [ ] Create first database backup
- [ ] Document server access details

### Within 1 week
- [ ] Set up automated backups
- [ ] Performance testing
- [ ] Security audit
- [ ] Update documentation with final URLs

## 🔧 Essential Commands Reference

```bash
# Service Management
sudo docker-compose ps              # Check status
sudo docker-compose logs -f         # View logs
sudo docker-compose restart         # Restart all
sudo docker-compose down           # Stop all

# System Monitoring
htop                               # Resource usage
df -h                              # Disk space
free -h                            # Memory usage
sudo ufw status                    # Firewall status

# SSL Management
sudo certbot certificates          # Check certificates
sudo certbot renew --dry-run      # Test renewal

# Database Backup
sudo docker-compose exec mongodb mongodump --out /backup
```

## 🆘 Emergency Contacts & Info

```bash
Server IP: ___________________
Domain: ______________________
SSH Key Location: ____________
Admin Email: _________________

Lightsail Console: https://lightsail.aws.amazon.com/
Application URL: http://YOUR_IP or https://yourdomain.com
```

## 📞 Quick Troubleshooting

| Issue | Quick Fix |
|-------|-----------|
| App not loading | `sudo docker-compose restart` |
| SSL certificate error | `./ssl-setup.sh yourdomain.com` |
| Database connection failed | `sudo docker-compose logs mongodb` |
| Out of disk space | `sudo docker system prune -a` |
| High memory usage | Upgrade Lightsail instance |

---

**Need Help?** 
1. Check logs: `sudo docker-compose logs -f`
2. Restart services: `sudo docker-compose restart`
3. Review DEPLOYMENT.md for detailed troubleshooting