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

    // Sample events
    const ev = await db.query('SELECT id FROM events LIMIT 1');
    if (!ev.rows.length) {
      const now = new Date();
      const events = [
        {
          title: 'Chapter Meeting',
          description: 'Monthly chapter meeting to discuss upcoming competitions, fundraising ideas, and community service opportunities.',
          date: new Date(now.getTime() + 3 * 24 * 3600 * 1000),
          location: 'Room 204'
        },
        {
          title: 'Regional Leadership Conference',
          description: 'Join us for the Regional Leadership Conference! Compete in various events, attend workshops, and network with FBLA members from across the region.',
          date: new Date(now.getTime() + 15 * 24 * 3600 * 1000),
          location: 'Convention Center Downtown'
        },
        {
          title: 'Business Plan Workshop',
          description: 'Learn how to create a winning business plan for the FBLA competition. Industry professionals will share tips and review sample plans.',
          date: new Date(now.getTime() + 7 * 24 * 3600 * 1000),
          location: 'Business Lab, Room 301'
        },
        {
          title: 'Community Service Day',
          description: 'Volunteer at the local food bank as part of our community service initiative. This counts toward your volunteering hours requirement.',
          date: new Date(now.getTime() + 10 * 24 * 3600 * 1000),
          location: 'City Food Bank'
        },
        {
          title: 'Career Fair',
          description: 'Meet with local business professionals and learn about career opportunities in various fields. Bring your resume!',
          date: new Date(now.getTime() + 20 * 24 * 3600 * 1000),
          location: 'School Gymnasium'
        },
        {
          title: 'State Competition Prep',
          description: 'Final preparation session for State Leadership Conference competitors. Practice your presentations and get feedback from advisors.',
          date: new Date(now.getTime() + 25 * 24 * 3600 * 1000),
          location: 'School Auditorium'
        },
        {
          title: 'Fundraiser Pizza Night',
          description: 'Join us for our annual pizza fundraiser! All proceeds go towards funding our trip to the National Leadership Conference.',
          date: new Date(now.getTime() + 12 * 24 * 3600 * 1000),
          location: 'School Cafeteria'
        }
      ];
      
      for (const event of events) {
        await db.query(
          'INSERT INTO events (title, description, date, location, created_by) VALUES ($1,$2,$3,$4,$5)',
          [event.title, event.description, event.date, event.location, 1]
        );
      }
      console.log('Inserted sample events');
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
