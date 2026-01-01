#!/bin/bash
# OnTrack - Quick Environment Setup
# Generates .env file with secure random secrets

set -e

echo "========================================"
echo "  OnTrack - Environment Setup"
echo "========================================"
echo

# Check if .env already exists
if [ -f ".env" ]; then
    read -p "⚠️  .env file already exists. Overwrite? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Setup cancelled. Using existing .env file."
        exit 0
    fi
fi

# Check if .env.example exists
if [ ! -f ".env.example" ]; then
    echo "❌ ERROR: .env.example not found!"
    echo "Creating minimal .env.example..."

    cat > .env.example <<'EOF'
# OnTrack Environment Configuration
# Copy this to .env and update values

# Node Environment
NODE_ENV=development

# PostgreSQL Configuration
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_USER=ontrack_user
POSTGRES_PASSWORD=CHANGE_THIS_PASSWORD
POSTGRES_DB=ontrack_db

# Redis Configuration
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=

# JWT Configuration (Generate with: openssl rand -base64 32)
JWT_SECRET=GENERATE_A_SECURE_SECRET_HERE
JWT_REFRESH_SECRET=GENERATE_ANOTHER_SECURE_SECRET_HERE
JWT_EXPIRATION=3600
JWT_REFRESH_EXPIRATION=604800

# NextCloud Configuration
NEXTCLOUD_DB_USER=nextcloud
NEXTCLOUD_DB_PASSWORD=CHANGE_THIS_PASSWORD
NEXTCLOUD_DB_NAME=nextcloud
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=CHANGE_THIS_PASSWORD

# Backend Configuration
BACKEND_PORT=3001
LOG_LEVEL=debug

# Frontend Configuration
FRONTEND_PORT=3000
NEXT_PUBLIC_API_URL=http://localhost/api/v1
NEXT_PUBLIC_NEXTCLOUD_URL=http://localhost/nextcloud

# Nginx Configuration
NGINX_PORT=80
NGINX_SSL_PORT=443
EOF
fi

echo "📝 Copying .env.example to .env..."
cp .env.example .env

echo "🔐 Generating secure JWT secrets..."
JWT_SECRET=$(openssl rand -base64 32)
JWT_REFRESH_SECRET=$(openssl rand -base64 32)

echo "🔐 Generating secure database passwords..."
POSTGRES_PASSWORD=$(openssl rand -base64 16 | tr -d '/+=' | cut -c1-20)
NEXTCLOUD_DB_PASSWORD=$(openssl rand -base64 16 | tr -d '/+=' | cut -c1-20)
NEXTCLOUD_ADMIN_PASSWORD=$(openssl rand -base64 16 | tr -d '/+=' | cut -c1-20)

echo "✏️  Updating .env with generated secrets..."

# Use different delimiter to avoid conflicts with base64 characters
sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT_SECRET|" .env
sed -i "s|JWT_REFRESH_SECRET=.*|JWT_REFRESH_SECRET=$JWT_REFRESH_SECRET|" .env
sed -i "s|POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$POSTGRES_PASSWORD|" .env
sed -i "s|NEXTCLOUD_DB_PASSWORD=.*|NEXTCLOUD_DB_PASSWORD=$NEXTCLOUD_DB_PASSWORD|" .env
sed -i "s|NEXTCLOUD_ADMIN_PASSWORD=.*|NEXTCLOUD_ADMIN_PASSWORD=$NEXTCLOUD_ADMIN_PASSWORD|" .env

echo ""
echo "========================================"
echo "✅ Environment file created!"
echo "========================================"
echo ""
echo "🔑 Generated Credentials:"
echo "   PostgreSQL Password: $POSTGRES_PASSWORD"
echo "   NextCloud Admin Password: $NEXTCLOUD_ADMIN_PASSWORD"
echo "   JWT Secret: ${JWT_SECRET:0:20}..."
echo ""
echo "⚠️  IMPORTANT:"
echo "   1. These passwords are saved in .env"
echo "   2. .env is excluded from git (contains secrets)"
echo "   3. Keep .env file secure!"
echo ""
echo "Next steps:"
echo "   docker compose up -d"
echo ""
