# Universal Admin Account - UEMS

## 🔐 Admin Credentials

**A single universal admin account works across ALL systems in UEMS:**

```
Username: Admin
Password: AdminAdmin@123
```

---

## 📍 Where This Account Works

### 1. **UEMS Backend API**
- **Login URL**: `http://localhost/api/v1/auth/login`
- **Username**: `Admin`
- **Password**: `AdminAdmin@123`
- **Role**: `admin` (full system access)

### 2. **UEMS Frontend**
- **Login URL**: `http://localhost:3000/login`
- **Username**: `Admin`
- **Password**: `AdminAdmin@123`
- **Access**: Full administrative dashboard

### 3. **NextCloud DMS**
- **Login URL**: `http://localhost/nextcloud`
- **Username**: `Admin`
- **Password**: `AdminAdmin@123`
- **Access**: NextCloud administrator panel

---

## 🚀 Quick Login Guide

### Backend API Login (via curl)

```bash
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "Admin",
    "password": "AdminAdmin@123"
  }'
```

**Response:**
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "uuid-here",
    "username": "Admin",
    "email": "admin@uems.local",
    "firstName": "System",
    "lastName": "Administrator",
    "role": "admin"
  }
}
```

### Frontend Login (Web Interface)

1. Navigate to: `http://localhost:3000/login`
2. Enter username: `Admin`
3. Enter password: `AdminAdmin@123`
4. Click "Login"

### NextCloud Login (Web Interface)

1. Navigate to: `http://localhost/nextcloud`
2. Enter username: `Admin`
3. Enter password: `AdminAdmin@123`
4. Click "Log in"

---

## 👥 Other Default Accounts

The system also includes sample accounts for testing:

### HR Manager Account
```
Username: hrmanager
Password: HR@123456
Email: hr@uems.com
Role: hr_manager
```

**Access**: HR module, employee management, recruitment, ATS

### Sales User Account
```
Username: salesuser
Password: Sales@123456
Email: sales@uems.com
Role: sales_user
```

**Access**: CRM module, contacts, organizations, deals, activities

---

## 🔧 How the Admin Account is Created

### Automatic Creation (Recommended)

The Admin account is automatically created when you run database seeding:

```bash
# Using Docker Compose
docker compose exec backend npm run seed

# Using Makefile
make seed
```

**Output:**
```
🌱 Starting database seed...
✓ Universal Admin account created:
  Username: Admin
  Password: AdminAdmin@123
  Email: admin@uems.local
✓ HR Manager created: hrmanager / HR@123456
✓ Sales User created: salesuser / Sales@123456
🎉 Database seeding completed!
```

### Manual Creation (If needed)

If you need to manually create the admin user:

```bash
# Connect to backend container
docker compose exec backend sh

# Open Node.js REPL or create a script
node -e "
const bcrypt = require('bcrypt');
const password = await bcrypt.hash('AdminAdmin@123', 12);
console.log('Hashed password:', password);
"

# Then manually insert into database
docker compose exec postgres psql -U uems_user -d uems_db

INSERT INTO users (
  id, username, email, password,
  \"firstName\", \"lastName\", role,
  \"isActive\", \"createdAt\", \"updatedAt\"
) VALUES (
  gen_random_uuid(),
  'Admin',
  'admin@uems.local',
  '$2b$12$...',  -- Use the hashed password
  'System',
  'Administrator',
  'admin',
  true,
  NOW(),
  NOW()
);
```

---

## 🔒 Security Notes

### Development vs Production

**Current Setup (Development):**
- Username: `Admin`
- Password: `AdminAdmin@123`
- ⚠️ **DO NOT use in production!**

**For Production:**

1. **Change the password immediately:**
   ```bash
   # Update in .env file
   DEFAULT_ADMIN_PASSWORD=YOUR_SECURE_PASSWORD_HERE

   # Run seed again or update via API
   ```

2. **Use strong password requirements:**
   - Minimum 16 characters
   - Mix of uppercase, lowercase, numbers, symbols
   - No dictionary words
   - Example: `A!x9#mP2$qL7&vK4@zR8`

3. **Enable Two-Factor Authentication** (if implemented)

4. **Rotate credentials regularly**

### Password Change via API

```bash
# Get access token first (login as Admin)
ACCESS_TOKEN="your-access-token-here"

# Change password
curl -X PATCH http://localhost/api/v1/users/me/password \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "currentPassword": "AdminAdmin@123",
    "newPassword": "YourNewSecurePassword123!"
  }'
```

---

## 🛠️ Troubleshooting

### "Invalid username or password"

**Check:**
1. Ensure database seeding has run: `docker compose exec backend npm run seed`
2. Verify username is exactly `Admin` (case-sensitive)
3. Verify password is exactly `AdminAdmin@123`
4. Check backend logs: `docker compose logs backend`

### "User already exists" during seeding

This is normal if the admin already exists. The seed script skips existing users.

### Cannot login to NextCloud

**Solutions:**
1. Wait for NextCloud to fully initialize (can take 2-3 minutes on first start)
2. Check NextCloud logs: `docker compose logs nextcloud`
3. Verify environment variables: `docker compose config | grep NEXTCLOUD_ADMIN`
4. Try accessing: `http://localhost/nextcloud` (not `http://localhost:nextcloud`)

### Forgot the admin password

**Reset via database:**

```bash
# Generate new password hash
docker compose exec backend node -e "
const bcrypt = require('bcrypt');
bcrypt.hash('NewPassword123!', 12).then(hash => console.log(hash));
"

# Update in database
docker compose exec postgres psql -U uems_user -d uems_db -c \
  "UPDATE users SET password = '<HASHED_PASSWORD>' WHERE username = 'Admin';"
```

---

## 📊 Admin Capabilities

### UEMS Backend/Frontend Admin Can:

- ✅ **User Management**: Create, read, update, delete all users
- ✅ **Role Assignment**: Assign roles to users (admin, hr_manager, sales_user, user)
- ✅ **CRM Access**: Full access to contacts, organizations, deals, activities
- ✅ **HRM Access**: Full access to employees, job postings, candidates, ATS
- ✅ **DMS Access**: Full access to NextCloud document management
- ✅ **System Configuration**: Modify system settings
- ✅ **Audit Logs**: View all system audit logs
- ✅ **Reports**: Generate and view all reports

### NextCloud Admin Can:

- ✅ **User Provisioning**: Create NextCloud users for UEMS users
- ✅ **Storage Management**: Manage storage quotas and limits
- ✅ **App Management**: Install/remove NextCloud apps
- ✅ **Security Settings**: Configure security policies
- ✅ **Sharing Settings**: Control file sharing permissions
- ✅ **Activity Monitoring**: View all user activities

---

## 🔄 Changing the Universal Admin Credentials

To change the admin credentials across all systems:

### 1. Update Environment Variables

Edit `.env` file:
```bash
DEFAULT_ADMIN_USERNAME=NewAdminUser
DEFAULT_ADMIN_PASSWORD=NewSecurePassword123!
NEXTCLOUD_ADMIN_USER=NewAdminUser
NEXTCLOUD_ADMIN_PASSWORD=NewSecurePassword123!
```

### 2. Update Database Seed

Edit `backend/src/database/seeds/seed.ts`:
```typescript
username: 'NewAdminUser',
password: await bcrypt.hash('NewSecurePassword123!', 12),
```

### 3. Recreate Services

```bash
# Stop all services
docker compose down -v

# Rebuild and restart
docker compose up -d

# Run seed
docker compose exec backend npm run seed
```

### 4. Verify

```bash
# Test login
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "NewAdminUser",
    "password": "NewSecurePassword123!"
  }'
```

---

## 📞 Support

For issues with admin access:

1. Check `ENVIRONMENT_SETUP.md` for environment configuration
2. Review `DOCKER_README.md` for Docker setup
3. Check logs: `docker compose logs -f backend`
4. Verify database: `docker compose exec postgres psql -U uems_user -d uems_db -c "SELECT username, email, role FROM users WHERE role = 'admin';"`

---

## 🎯 Summary

**Universal Admin Credentials:**
- Username: `Admin`
- Password: `AdminAdmin@123`

**Works on:**
- ✅ UEMS Backend API (`/api/v1/auth/login`)
- ✅ UEMS Frontend (`http://localhost:3000/login`)
- ✅ NextCloud DMS (`http://localhost/nextcloud`)

**Security Reminder:**
⚠️ **Change these credentials before deploying to production!**
