const express = require('express');
const router = express.Router();
const db = require('../db');
const auth = require('../middleware/auth');

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
    const { first_name, last_name, school, age, grade, address } = req.body;
    const result = await db.query(
      'UPDATE users SET first_name=$1, last_name=$2, school=$3, age=$4, grade=$5, address=$6 WHERE id=$7 RETURNING id, username, email, first_name, last_name, school, age, grade, address, role',
      [first_name || null, last_name || null, school || null, age || null, grade || null, address || null, id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'User not found' });
    console.log('Updated user profile:', result.rows[0]);
    res.json(result.rows[0]);
  } catch (err) {
    console.error('PUT /api/users/:id error:', err);
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

module.exports = router;
