# CRITICAL FIXES REQUIRED BEFORE PRODUCTION

## ⚠️ DO NOT DEPLOY TO PRODUCTION WITHOUT FIXING THESE ISSUES

**Report Date:** January 1, 2026
**Platform:** OnTrack (formerly UEMS) v1.0
**Status:** NOT PRODUCTION READY

---

## P0 - MUST FIX IMMEDIATELY (Before any deployment)

### 1. Privilege Escalation Vulnerability ⚠️ CRITICAL

**File:** `backend/src/modules/auth/dto/register.dto.ts`
**Lines:** 27-30

**Current Code:**
```typescript
@IsEnum(['admin', 'hr_manager', 'sales_user', 'user'])
@IsOptional()
role?: string;
```

**Issue:** ANY user can register as admin by sending `role: 'admin'` in registration request.

**Fix:**
```typescript
// Remove role from RegisterDto entirely
// OR force it to 'user' only:
@IsEnum(['user'])
@IsOptional()
role?: string = 'user';
```

**Severity:** CRITICAL - Complete system compromise possible
**CVSS:** 9.8/10
**Exploit:** Trivial - `curl -X POST http://api/auth/register -d '{"role":"admin",...}'`

---

### 2. Refresh Token Not Hashed ⚠️ HIGH

**File:** `backend/src/modules/auth/auth.service.ts`
**Line:** 55-58

**Issue:** Refresh tokens stored as plain text in database.

**Fix:**
```typescript
import * as crypto from 'crypto';

// In generateTokens method:
const refreshToken = this.jwtService.sign(payload, { expiresIn: refreshExpiration });
const hashedRefreshToken = crypto.createHash('sha256').update(refreshToken).digest('hex');

await this.userRepository.update(user.id, {
  refreshToken: hashedRefreshToken  // Store hashed version
});

return { accessToken, refreshToken };  // Return plain version to client

// In refreshTokens method:
const hashedToken = crypto.createHash('sha256').update(refreshTokenDto.refreshToken).digest('hex');
const user = await this.userRepository.findOne({
  where: { refreshToken: hashedToken }  // Compare hashed versions
});
```

**Severity:** HIGH - Token theft if database compromised
**CVSS:** 7.5/10

---

### 3. Frontend is Non-Functional ⚠️ CRITICAL

**Issue:** Only 6 TypeScript files exist in frontend. No login page, no dashboard, no forms.

**Files Present:**
- `lib/api.ts` - API client (good)
- `app/page.tsx` - Landing page only
- 4 other minimal files

**Missing:**
- Login/Register pages
- Dashboard
- CRM module views (contacts, deals, organizations, activities)
- HRM module views (employees, candidates, job postings)
- DMS file browser
- Forms for CRUD operations
- State management implementation
- Error handling
- Loading states

**Fix Required:** Complete frontend development (2-4 weeks minimum)

**Severity:** CRITICAL - No product to demonstrate or sell
**Impact:** Cannot deploy, cannot demo to customers

---

## P1 - MUST FIX BEFORE PUBLIC DEPLOYMENT

### 4. Missing HTTPS Configuration ⚠️ HIGH

**File:** `nginx/conf.d/default.conf`

**Issue:** Only HTTP (port 80) configured, no SSL/TLS.

**Fix:** Add SSL configuration:
```nginx
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # ... rest of config
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name _;
    return 301 https://$host$request_uri;
}
```

**Severity:** HIGH - All traffic unencrypted
**CVSS:** 7.4/10

---

### 5. Missing Security Headers ⚠️ HIGH

**File:** `nginx/conf.d/default.conf`

**Issue:** No security headers configured.

**Fix:** Add to nginx config:
```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:;" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
```

**Severity:** HIGH - XSS, clickjacking, MIME sniffing attacks possible
**CVSS:** 6.5/10

---

### 6. Zero Test Coverage ⚠️ HIGH

**Issue:** `backend/test/` directory is empty. CI/CD will fail.

**Fix Required:**
1. Add unit tests for critical paths:
   - Authentication (login, register, refresh)
   - Authorization (role guards)
   - User CRUD operations
   - Token validation

2. Add integration tests:
   - API endpoints
   - Database operations
   - File uploads

3. Target: Minimum 60% coverage before production

**Severity:** HIGH - No quality assurance
**Impact:** CI/CD pipeline broken, bugs will reach production

---

### 7. Branding Inconsistency ⚠️ MEDIUM

**Issue:** Documentation says "UEMS", code says "OnTrack"

**Files Affected:**
- All *.md files in docs/
- README.md
- package.json descriptions
- Code comments
- Database seed data

**Fix:** Global find/replace "UEMS" → "OnTrack"

**Command:**
```bash
find . -type f \\( -name "*.md" -o -name "*.ts" -o -name "*.json" \\) \
  -exec sed -i 's/UEMS/OnTrack/g' {} +
```

**Severity:** MEDIUM - Confusing for users
**Impact:** Unprofessional appearance

---

### 8. CI/CD Pipeline Will Fail ⚠️ MEDIUM

**File:** `.github/workflows/ci.yml`
**Line:** 49

**Issue:** Pipeline runs `npm run test:cov` but no tests exist.

**Fix:**
```yaml
# Option 1: Skip tests until implemented
- name: Run backend tests
  run: npm run test:cov || echo "Tests not implemented yet"

# Option 2: Add actual tests (recommended)
- name: Run backend tests
  run: npm run test:cov
```

**Severity:** MEDIUM - Deployment pipeline broken
**Impact:** Cannot use automated deployments

---

## P2 - FIX BEFORE SCALE

### 9. No Pagination on List Endpoints ⚠️ MEDIUM

**Files:** All service files (`*service.ts`)

**Issue:** `findAll()` methods return ALL records, causing performance issues at scale.

**Example Fix:**
```typescript
// Before:
async findAll(): Promise<Contact[]> {
  return this.repo.find();
}

// After:
async findAll(page = 1, limit = 20): Promise<PaginatedResult<Contact>> {
  const [items, total] = await this.repo.findAndCount({
    skip: (page - 1) * limit,
    take: limit,
  });

  return {
    items,
    total,
    page,
    pages: Math.ceil(total / limit),
  };
}
```

**Severity:** MEDIUM - Performance degradation at scale
**Impact:** Slow responses with >1000 records

---

### 10. No Rate Limiting on Auth Endpoints ⚠️ MEDIUM

**Issue:** Global rate limiting exists, but auth endpoints need stricter limits.

**Fix:** Add specific throttling to auth controller:
```typescript
@Controller('auth')
@UseGuards(ThrottlerGuard)
@Throttle({ default: { limit: 5, ttl: 60000 } })  // 5 attempts per minute
export class AuthController {
  // ...
}
```

**Severity:** MEDIUM - Brute force attacks possible
**CVSS:** 5.3/10

---

## Summary Checklist

### Security (CRITICAL)
- [ ] Fix privilege escalation in registration
- [ ] Hash refresh tokens before storage
- [ ] Add HTTPS configuration
- [ ] Add security headers to nginx
- [ ] Add rate limiting to auth endpoints

### Functionality (CRITICAL)
- [ ] Build complete frontend (login, dashboard, forms)
- [ ] Add unit tests (minimum 60% coverage)
- [ ] Fix CI/CD pipeline

### Quality (MEDIUM)
- [ ] Complete UEMS → OnTrack rebrand
- [ ] Add pagination to all list endpoints
- [ ] Add monitoring and alerting
- [ ] Add database backups automation

---

## Deployment Timeline

### Week 1-2: Security Fixes
- Day 1-2: Fix privilege escalation and refresh token hashing
- Day 3-4: Add HTTPS and security headers
- Day 5-7: Add rate limiting and auth hardening
- Day 8-10: Security audit and penetration testing

### Week 3-4: Frontend Development
- Day 11-14: Login/Register pages
- Day 15-18: Dashboard and navigation
- Day 19-21: CRM module views
- Day 22-24: HRM module views
- Day 25-28: DMS integration and file browser

### Week 5-6: Testing & Quality
- Day 29-35: Unit test development
- Day 36-40: Integration test development
- Day 41-42: End-to-end testing

### Week 7-8: Final Preparation
- Day 43-49: Bug fixes and refinement
- Day 50-52: Performance testing
- Day 53-54: Documentation review
- Day 55-56: Production deployment

**Earliest Production Date:** February 25, 2026 (8 weeks from now)

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Security breach due to privilege escalation | HIGH | CRITICAL | Fix immediately |
| Data theft via token compromise | MEDIUM | HIGH | Hash tokens |
| MITM attacks without HTTPS | HIGH | HIGH | Add SSL/TLS |
| Brute force authentication | MEDIUM | MEDIUM | Rate limiting |
| Frontend delays deployment | HIGH | CRITICAL | Hire frontend developer |
| Test coverage delays | MEDIUM | HIGH | Start test development now |

---

## Recommended Immediate Actions

1. **Today:** Fix privilege escalation vulnerability
2. **This Week:**
   - Hash refresh tokens
   - Add HTTPS configuration
   - Start frontend development
3. **Next Week:**
   - Add security headers
   - Begin test development
   - Complete branding migration
4. **Month 1:** Complete security hardening
5. **Month 2:** Complete frontend and testing

---

**Report Prepared By:** OnTrack Technical Review Team
**Review Type:** Comprehensive Production Readiness Audit
**Classification:** INTERNAL - ACTION REQUIRED
**Next Review:** After critical fixes implemented
