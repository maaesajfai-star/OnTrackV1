# OnTrack - Production Deployment Quick Start

## 🚀 5-Minute Production Deployment

### Prerequisites
- Docker 24.x+ installed
- Docker Compose 2.x+ installed
- 8GB RAM, 50GB disk space
- Git installed

---

## Step 1: Clone & Configure (2 minutes)

```bash
# Clone repository
git clone <your-repo-url>
cd claude-Version1

# Copy environment template
cp .env.example .env

# Generate strong JWT secrets (CRITICAL!)
echo "JWT_SECRET=$(openssl rand -base64 32)" >> .env
echo "JWT_REFRESH_SECRET=$(openssl rand -base64 32)" >> .env

# Edit .env file - MUST change these values:
nano .env
```

### Required .env Changes:
```bash
NODE_ENV=production                                    # Change from development
POSTGRES_PASSWORD=<YOUR_SECURE_PASSWORD>               # Change this!
NEXTCLOUD_DB_PASSWORD=<YOUR_SECURE_PASSWORD>           # Change this!
NEXTCLOUD_ADMIN_PASSWORD=<YOUR_SECURE_PASSWORD>        # Change this!
CORS_ORIGIN=https://your-production-domain.com         # Change to your domain
```

---

## Step 2: Build & Deploy (2 minutes)

```bash
# Build images (no cache for clean production build)
docker compose build --no-cache --pull

# Start all services in detached mode
docker compose up -d

# Watch backend startup (wait for "Nest application successfully started")
docker compose logs -f backend
```

Press `Ctrl+C` when you see the success message.

---

## Step 3: Verify & Secure (1 minute)

```bash
# Check all services are healthy
docker compose ps

# Verify backend health
curl http://localhost/api/v1/health

# Expected response:
# {"status":"ok","timestamp":"...","uptime":...,"environment":"production","version":"1.0.0","service":"OnTrack Backend API"}

# Access the application
# - Frontend: http://localhost
# - API Docs: http://localhost/api/docs
# - NextCloud: http://localhost/nextcloud

# Default admin login (CHANGE IMMEDIATELY):
# Username: Admin
# Password: AdminAdmin@123
```

---

## Step 4: Post-Deployment Security

### CRITICAL - Do These Immediately:

1. **Change Admin Password**
   - Login with default credentials
   - Navigate to user settings
   - Change password to a strong one
   - Save and re-login

2. **Disable Demo Accounts** (Optional)
   ```bash
   # Connect to database
   docker compose exec postgres psql -U ontrack_user -d ontrack_db

   # Disable demo accounts
   UPDATE users SET "isActive" = false WHERE username IN ('hrmanager', 'salesuser');

   # Exit
   \q
   ```

3. **Verify Secrets Not Exposed**
   ```bash
   # Check .env has correct permissions
   chmod 600 .env

   # Verify .env is in .gitignore
   git check-ignore .env  # Should output: .env

   # Ensure no secrets in logs
   docker compose logs backend | grep -i "JWT_SECRET"  # Should show nothing
   ```

---

## Backup Setup (Recommended)

```bash
# Create backup script
cat > /home/backup-ontrack.sh <<'EOF'
#!/bin/bash
BACKUP_DIR="/home/ontrack-backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup OnTrack database
docker compose exec -T postgres pg_dump -U ontrack_user ontrack_db > $BACKUP_DIR/ontrack_$DATE.sql

# Backup NextCloud database
docker compose exec -T nextcloud-db pg_dump -U nextcloud nextcloud > $BACKUP_DIR/nextcloud_$DATE.sql

# Keep only last 7 days
find $BACKUP_DIR -name "*.sql" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /home/backup-ontrack.sh

# Test backup
/home/backup-ontrack.sh

# Add to cron (daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /home/backup-ontrack.sh") | crontab -
```

---

## SSL/TLS Setup (Production Required)

### Option 1: Using Let's Encrypt (Recommended)

```bash
# Install certbot
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# Stop nginx container temporarily
docker compose stop nginx

# Generate certificates
sudo certbot certonly --standalone -d your-domain.com

# Certificates will be in:
# /etc/letsencrypt/live/your-domain.com/fullchain.pem
# /etc/letsencrypt/live/your-domain.com/privkey.pem

# Update docker-compose.yml nginx volumes:
volumes:
  - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
  - ./nginx/conf.d:/etc/nginx/conf.d:ro
  - /etc/letsencrypt:/etc/letsencrypt:ro  # Add this line

# Update nginx configuration for HTTPS (create nginx/conf.d/ssl.conf)
# Restart nginx
docker compose up -d nginx

# Set up auto-renewal
sudo certbot renew --dry-run
```

### Option 2: Using Your Own Certificates

```bash
# Create SSL directory
mkdir -p nginx/ssl

# Copy your certificates
cp your-cert.crt nginx/ssl/
cp your-key.key nginx/ssl/

# Update docker-compose.yml nginx volumes:
volumes:
  - ./nginx/ssl:/etc/nginx/ssl:ro
```

---

## Monitoring & Health Checks

### Check Service Status
```bash
# View all containers
docker compose ps

# Check logs
docker compose logs backend --tail=100
docker compose logs frontend --tail=100
docker compose logs postgres --tail=50

# Real-time logs
docker compose logs -f backend
```

### Health Endpoints
```bash
# Backend health
curl http://localhost/api/v1/health

# Nginx health
curl http://localhost/health

# Database check
docker compose exec postgres pg_isready -U ontrack_user
```

---

## Common Issues & Solutions

### Issue: Backend won't start

```bash
# Check database connectivity
docker compose exec backend nc -zv postgres 5432

# Run migrations manually
docker compose exec backend npm run migration:run

# Rebuild backend
docker compose build --no-cache backend
docker compose up -d backend
```

### Issue: JWT authentication errors

```bash
# Verify JWT_SECRET is set
docker compose exec backend env | grep JWT_SECRET

# Should be 32+ characters, not default value
# If not set properly, stop services and fix .env
docker compose down
nano .env  # Fix JWT_SECRET and JWT_REFRESH_SECRET
docker compose up -d
```

### Issue: Permission denied errors

```bash
# Fix entrypoint permissions
chmod +x backend/docker-entrypoint.sh

# Fix .env permissions
chmod 600 .env

# Restart services
docker compose restart
```

### Issue: Port already in use

```bash
# Check what's using port 80
sudo lsof -i :80

# Either stop that service or change OnTrack's port
# Edit docker-compose.yml:
ports:
  - "8080:80"  # Change to different port
```

---

## Scaling & Performance

### Increase Database Connections
```bash
# Edit .env
DB_POOL_MIN=5
DB_POOL_MAX=20

# Restart backend
docker compose restart backend
```

### Allocate More Resources
```bash
# Edit docker-compose.yml for backend service:
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 2G
    reservations:
      cpus: '0.5'
      memory: 1G
```

---

## Maintenance Commands

```bash
# View resource usage
docker stats

# Clean up old containers and images
docker system prune -a

# Update OnTrack (pull latest code)
git pull origin main
docker compose build --no-cache
docker compose up -d

# Restart specific service
docker compose restart backend

# View backend shell (debugging)
docker compose exec backend sh

# Database shell
docker compose exec postgres psql -U ontrack_user -d ontrack_db
```

---

## Default Accounts (Development/Demo)

| Username  | Email                | Password       | Role       |
|-----------|----------------------|----------------|------------|
| Admin     | admin@ontrack.local  | AdminAdmin@123 | admin      |
| hrmanager | hr@ontrack.com       | HR@123456      | hr_manager |
| salesuser | sales@ontrack.com    | Sales@123456   | sales_user |

**⚠️ SECURITY WARNING**: Change the admin password and disable/delete demo accounts in production!

---

## Production Checklist

- [ ] JWT secrets generated (32+ characters)
- [ ] All passwords changed from defaults
- [ ] NODE_ENV=production in .env
- [ ] CORS_ORIGIN set to production domain
- [ ] .env permissions set to 600
- [ ] SSL/TLS certificates configured
- [ ] Admin password changed after first login
- [ ] Demo accounts disabled or deleted
- [ ] Backups configured and tested
- [ ] Health checks verified
- [ ] Monitoring/alerting set up (optional)
- [ ] Firewall rules configured
- [ ] Rate limiting configured appropriately

---

## Support

- **Full Documentation**: See `PRODUCTION_DEPLOYMENT_REPORT.md`
- **Detailed README**: See `README.md`
- **Troubleshooting**: See `TROUBLESHOOTING.md`
- **Environment Variables**: See `.env.example`

---

## Quick Commands Reference

```bash
# Start everything
docker compose up -d

# Stop everything
docker compose down

# Restart backend only
docker compose restart backend

# View logs (follow)
docker compose logs -f backend

# Check health
curl http://localhost/api/v1/health

# Backup databases
/home/backup-ontrack.sh

# Update application
git pull && docker compose build --no-cache && docker compose up -d

# Emergency stop
docker compose down --remove-orphans
```

---

**Version**: OnTrack v1.0.0
**Last Updated**: January 1, 2026

For comprehensive deployment guide, see: `PRODUCTION_DEPLOYMENT_REPORT.md`
