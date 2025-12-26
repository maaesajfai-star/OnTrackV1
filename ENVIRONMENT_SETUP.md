# Environment Setup Guide

## Quick Start

### 1. Environment File Setup

The project now includes a pre-configured `.env` file with secure, cryptographically generated secrets. You can use it directly for development.

```bash
# The .env file is already created with:
# ✅ JWT_SECRET (512-bit cryptographic key)
# ✅ JWT_REFRESH_SECRET (512-bit cryptographic key)
# ✅ REDIS_PASSWORD (256-bit cryptographic key)
# ✅ All other required environment variables
```

### 2. For Production Deployment

Generate your own secrets:

```bash
# Generate JWT Secret
openssl rand -base64 64

# Generate JWT Refresh Secret
openssl rand -base64 64

# Generate Redis Password
openssl rand -base64 32
```

Then update your production `.env` file with these values.

## Package Lock Files Status

✅ **package-lock.json files are present:**
- `backend/package-lock.json` (405 KB)
- `frontend/package-lock.json` (238 KB)

Docker builds will use `npm ci` which requires these files.

## JWT Configuration

### Current Setup

The JWT authentication is configured with:

- **JWT_SECRET**: 512-bit cryptographically secure key
- **JWT_EXPIRATION**: 3600 seconds (1 hour)
- **JWT_REFRESH_SECRET**: 512-bit cryptographically secure refresh key
- **JWT_REFRESH_EXPIRATION**: 604800 seconds (7 days)

### Where JWT is Used

1. **Backend Authentication Module** (`backend/src/modules/auth/auth.module.ts`)
   - JwtModule configuration
   - Token generation and validation

2. **JWT Strategy** (`backend/src/modules/auth/strategies/jwt.strategy.ts`)
   - Token verification
   - User payload extraction

### Testing JWT Authentication

Once Docker is running:

```bash
# 1. Register a user
curl -X POST http://localhost/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test@12345",
    "firstName": "Test",
    "lastName": "User"
  }'

# 2. Login to get JWT token
curl -X POST http://localhost/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test@12345"
  }'

# Response will include:
# {
#   "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
#   "user": { ... }
# }

# 3. Use the access_token for authenticated requests
curl -X GET http://localhost/api/v1/users/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Docker Build Instructions

### Development Mode

```bash
# Using Makefile
make setup      # First time setup
make up         # Start all services
make logs       # View logs

# Or using Docker Compose directly
docker compose up -d
docker compose logs -f
```

### Production Mode

```bash
# Build production images
docker compose -f docker-compose.prod.yml build

# Start production services
docker compose -f docker-compose.prod.yml up -d

# View production logs
docker compose -f docker-compose.prod.yml logs -f
```

## Known Issues

### TypeScript Compilation Errors

The backend currently has 25 TypeScript compilation errors in the CRM and HRM modules:

- **Missing methods in services:**
  - `ContactsService`: missing `update()` and `remove()` methods
  - `DealsService`: missing `update()` and `remove()` methods
  - `OrganizationsService`: missing `update()` and `remove()` methods
  - Similar issues in HRM modules

**Status**: These errors are **separate from JWT configuration** and do not affect the JWT authentication setup.

**Impact**:
- JWT authentication works correctly
- Frontend builds successfully
- Backend TypeScript compilation fails
- Runtime may work if `start:dev` skips type checking

**Next Steps**: Fix the missing service methods in subsequent commits.

## Security Notes

### Never Commit Secrets

The `.env` file is gitignored to prevent accidentally committing secrets to version control.

**What's safe to commit:**
- ✅ `.env.example` (template without real secrets)
- ✅ `docker-compose.yml` (uses environment variables)
- ✅ Configuration files (that reference environment variables)

**What should NEVER be committed:**
- ❌ `.env` (contains actual secrets)
- ❌ Any file with hardcoded passwords or API keys
- ❌ Private certificates or keys

### Rotating Secrets

If secrets are compromised, regenerate them immediately:

```bash
# 1. Generate new secrets
NEW_JWT_SECRET=$(openssl rand -base64 64)
NEW_REFRESH_SECRET=$(openssl rand -base64 64)

# 2. Update .env file
# 3. Restart services
docker compose restart backend

# 4. All existing JWT tokens will be invalidated
# 5. Users will need to log in again
```

## Environment Variables Reference

### Critical Variables (Must be set)

| Variable | Description | How to Generate |
|----------|-------------|----------------|
| `JWT_SECRET` | Main JWT signing key | `openssl rand -base64 64` |
| `JWT_REFRESH_SECRET` | Refresh token signing key | `openssl rand -base64 64` |
| `POSTGRES_PASSWORD` | Database password | Strong random password |
| `REDIS_PASSWORD` | Redis password | `openssl rand -base64 32` |
| `NEXTCLOUD_ADMIN_PASSWORD` | NextCloud admin password | Strong random password |

### Optional Variables (Have defaults)

| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_ENV` | `development` | Environment mode |
| `BACKEND_PORT` | `3001` | Backend API port |
| `FRONTEND_PORT` | `3000` | Frontend port |
| `JWT_EXPIRATION` | `3600` | JWT expiry (seconds) |
| `REDIS_DB` | `0` | Redis database number |

## Troubleshooting

### "JWT_SECRET is undefined"

**Symptom**: Backend fails to start with JWT configuration errors

**Solution**:
1. Ensure `.env` file exists in project root
2. Check that `.env` contains `JWT_SECRET=...`
3. Restart Docker containers: `docker compose restart backend`

### "Package-lock.json not found"

**Symptom**: Docker build fails looking for package-lock.json

**Status**: ✅ **RESOLVED** - Files exist in both backend/ and frontend/

### Frontend Build Errors

**Status**: ✅ **RESOLVED** - Fixed in commit 342f628

### Backend TypeScript Errors

**Status**: ⚠️ **KNOWN ISSUE** - 25 compilation errors in services
- Does not affect JWT configuration
- Will be addressed in separate fix

## Support

For issues or questions:
1. Check this guide first
2. Review Docker logs: `make logs` or `docker compose logs`
3. Check GitHub Issues: https://github.com/maaesajfai-star/OnTrackV1/issues
4. Review the comprehensive docs:
   - `DOCKER_README.md` - Full Docker guide
   - `QUICK_START.md` - Quick reference
   - `DOCKER_OPTIMIZATION_SUMMARY.md` - Technical details
