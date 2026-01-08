const express = require('express');
const router = express.Router();
const db = require('../db');
const auth = require('../middleware/auth');

// GET /api/events
router.get('/', async (req, res) => {
  try {
    const { rows } = await db.query('SELECT id, title, description, date, location FROM events ORDER BY date');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/events/:id
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { rows } = await db.query('SELECT id, title, description, date, location FROM events WHERE id=$1', [id]);
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/events (auth required)
router.post('/', auth, async (req, res) => {
  try {
    const { title, description, date, location } = req.body;
    const { rows } = await db.query('INSERT INTO events (title, description, date, location, created_by) VALUES ($1,$2,$3,$4,$5) RETURNING id, title, description, date, location', [title, description, date, location, req.user.id]);
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
