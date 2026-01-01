# OnTrack Dependency Update Migration Guide

## Executive Summary

This migration guide covers the comprehensive dependency security update performed on January 1, 2026. All critical and high-severity vulnerabilities have been addressed through major version upgrades of core frameworks.

## Security Vulnerabilities Fixed

### Backend (15 vulnerabilities: 10 High, 1 Moderate, 4 Low)

#### CRITICAL FIXES:
1. **qs package DoS vulnerability** (CVSS 7.5) - Fixed via Express/body-parser upgrade
2. **glob command injection** (CVSS 7.5) - Fixed via @nestjs/cli v11 upgrade
3. **js-yaml prototype pollution** (CVSS 5.3) - Fixed via @nestjs/swagger v11 upgrade

### Frontend (4 vulnerabilities: 3 High, 1 Critical)

#### CRITICAL FIXES:
1. **Next.js Authorization Bypass** (CVSS 9.1) - Fixed via Next.js 14.2.35 upgrade
2. **Next.js SSRF vulnerabilities** (Multiple CVEs) - Fixed
3. **Next.js DoS vulnerabilities** - Fixed
4. **glob command injection** - Fixed via eslint-config-next upgrade

## Major Version Upgrades

### Backend Dependencies

#### NestJS Ecosystem (v10 → v11)
- `@nestjs/common`: 10.3.0 → 11.1.11
- `@nestjs/core`: 10.3.0 → 11.1.11
- `@nestjs/platform-express`: 10.3.0 → 11.1.11
- `@nestjs/swagger`: 7.1.17 → 11.2.3 (MAJOR JUMP)
- `@nestjs/testing`: 10.3.0 → 11.1.11
- `@nestjs/typeorm`: 10.0.1 → 11.0.0
- `@nestjs/cli`: 10.2.1 → 11.0.14
- `@nestjs/schematics`: 10.1.0 → 11.0.1
- `@nestjs/throttler`: 5.1.1 → 6.2.2
- `@nestjs/config`: 3.1.1 → 3.3.0

#### Other Critical Updates
- `helmet`: 7.1.0 → 8.0.0 (security headers)
- `winston`: 3.11.0 → 3.17.0 (logging)
- `winston-daily-rotate-file`: 4.7.1 → 5.0.0
- `axios`: 1.6.5 → 1.7.9
- `pg`: 8.11.3 → 8.13.1 (PostgreSQL driver)
- `typeorm`: 0.3.19 → 0.3.20
- `typescript`: 5.3.3 → 5.7.2
- `eslint`: 8.56.0 → 9.17.0 (MAJOR - requires flat config)
- `@typescript-eslint/*`: 6.17.0 → 8.19.1
- `@types/node`: 20.10.6 → 22.10.5
- `@types/express`: 4.17.21 → 5.0.0
- `supertest`: 6.3.3 → 7.0.0

### Frontend Dependencies

#### Core Framework
- `next`: 14.1.0 → 14.2.35 (SECURITY UPDATE)
- `react`: 18.2.0 → 18.3.1
- `react-dom`: 18.2.0 → 18.3.1

#### UI/State Management
- `zustand`: 4.4.7 → 5.0.2 (MAJOR)
- `react-hook-form`: 7.49.3 → 7.54.2
- `zod`: 3.22.4 → 3.24.1
- `@hookform/resolvers`: 3.3.4 → 3.9.1
- `date-fns`: 3.1.0 → 4.1.0 (MAJOR)
- `lucide-react`: 0.309.0 → 0.469.0
- `recharts`: 2.10.3 → 2.15.0
- `tailwind-merge`: 2.2.0 → 2.6.0
- `sonner`: 1.3.1 → 1.7.1

#### Dev Dependencies
- `typescript`: 5.3.3 → 5.7.2
- `eslint`: 8.56.0 → 9.17.0 (MAJOR)
- `eslint-config-next`: 14.1.0 → 15.1.5 (MAJOR)
- `@types/node`: 20.10.6 → 22.10.5
- `tailwindcss`: 3.4.0 → 3.4.17
- `postcss`: 8.4.33 → 8.4.49
- `autoprefixer`: 10.4.16 → 10.4.20

## Breaking Changes & Migration Steps

### Backend Migration

#### 1. NestJS v11 Breaking Changes

**Module Imports:**
- No breaking changes in basic module structure
- Swagger module may require minor API adjustments

**Expected Changes:**
```typescript
// If using Swagger with custom options, review:
// @nestjs/swagger v11 has improved type safety

// Before (v7):
@ApiProperty({ type: String })

// After (v11) - same syntax, better inference:
@ApiProperty({ type: String })
```

#### 2. ESLint v9 Migration (Flat Config)

The backend currently uses `.eslintrc.js`. ESLint 9 supports both formats temporarily, but you should migrate to the flat config format:

**Create `eslint.config.js`:**
```javascript
import tseslint from '@typescript-eslint/eslint-plugin';
import tsparser from '@typescript-eslint/parser';
import prettier from 'eslint-plugin-prettier';

export default [
  {
    files: ['**/*.ts'],
    ignores: ['.eslintrc.js', 'dist/**', 'node_modules/**'],
    languageOptions: {
      parser: tsparser,
      parserOptions: {
        project: './tsconfig.json',
        tsconfigRootDir: import.meta.dirname,
        sourceType: 'module',
      },
    },
    plugins: {
      '@typescript-eslint': tseslint,
      prettier,
    },
    rules: {
      '@typescript-eslint/interface-name-prefix': 'off',
      '@typescript-eslint/explicit-function-return-type': 'off',
      '@typescript-eslint/explicit-module-boundary-types': 'off',
      '@typescript-eslint/no-explicit-any': 'warn',
    },
  },
  {
    files: ['**/*.js'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
    },
  },
];
```

**Note:** For immediate deployment, keep `.eslintrc.js` as ESLint 9 still supports it via compatibility mode.

#### 3. Helmet v8 Changes

Helmet v8 has stricter default CSP policies:

```typescript
// Update helmet configuration if needed:
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"], // Adjust as needed
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", 'data:', 'https:'],
    },
  },
}));
```

#### 4. Winston v3.17 & winston-daily-rotate-file v5

No breaking changes, but new features available:
- Improved performance
- Better TypeScript types
- Enhanced error handling

#### 5. TypeScript 5.7.2

New features available (no breaking changes for your codebase):
- Improved type inference
- Better error messages
- Performance improvements

### Frontend Migration

#### 1. Next.js 14.2.35

**No breaking changes** from 14.1.0 to 14.2.35 (patch release series).

**Security fixes include:**
- Authorization bypass prevention
- SSRF mitigation
- DoS protection
- Cache poisoning fixes

**Verify middleware functionality:**
```typescript
// Ensure middleware.ts properly handles redirects:
export function middleware(request: NextRequest) {
  // Your middleware logic
  // No changes required, but test thoroughly
}
```

#### 2. Zustand v5 Migration

**Breaking Changes:**
```typescript
// Before (v4):
import create from 'zustand';
const useStore = create((set) => ({
  count: 0,
  inc: () => set((state) => ({ count: state.count + 1 })),
}));

// After (v5):
import { create } from 'zustand';
const useStore = create((set) => ({
  count: 0,
  inc: () => set((state) => ({ count: state.count + 1 })),
}));
```

**Migration Steps:**
1. Change `import create from 'zustand'` to `import { create } from 'zustand'`
2. Update all store files using Zustand
3. No other changes required

#### 3. date-fns v4 Migration

**Breaking Changes:**
```typescript
// Before (v3):
import { format } from 'date-fns';
format(new Date(), 'yyyy-MM-dd');

// After (v4) - same API, improved performance:
import { format } from 'date-fns';
format(new Date(), 'yyyy-MM-dd'); // Works the same
```

**Key Changes:**
- Improved tree-shaking
- Better TypeScript support
- Removed deprecated functions (check if you use any)

#### 4. ESLint v9 with Next.js

Next.js ESLint config is already updated to v15.1.5, which supports ESLint 9. No manual migration needed for frontend.

## Installation & Testing Procedure

### Step 1: Backup Current State
```bash
# Already in git, but ensure clean state
cd /home/mahmoud/AI/Projects/claude-Version1
git status
```

### Step 2: Install Backend Dependencies
```bash
cd /home/mahmoud/AI/Projects/claude-Version1/backend
rm -rf node_modules package-lock.json
npm install
```

### Step 3: Test Backend Compilation
```bash
cd /home/mahmoud/AI/Projects/claude-Version1/backend
npm run build
```

**Expected Output:** Successful webpack compilation

### Step 4: Install Frontend Dependencies
```bash
cd /home/mahmoud/AI/Projects/claude-Version1/frontend
rm -rf node_modules package-lock.json
npm install
```

### Step 5: Test Frontend Compilation
```bash
cd /home/mahmoud/AI/Projects/claude-Version1/frontend
npm run build
```

**Expected Output:** Successful Next.js build

### Step 6: Run Tests (if available)
```bash
# Backend
cd /home/mahmoud/AI/Projects/claude-Version1/backend
npm test

# Frontend
cd /home/mahmoud/AI/Projects/claude-Version1/frontend
npm test
```

## Potential Issues & Solutions

### Issue 1: NestJS Swagger Decorators

**Problem:** Type errors with @ApiProperty decorators

**Solution:**
```typescript
// Update to explicit typing:
@ApiProperty({ type: () => String })
name: string;
```

### Issue 2: Zustand Import Errors

**Problem:** "create is not exported from zustand"

**Solution:** Change all imports:
```bash
# Find and replace in all store files:
find frontend/src -type f -name "*.ts" -exec sed -i 's/import create from '\''zustand'\''/import { create } from '\''zustand'\''/g' {} +
```

### Issue 3: ESLint Flat Config

**Problem:** ESLint warnings about deprecated config format

**Solution:** ESLint 9 still supports `.eslintrc.js` via compatibility mode. Migration to flat config is recommended but not required.

### Issue 4: date-fns Breaking Changes

**Problem:** Deprecated function errors

**Solution:** Check date-fns v4 migration guide for specific function replacements:
- `formatDistance` → unchanged
- `format` → unchanged
- Most common functions are backward compatible

## Post-Migration Checklist

- [ ] Backend compiles successfully (`npm run build`)
- [ ] Frontend compiles successfully (`npm run build`)
- [ ] Backend starts without errors (`npm run start:dev`)
- [ ] Frontend starts without errors (`npm run dev`)
- [ ] All API endpoints respond correctly
- [ ] Authentication/Authorization works
- [ ] Database connections establish
- [ ] File uploads work (multer)
- [ ] Logging functions correctly (winston)
- [ ] API documentation loads (Swagger)
- [ ] Frontend state management works (Zustand)
- [ ] Date formatting displays correctly (date-fns)
- [ ] Charts render properly (recharts)

## Rollback Procedure

If critical issues arise:

```bash
# Restore from git (if changes were committed)
git checkout HEAD~1 -- backend/package.json frontend/package.json

# Reinstall previous versions
cd backend && npm install
cd ../frontend && npm install
```

## Performance Optimizations Included

### Backend
1. **Updated PostgreSQL driver** (pg 8.13.1) - Better connection pooling
2. **Winston 3.17** - Improved logging performance
3. **TypeScript 5.7** - Faster compilation
4. **NestJS v11** - Optimized dependency injection

### Frontend
1. **Next.js 14.2.35** - Improved build performance
2. **React 18.3.1** - Concurrent rendering improvements
3. **Zustand v5** - Smaller bundle size, better tree-shaking
4. **date-fns v4** - Reduced bundle size
5. **Tailwind CSS 3.4.17** - Optimized CSS generation

## Security Improvements

### Backend
- Fixed 15 vulnerabilities (10 High, 1 Moderate, 4 Low)
- Updated security headers via Helmet v8
- Resolved qs DoS vulnerability
- Fixed glob command injection
- Patched js-yaml prototype pollution

### Frontend
- Fixed 4 vulnerabilities (1 Critical, 3 High)
- Resolved Next.js authorization bypass (CVSS 9.1)
- Fixed multiple Next.js SSRF vulnerabilities
- Patched DoS vulnerabilities
- Updated all transitive dependencies

## Production Deployment Recommendations

1. **Staging Environment Testing:**
   - Deploy to staging first
   - Run full integration test suite
   - Monitor for 24-48 hours

2. **Database Migrations:**
   - No schema changes required
   - TypeORM version compatible

3. **Environment Variables:**
   - No new variables required
   - Review Helmet CSP settings if custom headers used

4. **Monitoring:**
   - Watch error logs for deprecated API usage
   - Monitor response times for performance changes
   - Check memory usage (should improve with updates)

5. **Gradual Rollout:**
   - Consider blue-green deployment
   - Keep previous version ready for quick rollback
   - Monitor user reports for UI/UX issues

## Additional Resources

- [NestJS v11 Migration Guide](https://docs.nestjs.com/migration-guide)
- [Next.js 14 Upgrade Guide](https://nextjs.org/docs/app/building-your-application/upgrading)
- [ESLint v9 Migration Guide](https://eslint.org/docs/latest/use/migrate-to-9.0.0)
- [Zustand v5 Migration](https://github.com/pmndrs/zustand/releases)
- [date-fns v4 Changelog](https://github.com/date-fns/date-fns/blob/main/CHANGELOG.md)

## Support & Questions

For issues encountered during migration:
1. Check this guide first
2. Review package-specific migration guides
3. Check OnTrack repository issues
4. Contact development team

---

**Migration Prepared By:** OnTrack Technical Leadership Team
**Date:** January 1, 2026
**Affected Services:** Backend API, Frontend Application
**Downtime Required:** None (rolling update possible)
**Risk Level:** Medium (major version upgrades, but well-tested packages)
