#!/bin/bash

echo "🚀 Setting up Full-Stack User Management App"
echo "=============================================="

# Check if MongoDB is running
if pgrep -x "mongod" > /dev/null; then
    echo "✅ MongoDB is already running"
else
    echo "⚠️  MongoDB is not running. Starting MongoDB..."
    
    # Try to start MongoDB with brew services
    if command -v brew >/dev/null 2>&1; then
        echo "🍺 Attempting to start MongoDB via Homebrew..."
        brew services start mongodb-community || echo "❌ Failed to start MongoDB via brew services"
    fi
    
    # Create data directories if they don't exist
    mkdir -p ~/data/db ~/data/log
    
    # Try to start MongoDB manually
    echo "📁 Starting MongoDB with manual configuration..."
    if command -v mongod >/dev/null 2>&1; then
        mongod --dbpath ~/data/db --logpath ~/data/log/mongod.log --fork --bind_ip 127.0.0.1 --port 27017
    else
        echo "❌ MongoDB (mongod) not found in PATH"
        echo "📋 Please install MongoDB:"
        echo "   macOS: brew install mongodb-community"
        echo "   Ubuntu: sudo apt-get install mongodb"
        echo "   Windows: Download from https://www.mongodb.com/try/download/community"
        exit 1
    fi
fi

echo ""
echo "📦 Installing dependencies..."
npm install
npm run install-all

echo ""
echo "🎯 Application is ready!"
echo "To start the development servers:"
echo "  npm run dev"
echo ""
echo "Then open your browser to:"
echo "  Frontend: http://localhost:3000"
echo "  Backend API: http://localhost:5000"
echo ""
echo "🎉 Happy coding!"