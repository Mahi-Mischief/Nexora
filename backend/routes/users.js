const express = require('express');
const router = express.Router();
const db = require('../db');
const auth = require('../middleware/auth');

let announcementsSchemaReady = false;

async function ensureAnnouncementsSchema() {
  if (announcementsSchemaReady) return;
  await db.query('ALTER TABLE announcements ADD COLUMN IF NOT EXISTS school VARCHAR(128)');
  await db.query('ALTER TABLE announcements ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT now()');
  announcementsSchemaReady = true;
}

async function seedSchoolAnnouncementsIfMissing(school, createdBy) {
  const normalized = (school || '').trim();
  if (!normalized) return;

  await ensureAnnouncementsSchema();

  const existing = await db.query('SELECT COUNT(*)::int AS count FROM announcements WHERE school = $1', [normalized]);
  const count = existing.rows[0]?.count || 0;
  if (count > 0) return;

  const placeholders = [
    {
      title: `Welcome ${normalized} FBLA Chapter`,
      content: 'Welcome to your school announcements feed. Teachers can post chapter updates, reminders, and opportunities here.',
    },
    {
      title: 'Getting Started',
      content: 'Complete your profile, check the calendar, and watch this space for upcoming chapter events and important notices.',
    },
  ];

  for (const item of placeholders) {
    await db.query(
      `INSERT INTO announcements (title, content, school, created_by, created_at, updated_at)
       VALUES ($1, $2, $3, $4, now(), now())`,
      [item.title, item.content, normalized, createdBy]
    );
  }
}

// GET /api/users/:id
router.get('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { rows } = await db.query('SELECT id, username, email, first_name, last_name, school, age, grade, address FROM users WHERE id=$1', [id]);
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// PUT /api/users/:id - update profile
router.put('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    if (parseInt(req.user.id) !== parseInt(id) && req.user.role !== 'admin') return res.status(403).json({ error: 'Forbidden' });

    const currentUser = await db.query('SELECT school FROM users WHERE id = $1', [id]);
    if (currentUser.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    const previousSchool = (currentUser.rows[0].school || '').trim();

    const { first_name, last_name, school, age, grade, address } = req.body;
    const nextSchool = (school || '').trim();

    const result = await db.query(
      'UPDATE users SET first_name=$1, last_name=$2, school=$3, age=$4, grade=$5, address=$6 WHERE id=$7 RETURNING id, username, email, first_name, last_name, school, age, grade, address, role',
      [first_name || null, last_name || null, school || null, age || null, grade || null, address || null, id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });

    // Seed initial placeholders when school is added for the first time.
    if (!previousSchool && nextSchool) {
      await seedSchoolAnnouncementsIfMissing(nextSchool, parseInt(id));
    }

    console.log('Updated user profile:', result.rows[0]);
    res.json(result.rows[0]);
  } catch (err) {
    console.error('PUT /api/users/:id error:', err);
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

module.exports = router;
