#!/bin/bash

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root"
  exit
fi

echo "🛡️  Setting up Firewall (UFW)..."

# Reset UFW to default
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (Critical!)
ufw allow 22/tcp
echo "✅ Allowed SSH (Port 22)"

# Allow HTTP
ufw allow 80/tcp
echo "✅ Allowed HTTP (Port 80)"

# Allow HTTPS
ufw allow 443/tcp
echo "✅ Allowed HTTPS (Port 443)"

# Enable UFW
echo "Enabling firewall..."
ufw --force enable

echo "✅ Firewall setup complete!"
ufw status verbose
