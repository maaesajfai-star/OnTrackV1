import { DataSource } from 'typeorm';
import { dataSourceOptions } from '../config/typeorm.config';
import * as bcrypt from 'bcrypt';

/**
 * Database initialization script
 * Runs migrations and creates initial admin user if needed
 */
async function initializeDatabase() {
  console.log('🔧 Initializing database...');

  const dataSource = new DataSource(dataSourceOptions);

  try {
    await dataSource.initialize();
    console.log('✓ Database connection established');

    // Run pending migrations
    console.log('📦 Running migrations...');
    const migrations = await dataSource.runMigrations({ transaction: 'all' });

    if (migrations.length > 0) {
      console.log(`✓ Ran ${migrations.length} migration(s):`);
      migrations.forEach(migration => {
        console.log(`  - ${migration.name}`);
      });
    } else {
      console.log('✓ No pending migrations');
    }

    // Check if admin user exists
    const userRepository = dataSource.getRepository('User');
    const adminExists = await userRepository
      .createQueryBuilder('user')
      .where('user.username = :username', { username: 'Admin' })
      .getOne();

    if (!adminExists) {
      console.log('👤 Creating default Admin user...');

      const hashedPassword = await bcrypt.hash('AdminAdmin@123', 12);

      await userRepository
        .createQueryBuilder()
        .insert()
        .into('users')
        .values({
          username: 'Admin',
          email: 'admin@uems.local',
          password: hashedPassword,
          firstName: 'System',
          lastName: 'Administrator',
          role: 'admin',
          isActive: true,
        })
        .execute();

      console.log('✓ Admin user created: Admin / AdminAdmin@123');
    } else {
      console.log('✓ Admin user already exists');
    }

    await dataSource.destroy();
    console.log('🎉 Database initialization completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Database initialization failed:', error);
    await dataSource.destroy();
    process.exit(1);
  }
}

initializeDatabase();
