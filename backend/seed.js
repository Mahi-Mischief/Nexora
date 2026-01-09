const { Pool } = require('pg');
const bcrypt = require('bcrypt');
require('dotenv').config();

async function run() {
  try {
    // Create database if it doesn't exist
    const adminPool = new Pool({
      connectionString: process.env.DATABASE_URL.replace('/nexora_db', ''),
    });
    
    try {
      await adminPool.query('CREATE DATABASE nexora_db');
      console.log('Created nexora_db database');
    } catch (e) {
      if (!e.message.includes('already exists')) {
        throw e;
      }
    }
    await adminPool.end();

    // Connect to the actual database
    const db = require('./db');
    
    // Run schema
    const fs = require('fs');
    const path = require('path');
    const sql = fs.readFileSync(path.join(__dirname, 'sql', 'schema.sql'), 'utf8');
    await db.query(sql);

    // Create admin user if not exists
    const adminExists = await db.query('SELECT id FROM users WHERE username=$1', ['admin']);
    if (!adminExists.rows.length) {
      const hash = await bcrypt.hash('adminpass', 10);
      const r = await db.query('INSERT INTO users (username, email, password_hash, role, first_name) VALUES ($1,$2,$3,$4,$5) RETURNING id', ['admin', 'admin@nexora.local', hash, 'admin', 'Admin']);
      console.log('Created admin user id', r.rows[0].id);
    }

    // Sample event
    const ev = await db.query('SELECT id FROM events LIMIT 1');
    if (!ev.rows.length) {
      await db.query('INSERT INTO events (title, description, date, location, created_by) VALUES ($1,$2,$3,$4,$5)', ['Chapter Meeting', 'Monthly chapter meeting to discuss events and competitions.', new Date(Date.now() + 7 * 24 * 3600 * 1000), 'School Auditorium', 1]);
      console.log('Inserted sample event');
    }

    // Sample announcement
    const an = await db.query('SELECT id FROM announcements LIMIT 1');
    if (!an.rows.length) {
      await db.query('INSERT INTO announcements (title, content, created_by) VALUES ($1,$2,$3)', ['Welcome to NEXORA', 'This is a demo announcement. Check the calendar for upcoming events.', 1]);
      console.log('Inserted sample announcement');
    }

    console.log('Seeding complete');
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

run();
