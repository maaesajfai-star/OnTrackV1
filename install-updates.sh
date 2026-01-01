#!/bin/bash

###############################################################################
# OnTrack Dependency Update Installation Script
# Version: 1.0.0
# Date: 2026-01-01
# Description: Automated installation of security-patched dependencies
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project root
PROJECT_ROOT="/home/mahmoud/AI/Projects/claude-Version1"

# Log function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Banner
echo "###############################################################################"
echo "#                                                                             #"
echo "#           OnTrack Dependency Security Update Installation                  #"
echo "#                                                                             #"
echo "###############################################################################"
echo ""

# Check if running from correct directory
if [ ! -d "$PROJECT_ROOT" ]; then
    error "Project root not found at $PROJECT_ROOT"
    exit 1
fi

log "Starting dependency update installation..."
echo ""

###############################################################################
# Step 1: Backup current package-lock.json files
###############################################################################

log "Step 1: Creating backup of current state..."

BACKUP_DIR="$PROJECT_ROOT/dependency-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

if [ -f "$PROJECT_ROOT/backend/package-lock.json" ]; then
    cp "$PROJECT_ROOT/backend/package-lock.json" "$BACKUP_DIR/backend-package-lock.json"
    success "Backend package-lock.json backed up"
fi

if [ -f "$PROJECT_ROOT/frontend/package-lock.json" ]; then
    cp "$PROJECT_ROOT/frontend/package-lock.json" "$BACKUP_DIR/frontend-package-lock.json"
    success "Frontend package-lock.json backed up"
fi

success "Backup created at $BACKUP_DIR"
echo ""

###############################################################################
# Step 2: Clean backend dependencies
###############################################################################

log "Step 2: Cleaning backend dependencies..."

cd "$PROJECT_ROOT/backend"

if [ -d "node_modules" ]; then
    log "Removing backend node_modules..."
    rm -rf node_modules
    success "Backend node_modules removed"
fi

if [ -f "package-lock.json" ]; then
    log "Removing backend package-lock.json..."
    rm -f package-lock.json
    success "Backend package-lock.json removed"
fi

echo ""

###############################################################################
# Step 3: Install backend dependencies
###############################################################################

log "Step 3: Installing backend dependencies..."
log "This may take 2-5 minutes..."

cd "$PROJECT_ROOT/backend"

if npm install; then
    success "Backend dependencies installed successfully"
else
    error "Backend dependency installation failed"
    warning "To rollback, restore from: $BACKUP_DIR"
    exit 1
fi

echo ""

###############################################################################
# Step 4: Verify backend installation
###############################################################################

log "Step 4: Verifying backend installation..."

cd "$PROJECT_ROOT/backend"

# Check for vulnerabilities
log "Running npm audit..."
if npm audit --audit-level=high > /dev/null 2>&1; then
    success "Backend: No high/critical vulnerabilities found"
else
    warning "Backend: Some vulnerabilities may remain (check npm audit)"
fi

# Test compilation
log "Testing backend compilation..."
if npm run build > /dev/null 2>&1; then
    success "Backend compilation successful"
else
    error "Backend compilation failed"
    warning "Check build output for details"
    exit 1
fi

echo ""

###############################################################################
# Step 5: Clean frontend dependencies
###############################################################################

log "Step 5: Cleaning frontend dependencies..."

cd "$PROJECT_ROOT/frontend"

if [ -d "node_modules" ]; then
    log "Removing frontend node_modules..."
    rm -rf node_modules
    success "Frontend node_modules removed"
fi

if [ -f "package-lock.json" ]; then
    log "Removing frontend package-lock.json..."
    rm -f package-lock.json
    success "Frontend package-lock.json removed"
fi

echo ""

###############################################################################
# Step 6: Install frontend dependencies
###############################################################################

log "Step 6: Installing frontend dependencies..."
log "This may take 2-5 minutes..."

cd "$PROJECT_ROOT/frontend"

if npm install; then
    success "Frontend dependencies installed successfully"
else
    error "Frontend dependency installation failed"
    warning "To rollback, restore from: $BACKUP_DIR"
    exit 1
fi

echo ""

###############################################################################
# Step 7: Verify frontend installation
###############################################################################

log "Step 7: Verifying frontend installation..."

cd "$PROJECT_ROOT/frontend"

# Check for vulnerabilities
log "Running npm audit..."
if npm audit --audit-level=high > /dev/null 2>&1; then
    success "Frontend: No high/critical vulnerabilities found"
else
    warning "Frontend: Some vulnerabilities may remain (check npm audit)"
fi

# Test compilation
log "Testing frontend build..."
if npm run build > /dev/null 2>&1; then
    success "Frontend build successful"
else
    error "Frontend build failed"
    warning "Check build output for details"
    exit 1
fi

echo ""

###############################################################################
# Step 8: Generate installation report
###############################################################################

log "Step 8: Generating installation report..."

REPORT_FILE="$PROJECT_ROOT/installation-report-$(date +%Y%m%d-%H%M%S).txt"

cat > "$REPORT_FILE" <<EOF
OnTrack Dependency Update Installation Report
==============================================

Installation Date: $(date)
Backup Location: $BACKUP_DIR

Backend Status:
--------------
Package.json Location: $PROJECT_ROOT/backend/package.json
Node Modules: $(du -sh "$PROJECT_ROOT/backend/node_modules" | cut -f1)
Installed Packages: $(npm list --depth=0 2>/dev/null | grep -c "├─\|└─" || echo "Unknown")

Frontend Status:
---------------
Package.json Location: $PROJECT_ROOT/frontend/package.json
Node Modules: $(du -sh "$PROJECT_ROOT/frontend/node_modules" | cut -f1)
Installed Packages: $(npm list --depth=0 2>/dev/null | grep -c "├─\|└─" || echo "Unknown")

Security Status:
---------------
Backend Audit:
$(cd "$PROJECT_ROOT/backend" && npm audit 2>&1 || echo "Audit failed")

Frontend Audit:
$(cd "$PROJECT_ROOT/frontend" && npm audit 2>&1 || echo "Audit failed")

Next Steps:
----------
1. Review DEPENDENCY_UPDATE_MIGRATION_GUIDE.md for breaking changes
2. Run manual tests on both backend and frontend
3. Test database connections
4. Verify API functionality
5. Test authentication flows
6. Review SECURITY_AUDIT_REPORT.md for details

Rollback Instructions:
---------------------
If issues occur, restore package-lock.json files from:
$BACKUP_DIR

Then run:
cd $PROJECT_ROOT/backend && npm ci
cd $PROJECT_ROOT/frontend && npm ci
EOF

success "Installation report generated: $REPORT_FILE"
echo ""

###############################################################################
# Step 9: Summary
###############################################################################

echo "###############################################################################"
echo "#                                                                             #"
echo "#                        INSTALLATION COMPLETE                                #"
echo "#                                                                             #"
echo "###############################################################################"
echo ""

success "All dependencies updated successfully!"
echo ""

log "Summary:"
echo "  - Backend: $(cd "$PROJECT_ROOT/backend" && npm list 2>/dev/null | grep -c "├─\|└─" || echo "Unknown") packages installed"
echo "  - Frontend: $(cd "$PROJECT_ROOT/frontend" && npm list 2>/dev/null | grep -c "├─\|└─" || echo "Unknown") packages installed"
echo "  - Backup: $BACKUP_DIR"
echo "  - Report: $REPORT_FILE"
echo ""

warning "IMPORTANT: Review the following files before deployment:"
echo "  1. $PROJECT_ROOT/SECURITY_AUDIT_REPORT.md"
echo "  2. $PROJECT_ROOT/DEPENDENCY_UPDATE_MIGRATION_GUIDE.md"
echo "  3. $REPORT_FILE"
echo ""

log "Next steps:"
echo "  1. Run: cd $PROJECT_ROOT/backend && npm run start:dev"
echo "  2. Run: cd $PROJECT_ROOT/frontend && npm run dev"
echo "  3. Test all critical functionality"
echo "  4. Review migration guide for breaking changes"
echo "  5. Deploy to staging environment first"
echo ""

success "Update installation completed successfully!"
exit 0
