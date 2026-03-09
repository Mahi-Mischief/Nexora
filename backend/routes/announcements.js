const express = require('express');
const router = express.Router();
const db = require('../db');
const auth = require('../middleware/auth');

let schemaReady = false;

async function ensureAnnouncementsSchema() {
  if (schemaReady) return;
  await db.query('ALTER TABLE announcements ADD COLUMN IF NOT EXISTS school VARCHAR(128)');
  await db.query('ALTER TABLE announcements ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT now()');
  schemaReady = true;
}

async function getRequester(req) {
  const { rows } = await db.query('SELECT id, role, school FROM users WHERE id = $1', [req.user.id]);
  return rows[0] || null;
}

// GET announcements for the requester's school
router.get('/', auth, async (req, res) => {
  try {
    await ensureAnnouncementsSchema();
    const requester = await getRequester(req);
    if (!requester) return res.status(404).json({ error: 'User not found' });
    if (!requester.school) {
      return res.status(400).json({ error: 'Add more profile information to access announcements' });
    }

    const { rows } = await db.query(
      `SELECT a.id, a.title, a.content, a.school, a.created_at, a.updated_at,
              a.created_by, u.username AS created_by_username, u.role AS created_by_role
       FROM announcements a
       LEFT JOIN users u ON u.id = a.created_by
       WHERE a.school = $1
       ORDER BY a.created_at DESC`,
      [requester.school]
    );
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST announcement (teachers only, scoped to teacher school)
router.post('/', auth, async (req, res) => {
  try {
    await ensureAnnouncementsSchema();
    const requester = await getRequester(req);
    if (!requester) return res.status(404).json({ error: 'User not found' });
    if (!requester.school) {
      return res.status(400).json({ error: 'Add more profile information to access announcements' });
    }
    if ((requester.role || '').toLowerCase() !== 'teacher') {
      return res.status(403).json({ error: 'Only teachers can manage announcements' });
    }

    const { title, content } = req.body;
    if (!title || !title.trim()) {
      return res.status(400).json({ error: 'Title is required' });
    }

    const { rows } = await db.query(
      `INSERT INTO announcements (title, content, school, created_by, created_at, updated_at)
       VALUES ($1, $2, $3, $4, now(), now())
       RETURNING id, title, content, school, created_at, updated_at, created_by`,
      [title.trim(), content || '', requester.school, req.user.id]
    );
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// PUT announcement (teachers only, same school)
router.put('/:id', auth, async (req, res) => {
  try {
    await ensureAnnouncementsSchema();
    const requester = await getRequester(req);
    if (!requester) return res.status(404).json({ error: 'User not found' });
    if (!requester.school) {
      return res.status(400).json({ error: 'Add more profile information to access announcements' });
    }
    if ((requester.role || '').toLowerCase() !== 'teacher') {
      return res.status(403).json({ error: 'Only teachers can manage announcements' });
    }

    const { id } = req.params;
    const { title, content } = req.body;
    if (!title || !title.trim()) {
      return res.status(400).json({ error: 'Title is required' });
    }

    const { rows } = await db.query(
      `UPDATE announcements
       SET title = $1, content = $2, updated_at = now()
       WHERE id = $3 AND school = $4
       RETURNING id, title, content, school, created_at, updated_at, created_by`,
      [title.trim(), content || '', id, requester.school]
    );

    if (!rows.length) return res.status(404).json({ error: 'Announcement not found in your school' });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// DELETE announcement (teachers only, same school)
router.delete('/:id', auth, async (req, res) => {
  try {
    await ensureAnnouncementsSchema();
    const requester = await getRequester(req);
    if (!requester) return res.status(404).json({ error: 'User not found' });
    if (!requester.school) {
      return res.status(400).json({ error: 'Add more profile information to access announcements' });
    }
    if ((requester.role || '').toLowerCase() !== 'teacher') {
      return res.status(403).json({ error: 'Only teachers can manage announcements' });
    }

    const { id } = req.params;
    const result = await db.query('DELETE FROM announcements WHERE id = $1 AND school = $2', [id, requester.school]);
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Announcement not found in your school' });
    }
    res.json({ success: true });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
