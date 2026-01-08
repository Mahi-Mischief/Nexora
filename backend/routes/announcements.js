const express = require('express');
const router = express.Router();
const db = require('../db');
const auth = require('../middleware/auth');

// GET announcements
router.get('/', async (req, res) => {
  try {
    const { rows } = await db.query('SELECT id, title, content, created_at FROM announcements ORDER BY created_at DESC');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST announcement (protected)
router.post('/', auth, async (req, res) => {
  try {
    const { title, content } = req.body;
    const { rows } = await db.query('INSERT INTO announcements (title, content, created_by, created_at) VALUES ($1,$2,$3,now()) RETURNING id, title, content, created_at', [title, content, req.user.id]);
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
