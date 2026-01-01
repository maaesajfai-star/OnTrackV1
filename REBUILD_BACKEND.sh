#!/bin/bash
#
# Script to rebuild and test the backend container after TypeORM fix
#
# Usage: ./REBUILD_BACKEND.sh
#

set -e

echo "=========================================="
echo "UEMS Backend Container Rebuild & Test"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo -e "${YELLOW}Step 1: Stopping existing backend container...${NC}"
docker compose stop backend 2>/dev/null || true
docker compose rm -f backend 2>/dev/null || true
echo -e "${GREEN}✓ Backend container stopped${NC}"
echo ""

echo -e "${YELLOW}Step 2: Removing old backend image...${NC}"
docker rmi uems-backend:latest 2>/dev/null || echo "No existing image to remove"
echo -e "${GREEN}✓ Old image removed${NC}"
echo ""

echo -e "${YELLOW}Step 3: Building new backend image...${NC}"
docker compose build backend --no-cache
echo -e "${GREEN}✓ Backend image built successfully${NC}"
echo ""

echo -e "${YELLOW}Step 4: Starting backend container...${NC}"
docker compose up -d backend
echo -e "${GREEN}✓ Backend container started${NC}"
echo ""

echo -e "${YELLOW}Step 5: Waiting for backend to initialize (30 seconds)...${NC}"
for i in {1..30}; do
    echo -n "."
    sleep 1
done
echo ""
echo -e "${GREEN}✓ Wait complete${NC}"
echo ""

echo -e "${YELLOW}Step 6: Checking backend logs...${NC}"
echo "=========================================="
docker compose logs backend --tail=50
echo "=========================================="
echo ""

echo -e "${YELLOW}Step 7: Testing backend health...${NC}"
HEALTH_CHECK=$(docker compose exec -T backend curl -f http://localhost:3001/api/v1/health 2>/dev/null || echo "FAILED")

if [[ "$HEALTH_CHECK" == *"FAILED"* ]]; then
    echo -e "${RED}✗ Backend health check failed${NC}"
    echo ""
    echo -e "${YELLOW}Recent error logs:${NC}"
    docker compose logs backend --tail=100 | grep -i "error" || echo "No error messages found"
    echo ""
    echo -e "${RED}Backend failed to start properly. Check logs above.${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Backend is healthy!${NC}"
fi
echo ""

echo -e "${YELLOW}Step 8: Verifying TypeORM entity loading...${NC}"
TYPEORM_LOG=$(docker compose logs backend | grep -i "TypeORM" | tail -5)
if [[ -n "$TYPEORM_LOG" ]]; then
    echo "TypeORM logs found:"
    echo "$TYPEORM_LOG"
else
    echo "No TypeORM logs found (checking for errors...)"
    ERROR_LOG=$(docker compose logs backend | grep -i "syntaxerror\|invalid or unexpected" | head -5)
    if [[ -n "$ERROR_LOG" ]]; then
        echo -e "${RED}✗ Syntax errors still present:${NC}"
        echo "$ERROR_LOG"
        exit 1
    fi
fi
echo ""

echo "=========================================="
echo -e "${GREEN}✅ Backend rebuild and test complete!${NC}"
echo "=========================================="
echo ""
echo "Backend is running at: http://localhost:3001"
echo "API Documentation: http://localhost:3001/api/docs"
echo ""
echo "To view live logs: docker compose logs backend -f"
echo "To stop backend: docker compose stop backend"
echo ""
