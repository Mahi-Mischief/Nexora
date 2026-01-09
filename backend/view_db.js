const db = require('./db');

async function viewDatabase() {
  try {
    console.log('\n=== DATABASE TABLES ===');
    const tables = await db.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public'
      ORDER BY table_name
    `);
    console.table(tables.rows);

    console.log('\n=== USERS ===');
    const users = await db.query('SELECT id, username, email, role, created_at FROM users ORDER BY id');
    console.table(users.rows);

    console.log('\n=== EVENTS ===');
    const events = await db.query('SELECT id, title, description, date, location FROM events ORDER BY id');
    console.table(events.rows);

    console.log('\n=== ANNOUNCEMENTS ===');
    const announcements = await db.query('SELECT id, title, content, created_at FROM announcements ORDER BY id');
    console.table(announcements.rows);

    process.exit(0);
  } catch (err) {
    console.error('Error:', err.message);
    process.exit(1);
  }
}

viewDatabase();
