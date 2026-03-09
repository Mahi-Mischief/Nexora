const express = require('express');
const router = express.Router();
const db = require('../db');
const auth = require('../middleware/auth');

let schemaReady = false;

async function ensureSchema() {
  if (schemaReady) return;
  await db.query('ALTER TABLE events ADD COLUMN IF NOT EXISTS school VARCHAR(128)');
  await db.query('ALTER TABLE events ADD COLUMN IF NOT EXISTS event_type VARCHAR(64) DEFAULT \'general\'');
  await db.query('ALTER TABLE events ADD COLUMN IF NOT EXISTS details TEXT');
  await db.query(`
    CREATE TABLE IF NOT EXISTS event_signups (
      id SERIAL PRIMARY KEY,
      event_id INT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
      student_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      status VARCHAR(32) NOT NULL DEFAULT 'pending',
      created_at TIMESTAMP DEFAULT now(),
      decided_by INT REFERENCES users(id),
      decided_at TIMESTAMP,
      UNIQUE(event_id, student_id)
    )
  `);
  schemaReady = true;
}

router.use(auth);

const verifyTeacher = (req, res, next) => {
  const role = (req.userRole || req.user?.role || '').toLowerCase();
  if (role !== 'teacher') {
    return res.status(403).json({ error: 'Teacher role required' });
  }
  next();
};

async function getRequesterSchool(userId) {
  const { rows } = await db.query('SELECT school FROM users WHERE id = $1', [userId]);
  return (rows[0]?.school || '').trim();
}

// GET /api/events (school-scoped)
router.get('/', async (req, res) => {
  try {
    await ensureSchema();
    const school = await getRequesterSchool(req.userId);
    if (!school) {
      return res.status(400).json({ error: 'Add school to profile to access events' });
    }

    const { rows } = await db.query(
      `SELECT id, title, description, details, date, location, event_type, school, created_by
       FROM events
       WHERE school = $1
       ORDER BY date`,
      [school],
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/events/:id
router.get('/:id', async (req, res) => {
  try {
    await ensureSchema();
    const { id } = req.params;
    const school = await getRequesterSchool(req.userId);
    const { rows } = await db.query(
      `SELECT id, title, description, details, date, location, event_type, school, created_by
       FROM events WHERE id = $1 AND school = $2`,
      [id, school],
    );
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/events (teacher only)
router.post('/', verifyTeacher, async (req, res) => {
  try {
    await ensureSchema();
    const { title, description, details, date, location, event_type } = req.body;
    if (!title || !date) {
      return res.status(400).json({ error: 'Title and date are required' });
    }
    const school = await getRequesterSchool(req.userId);
    if (!school) {
      return res.status(400).json({ error: 'Teacher school not set' });
    }

    const { rows } = await db.query(
      `INSERT INTO events (title, description, details, date, location, event_type, school, created_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       RETURNING id, title, description, details, date, location, event_type, school, created_by`,
      [
        title,
        description || '',
        details || '',
        date,
        location || '',
        (event_type || 'general').toLowerCase(),
        school,
        req.userId,
      ],
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// PUT /api/events/:id (teacher only)
router.put('/:id', verifyTeacher, async (req, res) => {
  try {
    await ensureSchema();
    const { id } = req.params;
    const { title, description, details, date, location, event_type } = req.body;
    const school = await getRequesterSchool(req.userId);

    const { rows } = await db.query(
      `UPDATE events
       SET title = $1,
           description = $2,
           details = $3,
           date = $4,
           location = $5,
           event_type = $6
       WHERE id = $7 AND school = $8 AND created_by = $9
       RETURNING id, title, description, details, date, location, event_type, school, created_by`,
      [
        title,
        description || '',
        details || '',
        date,
        location || '',
        (event_type || 'general').toLowerCase(),
        id,
        school,
        req.userId,
      ],
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Event not found or not owned by teacher' });
    }

    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE /api/events/:id (teacher only)
router.delete('/:id', verifyTeacher, async (req, res) => {
  try {
    await ensureSchema();
    const { id } = req.params;
    const school = await getRequesterSchool(req.userId);

    const result = await db.query(
      'DELETE FROM events WHERE id = $1 AND school = $2 AND created_by = $3 RETURNING id',
      [id, school, req.userId],
    );

    if (!result.rows.length) {
      return res.status(404).json({ error: 'Event not found or not owned by teacher' });
    }

    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/events/:id/signup (student sign up for school event)
router.post('/:id/signup', async (req, res) => {
  try {
    await ensureSchema();
    const { id } = req.params;
    const role = (req.userRole || req.user?.role || '').toLowerCase();
    if (role !== 'student') {
      return res.status(403).json({ error: 'Student role required' });
    }

    const school = await getRequesterSchool(req.userId);
    const { rows: eventRows } = await db.query('SELECT id FROM events WHERE id = $1 AND school = $2', [id, school]);
    if (!eventRows.length) {
      return res.status(404).json({ error: 'Event not found in your school' });
    }

    const signup = await db.query(
      `INSERT INTO event_signups (event_id, student_id, status)
       VALUES ($1, $2, 'pending')
       ON CONFLICT (event_id, student_id)
       DO UPDATE SET status = 'pending', decided_by = NULL, decided_at = NULL
       RETURNING id, event_id, student_id, status, created_at`,
      [id, req.userId],
    );

    res.status(201).json(signup.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/events/:id/my-signup (student status)
router.get('/:id/my-signup', async (req, res) => {
  try {
    await ensureSchema();
    const { id } = req.params;
    const result = await db.query(
      'SELECT id, event_id, student_id, status, created_at, decided_at FROM event_signups WHERE event_id = $1 AND student_id = $2',
      [id, req.userId],
    );
    if (!result.rows.length) return res.json(null);
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
