const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../db');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret';

// POST /api/auth/signup
router.post('/signup', async (req, res) => {
  try {
    const { username, email, password, role } = req.body;
    if (!username || !email || !password) return res.status(400).json({ error: 'Missing fields' });

    const { rows } = await db.query('SELECT id FROM users WHERE username=$1 OR email=$2', [username, email]);
    if (rows.length) return res.status(409).json({ error: 'User already exists' });

    const hashed = await bcrypt.hash(password, 10);
    const userRole = role && (role === 'teacher' || role === 'student') ? role : 'student';
    const insert = await db.query(
      'INSERT INTO users (username, email, password_hash, role, created_at) VALUES ($1,$2,$3,$4,now()) RETURNING id, username, email, role',
      [username, email, hashed, userRole]
    );
    const user = insert.rows[0];
    const token = jwt.sign({ id: user.id, username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { usernameOrEmail, password } = req.body;
    if (!usernameOrEmail || !password) return res.status(400).json({ error: 'Missing fields' });

    const { rows } = await db.query('SELECT id, username, email, password_hash, role FROM users WHERE username=$1 OR email=$1', [usernameOrEmail]);
    if (!rows.length) return res.status(401).json({ error: 'Invalid credentials' });
    const user = rows[0];
    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });
    const token = jwt.sign({ id: user.id, username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user.id, username: user.username, email: user.email, role: user.role } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Server error' });
  }
});

// GET /api/auth/me
router.get('/me', async (req, res) => {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) return res.status(401).json({ error: 'Missing token' });
  const token = auth.split(' ')[1];
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    const { rows } = await db.query('SELECT id, username, email, first_name, last_name, school, age, grade, address, role FROM users WHERE id=$1', [payload.id]);
    if (!rows.length) return res.status(404).json({ error: 'User not found' });
    res.json(rows[0]);
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token' });
  }
});

module.exports = router;
