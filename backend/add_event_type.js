const db = require('./db');

async function migrate() {
  try {
    console.log('Adding event_type column to events table...');
    
    await db.query(`
      ALTER TABLE events 
      ADD COLUMN IF NOT EXISTS event_type VARCHAR(64) DEFAULT 'general'
    `);
    
    console.log('✓ Migration complete!');
    process.exit(0);
  } catch (err) {
    console.error('Migration error:', err);
    process.exit(1);
  }
}

migrate();
