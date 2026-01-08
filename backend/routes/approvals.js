const express = require('express');
const router = express.Router();
const db = require('../db');
const auth = require('../middleware/auth');

// GET /api/approvals - teacher/admin sees pending approvals
router.get('/', auth, async (req, res) => {
  try {
    // In a real app check role
    const { rows } = await db.query('SELECT id, message_id, student_id, status, created_at FROM approvals ORDER BY created_at DESC');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST create approval request
router.post('/', auth, async (req, res) => {
  try {
    const { message_id } = req.body;
    const student_id = req.user.id;
    const { rows } = await db.query('INSERT INTO approvals (message_id, student_id, status, created_at) VALUES ($1,$2,$3,now()) RETURNING id, message_id, student_id, status, created_at', [message_id, student_id, 'pending']);
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// PATCH /api/approvals/:id - approve or reject
router.patch('/:id', auth, async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body; // approved or rejected
    if (!['approved', 'rejected', 'pending'].includes(status)) return res.status(400).json({ error: 'Invalid status' });
    await db.query('UPDATE approvals SET status=$1, decided_at=now() WHERE id=$2', [status, id]);
    const { rows } = await db.query('SELECT id, message_id, student_id, status, created_at, decided_at FROM approvals WHERE id=$1', [id]);
    res.json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router;
