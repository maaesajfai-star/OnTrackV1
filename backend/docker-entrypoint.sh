#!/bin/sh
set -e

echo "🚀 Starting UEMS Backend..."

# Display environment information
echo "📋 Environment: NODE_ENV=${NODE_ENV:-not set}"
echo "📋 Working directory: $(pwd)"

# Clean any previous build artifacts to prevent syntax errors
echo "🧹 Cleaning build artifacts..."
rm -rf /app/dist /app/build /app/.nest
echo "✓ Build artifacts cleaned"

# Ensure NODE_ENV is set for TypeORM
export NODE_ENV="${NODE_ENV:-development}"
echo "✓ NODE_ENV set to: $NODE_ENV"

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL..."
MAX_RETRIES=30
RETRY_COUNT=0

until nc -z postgres 5432 || [ $RETRY_COUNT -eq $MAX_RETRIES ]; do
  echo "  PostgreSQL is unavailable - sleeping (attempt $RETRY_COUNT/$MAX_RETRIES)"
  sleep 2
  RETRY_COUNT=$((RETRY_COUNT + 1))
done

if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
  echo "❌ Failed to connect to PostgreSQL after $MAX_RETRIES attempts"
  exit 1
fi

echo "✓ PostgreSQL is ready!"

# Wait a bit more to ensure PostgreSQL is fully initialized
sleep 3

# Test database connection
echo "🔌 Testing database connection..."
if ! pg_isready -h postgres -p 5432 -U "$POSTGRES_USER" -d "$POSTGRES_DB"; then
  echo "❌ PostgreSQL is not ready to accept connections"
  exit 1
fi
echo "✓ Database connection successful!"

# Run migrations (ignore errors if already applied)
echo "📦 Running database migrations..."
if npm run migration:run; then
  echo "✓ Migrations completed successfully"
else
  echo "⚠️  Migration command failed - this may be normal if migrations are already applied"
fi

# Run database seeding (creates admin if needed)
echo "👤 Creating admin user..."
if npm run seed; then
  echo "✓ Seeding completed successfully"
else
  echo "⚠️  Seed failed - admin user may already exist"
fi

# Start the application in development mode (no build required)
echo "🎯 Starting NestJS application in watch mode..."
echo "   (TypeScript will compile on-the-fly)"
echo ""
exec npm run start:dev
