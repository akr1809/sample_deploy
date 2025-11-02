# Full-Stack User Management App

A modern full-stack application with React frontend and Express backend that demonstrates CRUD operations with MongoDB.

## Features

- ✨ Clean, responsive user interface
- 🚀 Real-time user list updates
- 📝 Form validation and error handling
- 🔄 Loading states for better UX
- 🗄️ MongoDB integration
- 🛠️ Single command development workflow

## Tech Stack

- **Frontend**: React, CSS3, Responsive Design
- **Backend**: Express.js, Node.js
- **Database**: MongoDB
- **Development**: Concurrently for running both services

## Quick Start

1. **Install dependencies**:
   ```bash
   npm install
   npm run install-all
   ```

2. **Set up MongoDB**:
   - Make sure MongoDB is running locally on port 27017
   - Or update the connection string in `backend/.env`

3. **Start the application**:
   ```bash
   npm run dev
   ```

4. **Open your browser**:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:5000

## Project Structure

```
├── package.json          # Root package with dev scripts
├── backend/              # Express.js API server
│   ├── server.js         # Main server file
│   ├── routes/           # API routes
│   ├── models/           # Database models
│   └── package.json      # Backend dependencies
├── frontend/             # React application
│   ├── src/              # React components
│   ├── public/           # Static files
│   └── package.json      # Frontend dependencies
└── README.md
```

## API Endpoints

- `GET /api/users` - Fetch all users
- `POST /api/users` - Create new user
- `DELETE /api/users/:id` - Delete user

## 🚀 Production Deployment on AWS Lightsail

### Quick Start (Recommended) - Server-Side Deployment
```bash
# 1. SSH into your Lightsail server
ssh ubuntu@YOUR_LIGHTSAIL_IP

# 2. Run one-liner deployment
curl -fsSL https://raw.githubusercontent.com/akr1809/sample_deploy/add-users-app/scripts/quick-deploy.sh | bash
```

### Alternative: Local to Remote Deployment
```bash
# Deploy from your local machine (requires SSH setup)
./one-click-deploy.sh
```

### Manual Deployment Steps
1. **Create Lightsail Instance**: Ubuntu 22.04 LTS, $10/month plan
2. **SSH to server**: `ssh ubuntu@YOUR_SERVER_IP`
3. **Run server deployment**: `./scripts/server-deploy.sh`
4. **Set up SSL**: `./scripts/ssl-setup.sh yourdomain.com` (optional)

### Documentation
- 📖 **Complete Guide**: [DEPLOYMENT.md](./DEPLOYMENT.md)
- ✅ **Quick Checklist**: [DEPLOYMENT-CHECKLIST.md](./DEPLOYMENT-CHECKLIST.md)

### Production Features
- 🐳 **Dockerized**: All services run in containers
- 🔒 **SSL Ready**: Automatic HTTPS with Let's Encrypt
- 🌐 **Nginx Proxy**: Optimized static file serving
- 📊 **Health Checks**: Automated service monitoring
- 🔄 **Auto-restart**: Services restart on failure
- 📈 **Scalable**: Easy to upgrade server resources

### Cost: ~$10-15/month
- Lightsail: $10/month (2GB RAM recommended)
- Domain: $12/year (optional)
- SSL Certificate: Free (Let's Encrypt)


The Root Cause
The issue was:

npm ci --only=production excludes devDependencies
react-scripts is a devDependency (needed for npm run build)
Without react-scripts, the build fails
The fix:

Use npm ci (without --only=production) in the build stage
This installs ALL dependencies including react-scripts
Then npm run build works properly
Try the first fix and you should see the React build complete successfully! The static files will then be properly copied to nginx and your app will work at http://13.204.124.72 🎉

Let me know what the build logs show now!