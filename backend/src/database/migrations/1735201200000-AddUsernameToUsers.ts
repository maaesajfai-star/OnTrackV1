import { MigrationInterface, QueryRunner, TableColumn, TableIndex } from 'typeorm';

export class AddUsernameToUsers1735201200000 implements MigrationInterface {
  public async up(queryRunner: QueryRunner): Promise<void> {
    // Add username column
    await queryRunner.addColumn(
      'users',
      new TableColumn({
        name: 'username',
        type: 'varchar',
        length: '100',
        isUnique: true,
        isNullable: true, // Temporarily nullable for migration
      }),
    );

    // Generate usernames for existing users based on their email
    await queryRunner.query(`
      UPDATE users
      SET username = CONCAT('user_', SUBSTRING(email FROM 1 FOR POSITION('@' IN email) - 1))
      WHERE username IS NULL;
    `);

    // Make username NOT NULL after populating
    await queryRunner.changeColumn(
      'users',
      'username',
      new TableColumn({
        name: 'username',
        type: 'varchar',
        length: '100',
        isUnique: true,
        isNullable: false,
      }),
    );

    // Create unique index on username
    await queryRunner.createIndex(
      'users',
      new TableIndex({
        name: 'IDX_users_username',
        columnNames: ['username'],
        isUnique: true,
      }),
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop index
    await queryRunner.dropIndex('users', 'IDX_users_username');

    // Drop username column
    await queryRunner.dropColumn('users', 'username');
  }
}
