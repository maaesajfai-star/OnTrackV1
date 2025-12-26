#!/bin/sh
set -e

echo "🚀 Starting UEMS Backend..."

# Wait for PostgreSQL to be ready
echo "⏳ Waiting for PostgreSQL..."
until nc -z postgres 5432; do
  echo "  PostgreSQL is unavailable - sleeping"
  sleep 2
done
echo "✓ PostgreSQL is ready!"

# Wait a bit more to ensure PostgreSQL is fully initialized
sleep 5

# Run migrations (ignore errors if already applied)
echo "📦 Running database migrations..."
npm run migration:run || echo "⚠️  Migrations failed or already applied"

# Run database initialization (creates admin if needed)
echo "👤 Initializing database..."
npm run db:init || echo "⚠️  Database init failed or admin already exists"

# Start the application
echo "🎯 Starting NestJS application..."
exec npm run start:dev
