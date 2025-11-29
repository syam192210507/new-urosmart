#!/bin/bash

echo "🚀 Starting UroSmart Secure App..."

# 1. Generate Certificates if missing
if [ ! -f "backend/nginx/certs/nginx-selfsigned.crt" ]; then
    echo "🔒 Generating SSL Certificates..."
    cd backend && ./generate_certs.sh
    cd ..
else
    echo "✅ SSL Certificates found."
fi

# 2. Firewall Setup (Linux Only)
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🛡️  Checking Firewall..."
    # Check if running as root for firewall
    if [ "$EUID" -ne 0 ]; then 
        echo "⚠️  Not running as root. Skipping firewall setup."
        echo "   Run 'sudo ./setup_firewall.sh' manually to secure ports."
    else
        ./setup_firewall.sh
    fi
else
    echo "ℹ️  Skipping Firewall setup (Not on Linux). This is expected for local development."
fi

# 3. Start Docker Containers
echo "🐳 Starting Docker Containers (Postgres + Backend + Nginx)..."
cd backend
docker-compose up --build -d

echo ""
echo "✅ App is running securely!"
echo "👉 API: https://localhost/api/health"
echo "👉 Database: PostgreSQL running on port 5432"
