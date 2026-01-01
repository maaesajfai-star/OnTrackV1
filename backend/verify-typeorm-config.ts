/**
 * Verification Script for TypeORM Configuration
 *
 * This script tests the TypeORM configuration to ensure paths are correctly resolved
 * Run with: npx ts-node verify-typeorm-config.ts
 */

import { join } from 'path';
import { existsSync, readdirSync } from 'fs';
import * as glob from 'glob';

console.log('==========================================');
console.log('TypeORM Configuration Verification');
console.log('==========================================\n');

// Check NODE_ENV
const nodeEnv = process.env.NODE_ENV || 'development';
console.log(`1. NODE_ENV: ${nodeEnv}`);
console.log(`   Is Development: ${nodeEnv === 'development'}\n`);

// Check working directory
const cwd = process.cwd();
console.log(`2. Working Directory: ${cwd}\n`);

// Check paths
const srcPath = join(cwd, 'src');
const distPath = join(cwd, 'dist');

console.log(`3. Paths:`);
console.log(`   - src exists: ${existsSync(srcPath)} (${srcPath})`);
console.log(`   - dist exists: ${existsSync(distPath)} (${distPath})\n`);

// Check entity files based on environment
const isDevelopment = nodeEnv === 'development';
const entitiesGlob = isDevelopment
  ? join(srcPath, '**', '*.entity.ts')
  : join(distPath, '**', '*.entity.js');

console.log(`4. Entity Pattern: ${entitiesGlob}\n`);

// Find entity files
try {
  const entityFiles = glob.sync(entitiesGlob);
  console.log(`5. Found ${entityFiles.length} entity files:`);

  if (entityFiles.length === 0) {
    console.log('   ⚠️  WARNING: No entity files found!\n');
  } else {
    entityFiles.forEach((file, index) => {
      const fileName = file.replace(cwd, '');
      const exists = existsSync(file);
      console.log(`   ${index + 1}. ${fileName} ${exists ? '✓' : '✗ FILE NOT FOUND'}`);
    });
    console.log();
  }

  // Check migrations
  const migrationsGlob = isDevelopment
    ? join(srcPath, 'database', 'migrations', '*.ts')
    : join(distPath, 'database', 'migrations', '*.js');

  console.log(`6. Migration Pattern: ${migrationsGlob}\n`);

  const migrationFiles = glob.sync(migrationsGlob);
  console.log(`7. Found ${migrationFiles.length} migration files:`);

  if (migrationFiles.length === 0) {
    console.log('   ℹ️  No migrations found (this is okay if none exist yet)\n');
  } else {
    migrationFiles.forEach((file, index) => {
      const fileName = file.replace(cwd, '');
      const exists = existsSync(file);
      console.log(`   ${index + 1}. ${fileName} ${exists ? '✓' : '✗ FILE NOT FOUND'}`);
    });
    console.log();
  }

  // Summary
  console.log('==========================================');
  console.log('Verification Summary');
  console.log('==========================================');

  const issues = [];

  if (!existsSync(srcPath)) {
    issues.push('❌ src directory does not exist');
  }

  if (isDevelopment && entityFiles.length === 0) {
    issues.push('❌ No .entity.ts files found in development mode');
  }

  if (!isDevelopment && !existsSync(distPath)) {
    issues.push('❌ dist directory does not exist in production mode');
  }

  if (!isDevelopment && entityFiles.length === 0) {
    issues.push('❌ No .entity.js files found in production mode');
  }

  if (issues.length === 0) {
    console.log('✅ All checks passed! TypeORM configuration should work correctly.');
  } else {
    console.log('⚠️  Issues found:');
    issues.forEach(issue => console.log(`   ${issue}`));
  }

} catch (error) {
  console.error('Error during verification:', error);
  process.exit(1);
}

console.log('==========================================\n');
