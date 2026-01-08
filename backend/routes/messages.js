const express = require('express');
const router = express.Router();
const db = require('../db');
const auth = require('../middleware/auth');

// POST message - send a message (student -> student/teacher). Creates conversation if needed.
router.post('/', auth, async (req, res) => {
  try {
    const { to_user_id, content, type } = req.body; // type can be 'message' or 'request'
    const from_user_id = req.user.id;
    const { rows } = await db.query('INSERT INTO messages (from_user_id, to_user_id, content, type, status, created_at) VALUES ($1,$2,$3,$4,$5,now()) RETURNING id, from_user_id, to_user_id, content, type, status, created_at', [from_user_id, to_user_id, content, type || 'message', type === 'request' ? 'pending' : 'sent']);
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET messages for a user (inbox)
router.get('/', auth, async (req, res) => {
  try {
    const userId = req.user.id;
    const { rows } = await db.query('SELECT id, from_user_id, to_user_id, content, type, status, created_at FROM messages WHERE to_user_id=$1 OR from_user_id=$1 ORDER BY created_at DESC', [userId]);
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
