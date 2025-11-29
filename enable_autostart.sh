#!/bin/bash

# Only for Linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    echo "🐧 Linux detected. Enabling Docker autostart..."
    
    if [ "$EUID" -ne 0 ]; then 
        echo "⚠️  Please run as root (sudo) to enable system services."
        exit 1
    fi

    # Enable Docker service
    systemctl enable docker
    systemctl start docker
    echo "✅ Docker service enabled."

    # Start the app (if not running)
    ./start_secure_app.sh
    
    echo "✅ Autostart configured! Your app will now start automatically when the server reboots."
else
    echo "🍎 Mac/Windows detected."
    echo "   Docker Desktop usually handles autostart settings in its Preferences."
    echo "   Please check Docker Desktop > Settings > General > 'Start Docker Desktop when you log in'."
fi
