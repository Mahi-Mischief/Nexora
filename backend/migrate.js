const db = require('./db');
require('dotenv').config();

async function migrate() {
  console.log('Running database migrations...');
  
  try {
    // Add approval columns to teams table
    console.log('Adding approval columns to teams table...');
    await db.query(`
      ALTER TABLE teams 
      ADD COLUMN IF NOT EXISTS approval_status VARCHAR(32) DEFAULT 'pending',
      ADD COLUMN IF NOT EXISTS approved_by INT REFERENCES users(id),
      ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP
    `);
    
    // Add approval columns to team_members table
    console.log('Adding approval columns to team_members table...');
    await db.query(`
      ALTER TABLE team_members 
      ADD COLUMN IF NOT EXISTS approval_status VARCHAR(32) DEFAULT 'pending',
      ADD COLUMN IF NOT EXISTS approved_by INT REFERENCES users(id),
      ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP
    `);
    
    // Create student_activities table
    console.log('Creating student_activities table...');
    await db.query(`
      CREATE TABLE IF NOT EXISTS student_activities (
        id SERIAL PRIMARY KEY,
        student_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        activity_type VARCHAR(64) NOT NULL,
        title VARCHAR(255) NOT NULL,
        description TEXT,
        hours DECIMAL(5,2) DEFAULT 0,
        date DATE NOT NULL,
        created_at TIMESTAMP DEFAULT now()
      )
    `);
    
    console.log('Migrations completed successfully!');
    process.exit(0);
  } catch (error) {
    console.error('Migration error:', error.message);
    process.exit(1);
  }
}

migrate();
