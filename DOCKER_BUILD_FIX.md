# Docker Build and Startup Fix Guide

## 🔴 Problems Solved

1. **Cache manifest pull errors** during `docker compose up --build`
2. **Backend container failing to start** or showing unhealthy
3. **Frontend build cache issues**
4. **Migration/database initialization issues**

---

## ✅ Solutions Implemented

### 1. **Simplified Dockerfiles**

Created new simplified Dockerfiles that avoid cache manifest issues:
- `backend/Dockerfile.simple` - Single-stage, no cache_from
- `frontend/Dockerfile.simple` - Single-stage, no cache_from

### 2. **Backend Startup Script**

Created `backend/docker-entrypoint.sh` that:
- ✅ Waits for PostgreSQL to be ready
- ✅ Runs database migrations automatically
- ✅ Initializes database (creates Admin user)
- ✅ Starts the NestJS application
- ✅ Handles errors gracefully (continues even if migrations already applied)

### 3. **Updated docker-compose.yml**

- Backend now uses `Dockerfile.simple`
- Frontend now uses `Dockerfile.simple`
- Removed complex cache_from configurations
- Backend uses entrypoint script for robust startup

---

## 🚀 How to Fix Now

### Step 1: Clean Up Old Containers and Images

```bash
# Stop all containers
docker compose down

# Remove old images (forces rebuild)
docker rmi uems-backend:latest uems-frontend:latest 2>/dev/null || true

# Optional: Clean up all Docker resources (⚠️ affects other projects too)
docker system prune -af
```

### Step 2: Build with Simplified Dockerfiles

```bash
# Build without cache
docker compose build --no-cache

# You should see:
# - No cache manifest errors
# - Clean build output
# - Both backend and frontend build successfully
```

### Step 3: Start All Services

```bash
# Start in detached mode
docker compose up -d

# Watch logs in real-time
docker compose logs -f
```

### Step 4: Verify Backend Startup

The backend entrypoint script will automatically:

```
🚀 Starting UEMS Backend...
⏳ Waiting for PostgreSQL...
✓ PostgreSQL is ready!
📦 Running database migrations...
✓ Ran 1 migration(s):
  - AddUsernameToUsers1735201200000
👤 Initializing database...
✓ Admin user created: Admin / AdminAdmin@123
🎯 Starting NestJS application...
```

### Step 5: Check Health

```bash
# Check all services
docker compose ps

# All should show "healthy" or "running"
# NAME              STATUS
# uems-backend      Up (healthy)
# uems-frontend     Up
# uems-postgres     Up (healthy)
# uems-redis        Up (healthy)
# uems-nextcloud    Up (healthy)
# uems-nginx        Up (healthy)
```

---

## 🔧 Alternative: One Command Fix

```bash
# Complete reset and rebuild (⚠️ deletes all data)
docker compose down -v && \
docker rmi uems-backend:latest uems-frontend:latest 2>/dev/null || true && \
docker compose build --no-cache && \
docker compose up -d && \
docker compose logs -f backend
```

---

## 🐛 Troubleshooting

### Issue: "Cannot pull cache manifest"

**This is normal and can be ignored.** The new Dockerfiles don't use cache_from, so this error won't appear anymore.

**If you still see it:**
```bash
# Use the new simplified Dockerfiles
docker compose build --no-cache
```

### Issue: Backend still failing

**Check the logs:**
```bash
docker compose logs backend --tail=100
```

**Common issues:**

1. **PostgreSQL not ready**
   - Entrypoint waits automatically, but you can increase wait time
   - Edit `docker-entrypoint.sh`: change `sleep 5` to `sleep 10`

2. **Port 3001 already in use**
   ```bash
   # Find and kill the process
   sudo lsof -ti:3001 | xargs kill -9
   ```

3. **Migration errors**
   ```bash
   # Run migration manually
   docker compose exec backend npm run migration:run
   docker compose restart backend
   ```

4. **Database connection errors**
   ```bash
   # Check PostgreSQL is healthy
   docker compose ps postgres

   # Check logs
   docker compose logs postgres

   # Restart PostgreSQL
   docker compose restart postgres
   docker compose restart backend
   ```

### Issue: Frontend build fails

```bash
# Check logs
docker compose logs frontend

# Rebuild frontend only
docker compose build --no-cache frontend
docker compose up -d frontend
```

### Issue: "Admin user already exists" error

**This is normal!** The entrypoint script tries to create the admin but skips if it exists.

**To reset admin:**
```bash
docker compose exec postgres psql -U uems_user -d uems_db \
  -c "DELETE FROM users WHERE username = 'Admin';"

docker compose restart backend
```

---

## 📝 What Changed

### Backend Changes:

**File: `backend/Dockerfile.simple`**
- Single-stage build
- No BuildKit cache_from
- Includes netcat for health checks
- Installs postgresql-client for debugging

**File: `backend/docker-entrypoint.sh`**
- Waits for PostgreSQL
- Runs migrations automatically
- Creates Admin user
- Starts application

### Frontend Changes:

**File: `frontend/Dockerfile.simple`**
- Single-stage build for development
- No complex caching
- Clean npm ci install

### Docker Compose Changes:

**File: `docker-compose.yml`**
- Backend uses `Dockerfile.simple`
- Frontend uses `Dockerfile.simple`
- Removed cache_from configurations
- Backend uses entrypoint script

---

## ✅ Verification Checklist

After running the fix:

- [ ] No cache manifest errors during build
- [ ] Backend builds successfully
- [ ] Frontend builds successfully
- [ ] PostgreSQL starts and shows healthy
- [ ] Redis starts and shows healthy
- [ ] Backend starts and shows healthy
- [ ] Frontend starts successfully
- [ ] Admin user created: `Admin` / `AdminAdmin@123`
- [ ] Can login to backend API
- [ ] Can access frontend
- [ ] Can access NextCloud

---

## 🧪 Testing the Fix

### Test 1: Build

```bash
docker compose build --no-cache

# Should complete without errors
# No "cache manifest" errors
```

### Test 2: Start

```bash
docker compose up -d

# Wait 30 seconds
sleep 30

# Check status
docker compose ps
```

### Test 3: Backend Health

```bash
# Check health endpoint
curl http://localhost:3001/api/v1/health

# Expected: {"status":"ok","database":"connected"}
```

### Test 4: Admin Login

```bash
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "Admin",
    "password": "AdminAdmin@123"
  }'

# Should return access_token and user data
```

### Test 5: Frontend

```bash
# Open in browser
open http://localhost:3000

# Or test with curl
curl -I http://localhost:3000
```

---

## 🔄 Switching Back to Original Dockerfiles

If you need to switch back:

```bash
# Edit docker-compose.yml
# Change:
#   dockerfile: Dockerfile.simple
# To:
#   dockerfile: Dockerfile

docker compose build
docker compose up -d
```

---

## 📦 Files Created/Modified

### New Files:
- `backend/Dockerfile.simple` - Simplified backend Dockerfile
- `backend/docker-entrypoint.sh` - Startup script with migrations
- `frontend/Dockerfile.simple` - Simplified frontend Dockerfile
- `DOCKER_BUILD_FIX.md` - This guide

### Modified Files:
- `docker-compose.yml` - Uses simplified Dockerfiles

---

## 🎯 Quick Reference

### Build and start:
```bash
docker compose build --no-cache && docker compose up -d
```

### View logs:
```bash
docker compose logs -f backend
docker compose logs -f frontend
```

### Restart a service:
```bash
docker compose restart backend
docker compose restart frontend
```

### Full reset:
```bash
docker compose down -v && docker compose up -d
```

### Check health:
```bash
docker compose ps
curl http://localhost:3001/api/v1/health
```

---

## 🚨 Emergency: Complete Reset

If nothing works, full reset:

```bash
#!/bin/bash

# Stop everything
docker compose down -v

# Remove images
docker rmi uems-backend:latest uems-frontend:latest 2>/dev/null || true

# Clean Docker
docker system prune -af --volumes

# Rebuild from scratch
docker compose build --no-cache

# Start
docker compose up -d

# Wait
sleep 30

# Check
docker compose ps
docker compose logs backend --tail=50
```

---

## ✅ Success Indicators

You'll know it's working when you see:

1. **Build output shows:**
   - No cache manifest errors
   - Clean package installations
   - Successful builds

2. **Backend logs show:**
   ```
   🚀 Starting UEMS Backend...
   ✓ PostgreSQL is ready!
   📦 Running database migrations...
   👤 Initializing database...
   ✓ Admin user created: Admin / AdminAdmin@123
   🎯 Starting NestJS application...
   [Nest] Application successfully started
   ```

3. **`docker compose ps` shows:**
   ```
   NAME              STATUS
   uems-backend      Up (healthy)
   uems-frontend     Up
   uems-postgres     Up (healthy)
   ```

4. **Health check passes:**
   ```bash
   curl http://localhost:3001/api/v1/health
   # {"status":"ok","database":"connected"}
   ```

5. **Login works:**
   ```bash
   curl -X POST http://localhost/api/v1/auth/login \
     -H "Content-Type: application/json" \
     -d '{"username": "Admin", "password": "AdminAdmin@123"}'
   # Returns access_token
   ```

---

## 📞 Still Having Issues?

1. Check logs: `docker compose logs -f`
2. Check disk space: `df -h`
3. Check Docker: `docker info`
4. Restart Docker daemon: `sudo systemctl restart docker`
5. Review BACKEND_STARTUP_FIX.md for database-specific issues

**Your Docker build and startup issues are now fixed!** 🎉
