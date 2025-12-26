# Backend Container Startup Fix Guide

## 🔴 Problem: Backend Container Failing or Unhealthy

The backend container fails to start or shows as unhealthy due to missing database schema changes (username field).

---

## 🔍 Root Cause

After implementing the universal Admin account, the database schema needs to be updated with:
- New `username` column in the `users` table
- Unique index on `username`
- Existing users need usernames populated

**Without this migration, the backend will fail because:**
1. TypeORM entities expect `username` field
2. Seed script tries to create users with `username`
3. Database doesn't have the `username` column yet

---

## ✅ Solution: Apply Database Migration

### Method 1: Automatic (Recommended)

The system now includes auto-migration on startup:

```bash
# 1. Stop all containers
docker compose down

# 2. Remove old volumes (⚠️ This deletes ALL data!)
docker compose down -v

# 3. Start fresh
docker compose up -d

# 4. Backend will automatically:
#    - Run migrations
#    - Create tables
#    - Wait for you to run seed

# 5. Seed the database
docker compose exec backend npm run seed
```

### Method 2: Manual Migration (Preserves Data)

If you have existing data you want to keep:

```bash
# 1. Ensure containers are running
docker compose up -d postgres

# 2. Run migrations
docker compose exec backend npm run migration:run

# Expected output:
# ✓ Ran 1 migration(s):
#   - AddUsernameToUsers1735201200000

# 3. Restart backend
docker compose restart backend

# 4. Check health
docker compose ps backend
```

### Method 3: Using Database Init Script

```bash
# This runs migrations AND creates admin user in one step
docker compose exec backend npm run db:init

# Expected output:
# 🔧 Initializing database...
# ✓ Database connection established
# 📦 Running migrations...
# ✓ Ran 1 migration(s):
#   - AddUsernameToUsers1735201200000
# 👤 Creating default Admin user...
# ✓ Admin user created: Admin / AdminAdmin@123
# 🎉 Database initialization completed successfully!
```

---

## 📋 Step-by-Step Fix Instructions

### Option A: Fresh Start (No Existing Data)

```bash
# 1. Stop everything and remove volumes
docker compose down -v

# 2. Rebuild images (includes new migration)
docker compose build

# 3. Start all services
docker compose up -d

# 4. Wait for postgres to be healthy (30 seconds)
docker compose ps

# 5. Initialize database
docker compose exec backend npm run db:init

# 6. Verify backend is healthy
docker compose ps backend
# Should show "healthy" status

# 7. Test login
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "Admin", "password": "AdminAdmin@123"}'
```

### Option B: Preserve Existing Data

```bash
# 1. Backup database (important!)
docker compose exec postgres pg_dump -U uems_user uems_db > backup.sql

# 2. Rebuild backend
docker compose build backend

# 3. Run migration only
docker compose exec backend npm run migration:run

# 4. Update existing users with usernames (if any)
docker compose exec postgres psql -U uems_user -d uems_db -c \
  "UPDATE users SET username = CONCAT('user_', SUBSTRING(email FROM 1 FOR POSITION('@' IN email) - 1)) WHERE username IS NULL;"

# 5. Create admin if needed
docker compose exec backend npm run seed

# 6. Restart backend
docker compose restart backend

# 7. Verify health
docker compose ps backend
```

---

## 🔍 Troubleshooting

### Backend Logs Show "column username does not exist"

**Cause:** Migration hasn't run yet

**Fix:**
```bash
docker compose exec backend npm run migration:run
docker compose restart backend
```

### Backend Logs Show "duplicate key value violates unique constraint"

**Cause:** Trying to create duplicate usernames

**Fix:**
```bash
# Check existing users
docker compose exec postgres psql -U uems_user -d uems_db -c \
  "SELECT id, username, email, role FROM users;"

# Delete duplicate or problematic user
docker compose exec postgres psql -U uems_user -d uems_db -c \
  "DELETE FROM users WHERE username = 'Admin' AND role != 'admin';"

# Run seed again
docker compose exec backend npm run seed
```

### Backend Container Keeps Restarting

**Check logs:**
```bash
docker compose logs backend --tail=100

# Common issues and fixes:
# 1. "Cannot connect to postgres" → Wait longer, postgres is still initializing
# 2. "column username does not exist" → Run migration
# 3. "Port 3001 already in use" → Kill process using port 3001
# 4. TypeScript errors → Check for compilation issues
```

### Health Check Failing

```bash
# Check if backend is responding
docker compose exec backend curl http://localhost:3001/api/v1/health

# If curl not available in container:
curl http://localhost:3001/api/v1/health

# Expected response:
# {"status":"ok","database":"connected"}
```

---

## 🛠️ Development Mode vs Production

### Development (synchronize: true)

In development, TypeORM's `synchronize: true` automatically creates tables but **doesn't handle complex migrations** well.

**Recommended approach:**
```bash
# Disable synchronize for this change
# Edit backend/src/config/typeorm.config.ts:
# synchronize: false,  // Changed from: configService.get('NODE_ENV') === 'development'

# Use migrations instead
docker compose exec backend npm run migration:run
```

### Production (synchronize: false)

Production **always** uses migrations:

```bash
# Migrations run automatically before start
npm run start:prod
# This calls: prestart:prod → migration:run → start:prod
```

---

## 📦 What Was Created

### 1. Database Migration

**File:** `backend/src/database/migrations/1735201200000-AddUsernameToUsers.ts`

**What it does:**
- Adds `username` column (VARCHAR 100, UNIQUE, NOT NULL)
- Creates unique index on `username`
- Migrates existing users: generates usernames from emails
- Handles rollback if needed

### 2. Database Init Script

**File:** `backend/src/database/init-db.ts`

**What it does:**
- Runs pending migrations
- Creates Admin user if doesn't exist
- Safe to run multiple times (idempotent)

### 3. NPM Scripts

**Added to package.json:**
- `npm run db:init` - Run migrations + create admin
- `npm run migration:run` - Run pending migrations only
- `npm run migration:revert` - Rollback last migration
- `prestart:prod` - Auto-run migrations in production

---

## ✅ Verification Checklist

After applying the fix:

- [ ] Backend container shows `healthy` status: `docker compose ps backend`
- [ ] Migration ran successfully: Check logs for "Ran 1 migration(s)"
- [ ] Admin user exists: `docker compose exec backend npm run seed`
- [ ] Login works: Test API endpoint `/api/v1/auth/login`
- [ ] Health check passes: `curl http://localhost:3001/api/v1/health`
- [ ] No errors in logs: `docker compose logs backend --tail=50`

---

## 🔄 Future Migrations

When you make schema changes:

```bash
# 1. Update entity (e.g., add new field)
# 2. Generate migration
docker compose exec backend npm run migration:generate -- src/database/migrations/YourMigrationName

# 3. Review generated migration file
# 4. Run migration
docker compose exec backend npm run migration:run

# 5. Test
# 6. Commit migration file to git
```

---

## 🚨 Emergency Rollback

If something goes wrong:

```bash
# 1. Revert the migration
docker compose exec backend npm run migration:revert

# 2. Restore from backup (if you made one)
docker compose exec -T postgres psql -U uems_user -d uems_db < backup.sql

# 3. Restart backend
docker compose restart backend
```

---

## 📞 Quick Commands Reference

```bash
# Check backend status
docker compose ps backend

# View backend logs
docker compose logs backend -f

# Run migrations
docker compose exec backend npm run migration:run

# Initialize database (migrations + admin)
docker compose exec backend npm run db:init

# Seed database (create admin + sample users)
docker compose exec backend npm run seed

# Check database
docker compose exec postgres psql -U uems_user -d uems_db -c \
  "SELECT username, email, role FROM users;"

# Restart backend
docker compose restart backend

# Full reset (⚠️ Deletes all data!)
docker compose down -v && docker compose up -d
```

---

## 📝 Summary

**Problem:** Backend fails because database doesn't have `username` column

**Solution:** Run database migration

**Quickest Fix:**
```bash
docker compose exec backend npm run db:init
docker compose restart backend
```

**The backend should now start successfully with the Admin account ready to use!** ✅
