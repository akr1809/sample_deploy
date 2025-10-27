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

## Production Deployment

1. Build the frontend: `npm run build`
2. Start the production server: `npm start`