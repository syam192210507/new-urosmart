# 🚀 Production Deployment Guide

Your application architecture is secure, but your **configuration** needs to be updated before you deploy to a real server.

## 🛑 Critical Security Checklist

### 1. Change Default Passwords
**Risk**: High. Hackers know the default `changeme` password.
- [ ] Open `.env` (create it if missing based on `.env.example`) on your server.
- [ ] Set a strong `POSTGRES_PASSWORD`.
- [ ] Update `DATABASE_URL` to match the new password.

### 2. Rotate Secret Keys
**Risk**: High. `dev-secret-key` allows hackers to forge login tokens.
- [ ] Generate a random string (e.g., `openssl rand -hex 32`).
- [ ] Set `SECRET_KEY` and `JWT_SECRET_KEY` in `.env`.

### 3. Disable Debug Mode
**Risk**: Medium. Debug mode shows code snippets when errors occur.
- [ ] Set `DEBUG=False` in `.env`.

### 4. Get Real SSL Certificates
**Risk**: Medium. Self-signed certs scare users with browser warnings.
- [ ] Buy a domain name (e.g., `urosmart.com`).
- [ ] Point the domain to your server's IP.
- [ ] Use Certbot to get a free, valid certificate:
  ```bash
  # Example command (depends on your OS)
  sudo certbot --nginx -d urosmart.com
  ```

## 🛡️ Architecture Security (Already Done ✅)
- **Database**: PostgreSQL is isolated in Docker.
- **Firewall**: `setup_firewall.sh` is ready to lock down ports.
- **Network**: Nginx is set up as a reverse proxy.
- **App Logic**: Input validation and secure file handling are implemented.

## 📝 Deployment Steps
1. **Copy Code**: `git clone` your repo to the server.
2. **Setup Env**: Create `.env` with strong secrets.
3. **Firewall**: Run `sudo ./setup_firewall.sh`.
4. **Start**: Run `./start_secure_app.sh`.
