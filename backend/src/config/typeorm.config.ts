import { ConfigService } from '@nestjs/config';
import { TypeOrmModuleOptions } from '@nestjs/typeorm';
import { DataSource, DataSourceOptions } from 'typeorm';

export const typeOrmConfig = (
  configService: ConfigService,
): TypeOrmModuleOptions => {
  const isDevelopment = configService.get('NODE_ENV') !== 'production';
  const fileExtension = isDevelopment ? 'ts' : 'js';

  return {
    type: 'postgres',
    host: configService.get('POSTGRES_HOST', 'localhost'),
    port: configService.get('POSTGRES_PORT', 5432),
    username: configService.get('POSTGRES_USER', 'uems_user'),
    password: configService.get('POSTGRES_PASSWORD'),
    database: configService.get('POSTGRES_DB', 'uems_db'),
    entities: [__dirname + `/../**/*.entity.${fileExtension}`],
    migrations: [__dirname + `/../database/migrations/*.${fileExtension}`],
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
  entities: [__dirname + '/../**/*.entity.ts'],
  migrations: [__dirname + '/../database/migrations/*.ts'],
};

const dataSource = new DataSource(dataSourceOptions);
export default dataSource;
