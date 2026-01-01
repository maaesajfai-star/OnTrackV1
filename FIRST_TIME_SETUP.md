# OnTrack - First Time Setup (After Clone)

## 🚀 Quick Start (3 steps)

After cloning this repo, run these 3 commands:

```bash
# 1. Generate .env file with secure secrets
./setup-env.sh

# 2. Start the application
docker compose up -d

# 3. Verify it's running
curl http://localhost/api/v1/health
```

**Done!** Access at http://localhost

---

## 📝 What These Steps Do

### Step 1: `./setup-env.sh`
- Creates `.env` file from `.env.example` template
- Generates secure random JWT secrets (32 bytes)
- Generates secure database passwords
- **Why needed**: `.env` contains secrets and is excluded from git

### Step 2: `docker compose up -d`
- Builds Docker images (backend, frontend)
- Starts all services (PostgreSQL, Redis, NextCloud, Backend, Frontend, Nginx)
- Creates database tables automatically
- Seeds initial admin user

### Step 3: Test endpoint
- Verifies backend is healthy and responding

---

## 🔐 Default Credentials

After setup completes, login with:

```
Username: Admin
Password: AdminAdmin@123
Email: admin@ontrack.local
```

**⚠️ IMPORTANT**: Change this password immediately after first login!

---

## 📊 Accessing the Application

| Service | URL | Description |
|---------|-----|-------------|
| Frontend | http://localhost | Main application UI |
| API Documentation | http://localhost/api/docs | Swagger/OpenAPI docs |
| Backend API | http://localhost/api/v1 | REST API endpoints |
| Health Check | http://localhost/api/v1/health | Service health status |
| NextCloud | http://localhost/nextcloud | Document management |

---

## 🔧 Troubleshooting

### Issue: "setup-env.sh: Permission denied"
```bash
chmod +x setup-env.sh
./setup-env.sh
```

### Issue: "docker: command not found"
Install Docker first: https://docs.docker.com/get-docker/

### Issue: "Port 80 already in use"
```bash
# Option 1: Stop conflicting service
sudo lsof -i :80

# Option 2: Change port in .env
echo "NGINX_PORT=8080" >> .env
# Then access at http://localhost:8080
```

### Issue: Backend unhealthy / not starting
```bash
# View logs
docker compose logs backend

# Common fix: rebuild
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Issue: "JWT_SECRET is not defined"
```bash
# Re-run setup
./setup-env.sh

# Restart containers
docker compose down
docker compose up -d
```

---

## 🛠️ Development Commands

```bash
# View all logs
docker compose logs -f

# View backend logs only
docker compose logs -f backend

# Restart a service
docker compose restart backend

# Stop all services
docker compose down

# Stop and remove volumes (fresh start)
docker compose down -v

# Rebuild specific service
docker compose build --no-cache backend
docker compose up -d backend
```

---

## 📚 Documentation

- **Security Audit**: See `1st-audit.md` for security findings and fixes
- **API Documentation**: http://localhost/api/docs (after starting)
- **Deployment Guide**: See `DEPLOYMENT_QUICKSTART.md`
- **Full Documentation**: See `README.md`

---

## ⚠️ Security Notes

1. **Never commit `.env` to git** - it contains secrets
2. **Change default admin password** immediately
3. **Use HTTPS in production** - see `1st-audit.md` for SSL setup
4. **Review security fixes** in `1st-audit.md` before production

---

## 🆘 Getting Help

If you encounter issues:

1. Check the logs: `docker compose logs backend`
2. Review `TROUBLESHOOTING.md`
3. Check `1st-audit.md` for known issues
4. Restart fresh: `docker compose down -v && ./setup-env.sh && docker compose up -d`

---

## 🎉 Success Checklist

After setup, verify:

- [ ] `.env` file exists with secure secrets
- [ ] `docker compose ps` shows all services as "healthy"
- [ ] http://localhost/api/v1/health returns `{"status":"ok"}`
- [ ] http://localhost/api/docs loads Swagger UI
- [ ] You can login with Admin/AdminAdmin@123
- [ ] Admin password changed after first login

---

**Version**: OnTrack v1.0
**Last Updated**: January 1, 2026
**Setup Time**: ~5 minutes (first time with Docker image downloads)
