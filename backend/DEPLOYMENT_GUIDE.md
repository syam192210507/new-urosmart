# UroSmart Backend Deployment Guide

Quick deployment guides for various platforms.

---

## 🚀 Local Development

```bash
cd /Users/sail/Desktop/UroSmart/backend
./run.sh
```

Server: `http://localhost:5000`

---

## 🐳 Docker Deployment

### Quick Start
```bash
cd backend
docker-compose up -d
```

### Custom Build
```bash
docker build -t urosmart-backend .
docker run -d -p 5000:5000 \
  -e SECRET_KEY="your-secret" \
  -e JWT_SECRET_KEY="your-jwt-secret" \
  urosmart-backend
```

---

## ☁️ Heroku Deployment

### Setup
```bash
# Install Heroku CLI
brew install heroku/brew/heroku

# Login
heroku login

# Create app
cd backend
heroku create urosmart-backend

# Set environment variables
heroku config:set SECRET_KEY="$(openssl rand -hex 32)"
heroku config:set JWT_SECRET_KEY="$(openssl rand -hex 32)"

# Add PostgreSQL
heroku addons:create heroku-postgresql:mini

# Deploy
git init
git add .
git commit -m "Initial deployment"
heroku git:remote -a urosmart-backend
git push heroku main
```

### Update iOS App
```swift
private let baseURL = "https://urosmart-backend.herokuapp.com/api"
```

---

## 🌊 DigitalOcean App Platform

### Via Web Console
1. Go to https://cloud.digitalocean.com/apps
2. Click "Create App"
3. Connect GitHub repository
4. Select `backend` directory
5. Set environment variables:
   - `SECRET_KEY`
   - `JWT_SECRET_KEY`
   - `DATABASE_URL` (optional, uses SQLite by default)
6. Click "Deploy"

### Via CLI
```bash
# Install doctl
brew install doctl

# Authenticate
doctl auth init

# Create app spec
cat > app.yaml <<EOF
name: urosmart-backend
services:
- name: api
  github:
    repo: your-username/urosmart
    branch: main
    deploy_on_push: true
  source_dir: /backend
  run_command: gunicorn -w 4 -b 0.0.0.0:8080 app:app
  http_port: 8080
  envs:
  - key: SECRET_KEY
    value: "your-secret-key"
  - key: JWT_SECRET_KEY
    value: "your-jwt-secret"
EOF

# Deploy
doctl apps create --spec app.yaml
```

---

## 🔶 AWS EC2 Deployment

### Launch Instance
```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y python3-pip python3-venv nginx git

# Clone repository
git clone https://github.com/your-username/urosmart.git
cd urosmart/backend

# Setup Python environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Create .env file
cat > .env <<EOF
SECRET_KEY=$(openssl rand -hex 32)
JWT_SECRET_KEY=$(openssl rand -hex 32)
DEBUG=False
DATABASE_URL=sqlite:///urosmart.db
EOF

# Test run
python app.py
```

### Setup Systemd Service
```bash
sudo nano /etc/systemd/system/urosmart.service
```

```ini
[Unit]
Description=UroSmart Backend API
After=network.target

[Service]
User=ubuntu
WorkingDirectory=/home/ubuntu/urosmart/backend
Environment="PATH=/home/ubuntu/urosmart/backend/venv/bin"
ExecStart=/home/ubuntu/urosmart/backend/venv/bin/gunicorn -w 4 -b 127.0.0.1:5000 app:app

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl enable urosmart
sudo systemctl start urosmart
sudo systemctl status urosmart
```

### Configure Nginx
```bash
sudo nano /etc/nginx/sites-available/urosmart
```

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/urosmart /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Setup SSL with Let's Encrypt
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

---

## 🔷 Azure App Service

### Via Azure CLI
```bash
# Install Azure CLI
brew install azure-cli

# Login
az login

# Create resource group
az group create --name urosmart-rg --location eastus

# Create App Service plan
az appservice plan create \
  --name urosmart-plan \
  --resource-group urosmart-rg \
  --sku B1 \
  --is-linux

# Create web app
az webapp create \
  --resource-group urosmart-rg \
  --plan urosmart-plan \
  --name urosmart-backend \
  --runtime "PYTHON:3.11"

# Configure environment variables
az webapp config appsettings set \
  --resource-group urosmart-rg \
  --name urosmart-backend \
  --settings SECRET_KEY="your-secret" JWT_SECRET_KEY="your-jwt-secret"

# Deploy
cd backend
zip -r deploy.zip .
az webapp deployment source config-zip \
  --resource-group urosmart-rg \
  --name urosmart-backend \
  --src deploy.zip
```

---

## 🟢 Render Deployment

### Via Web Console
1. Go to https://render.com
2. Click "New +" → "Web Service"
3. Connect GitHub repository
4. Configure:
   - **Name**: urosmart-backend
   - **Root Directory**: backend
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn -w 4 -b 0.0.0.0:$PORT app:app`
5. Add environment variables:
   - `SECRET_KEY`
   - `JWT_SECRET_KEY`
   - `PYTHON_VERSION`: 3.11.0
6. Click "Create Web Service"

### Via render.yaml
```yaml
services:
  - type: web
    name: urosmart-backend
    env: python
    region: oregon
    plan: starter
    buildCommand: pip install -r requirements.txt
    startCommand: gunicorn -w 4 -b 0.0.0.0:$PORT app:app
    envVars:
      - key: SECRET_KEY
        generateValue: true
      - key: JWT_SECRET_KEY
        generateValue: true
      - key: PYTHON_VERSION
        value: 3.11.0
```

---

## 🗄️ Database Options

### SQLite (Development)
```bash
DATABASE_URL=sqlite:///urosmart.db
```

### PostgreSQL (Production)

#### Heroku Postgres
```bash
heroku addons:create heroku-postgresql:mini
# DATABASE_URL set automatically
```

#### DigitalOcean Managed Database
```bash
# Create database via console
# Get connection string
DATABASE_URL=postgresql://user:pass@host:25060/urosmart?sslmode=require
```

#### AWS RDS
```bash
# Create RDS instance via console
DATABASE_URL=postgresql://admin:password@urosmart.xxxx.us-east-1.rds.amazonaws.com:5432/urosmart
```

#### Self-hosted PostgreSQL
```bash
# Install PostgreSQL
sudo apt install postgresql postgresql-contrib

# Create database
sudo -u postgres psql
CREATE DATABASE urosmart;
CREATE USER urosmart_user WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE urosmart TO urosmart_user;
\q

# Connection string
DATABASE_URL=postgresql://urosmart_user:your_password@localhost:5432/urosmart
```

---

## 🔐 Environment Variables

### Required
```bash
SECRET_KEY=your-secret-key-here
JWT_SECRET_KEY=your-jwt-secret-key-here
```

### Optional
```bash
DEBUG=False
DATABASE_URL=postgresql://user:pass@host:5432/dbname
PORT=5000
MAX_CONTENT_LENGTH=16777216
```

### Generate Secure Keys
```bash
# On Mac/Linux
openssl rand -hex 32

# Or Python
python -c "import secrets; print(secrets.token_hex(32))"
```

---

## 📱 Update iOS App

After deployment, update `NetworkService.swift`:

```swift
// Development
private let baseURL = "http://localhost:5000/api"

// Production
private let baseURL = "https://your-domain.com/api"
```

And update `Info.plist`:

```xml
<!-- Development: Allow HTTP -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsLocalNetworking</key>
    <true/>
</dict>

<!-- Production: Remove NSAllowsArbitraryLoads, use HTTPS -->
```

---

## ✅ Post-Deployment Checklist

- [ ] Backend is accessible via HTTPS
- [ ] Health check endpoint works: `curl https://your-domain.com/api/health`
- [ ] Environment variables are set
- [ ] Database is configured
- [ ] iOS app updated with production URL
- [ ] Test signup/login from iOS app
- [ ] Test report creation from iOS app
- [ ] Monitor logs for errors
- [ ] Set up database backups
- [ ] Configure monitoring/alerts

---

## 📊 Monitoring

### Heroku
```bash
heroku logs --tail
heroku ps
```

### DigitalOcean
- View logs in App Platform console
- Set up alerts for errors

### AWS CloudWatch
```bash
# View logs
aws logs tail /aws/elasticbeanstalk/urosmart/var/log/web.stdout.log --follow
```

### Custom Logging
Add to `app.py`:
```python
import logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

@app.route('/api/auth/login', methods=['POST'])
def login():
    logger.info(f"Login attempt for: {data.get('email')}")
    # ... rest of code
```

---

## 🔄 CI/CD Setup

### GitHub Actions
Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Deploy to Heroku
        uses: akhileshns/heroku-deploy@v3.12.12
        with:
          heroku_api_key: ${{secrets.HEROKU_API_KEY}}
          heroku_app_name: "urosmart-backend"
          heroku_email: "your-email@example.com"
          appdir: "backend"
```

---

## 🆘 Troubleshooting

### Application Error
```bash
# Check logs
heroku logs --tail

# Restart
heroku restart
```

### Database Connection Error
```bash
# Verify DATABASE_URL
heroku config:get DATABASE_URL

# Reset database
heroku pg:reset DATABASE_URL
```

### Port Binding Error
```python
# Ensure app.py uses PORT from environment
port = int(os.environ.get('PORT', 5000))
app.run(host='0.0.0.0', port=port)
```

---

## 💰 Cost Estimates

### Free Tier Options
- **Heroku**: Free dyno (sleeps after 30 min inactivity)
- **Render**: Free tier available
- **Railway**: $5 free credit monthly

### Paid Options
- **Heroku Hobby**: $7/month
- **DigitalOcean App Platform**: $5/month
- **AWS EC2 t2.micro**: ~$10/month
- **Render Starter**: $7/month

### Database
- **Heroku Postgres Mini**: $5/month
- **DigitalOcean Managed DB**: $15/month
- **AWS RDS db.t3.micro**: ~$15/month

---

## 🎯 Recommended Setup

### For Development
- Local: `./run.sh`
- Database: SQLite
- Cost: Free

### For Testing/Staging
- Platform: Render or Railway
- Database: Included PostgreSQL
- Cost: Free or $5-7/month

### For Production
- Platform: DigitalOcean App Platform or AWS
- Database: Managed PostgreSQL
- CDN: CloudFlare (free)
- Monitoring: Sentry (free tier)
- Cost: $20-30/month

---

**Choose your platform and follow the guide above!** 🚀
