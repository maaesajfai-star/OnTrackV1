import { ConfigService } from '@nestjs/config';
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { DataSource, DataSourceOptions } from 'typeorm';
import { join } from 'path';

export const typeOrmConfig = (
  configService: ConfigService,
): TypeOrmModuleOptions => {
  const nodeEnv = configService.get('NODE_ENV', 'development');
  const isDevelopment = nodeEnv === 'development';

  // Use absolute paths from project root to avoid __dirname issues with ts-node
  const srcPath = join(process.cwd(), 'src');
  const distPath = join(process.cwd(), 'dist');

  // In development with ts-node, always use .ts files from src
  // In production, use .js files from dist
  const entitiesPath = isDevelopment
    ? [join(srcPath, '**', '*.entity.ts')]
    : [join(distPath, '**', '*.entity.js')];

  const migrationsPath = isDevelopment
    ? [join(srcPath, 'database', 'migrations', '*.ts')]
    : [join(distPath, 'database', 'migrations', '*.js')];

  console.log('[TypeORM] Configuration:', {
    nodeEnv,
    isDevelopment,
    entitiesPath,
    migrationsPath,
  });

  return {
    type: 'postgres',
    host: configService.get('POSTGRES_HOST', 'localhost'),
    port: configService.get('POSTGRES_PORT', 5432),
    username: configService.get('POSTGRES_USER', 'uems_user'),
    password: configService.get('POSTGRES_PASSWORD'),
    database: configService.get('POSTGRES_DB', 'uems_db'),
    entities: entitiesPath,
    migrations: migrationsPath,
    synchronize: false,
    migrationsRun: false,
    logging: isDevelopment ? ['error', 'warn', 'migration'] : ['error'],
    ssl: configService.get('NODE_ENV') === 'production' ? { rejectUnauthorized: false } : false,
    extra: {
      max: configService.get('DB_POOL_MAX', 10),
      min: configService.get('DB_POOL_MIN', 2),
      connectionTimeoutMillis: configService.get('DB_CONNECTION_TIMEOUT', 30000),
    },
  };
};

// DataSource for migrations (uses .ts files in development/migration context)
export const dataSourceOptions: DataSourceOptions = {
  type: 'postgres',
  host: process.env.POSTGRES_HOST || 'localhost',
  port: parseInt(process.env.POSTGRES_PORT || '5432'),
  username: process.env.POSTGRES_USER || 'uems_user',
  password: process.env.POSTGRES_PASSWORD,
  database: process.env.POSTGRES_DB || 'uems_db',
  entities: [join(process.cwd(), 'src', '**', '*.entity.ts')],
  migrations: [join(process.cwd(), 'src', 'database', 'migrations', '*.ts')],
};

const dataSource = new DataSource(dataSourceOptions);
export default dataSource;
