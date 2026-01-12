const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const db = require('../db');
require('dotenv').config();

const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret';
const admin = require('../firebaseAdmin');

// POST /api/auth/signup
router.post('/signup', async (req, res) => {
  try {
    const { username, email, password, role } = req.body;
    console.log('Signup attempt:', { username, email, role });
    if (!username || !email || !password) return res.status(400).json({ error: 'Missing fields' });

    const hashed = await bcrypt.hash(password, 10);
    const userRole = role && (role === 'teacher' || role === 'student') ? role : 'student';
    const insert = await db.query(
      'INSERT INTO users (username, email, password_hash, role, created_at) VALUES ($1,$2,$3,$4,now()) RETURNING id, username, email, role',
      [username, email, hashed, userRole]
    );
    const user = insert.rows[0];
    const token = jwt.sign({ id: user.id, username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
    console.log('User created successfully:', user.id);
    res.json({ token, user });
  } catch (err) {
    if (err && err.code === '23505') {
      console.error('SIGNUP DUPLICATE:', err.detail || err.message);
      return res.status(409).json({ error: 'Username or email already in use' });
    }
    console.error('SIGNUP ERROR:', err.message, err.code);
    res.status(500).json({ error: 'Server error: ' + err.message });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  try {
    const { usernameOrEmail, password } = req.body;
    if (!usernameOrEmail || !password) return res.status(400).json({ error: 'Missing fields' });

    const lowerInput = usernameOrEmail.toLowerCase();
    const { rows } = await db.query('SELECT id, username, email, password_hash, role, first_name, last_name, school, age, grade, address FROM users WHERE LOWER(username)=$1 OR LOWER(email)=$1', [lowerInput]);
    if (!rows.length) return res.status(401).json({ error: 'Invalid credentials' });
    const user = rows[0];
    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) return res.status(401).json({ error: 'Invalid credentials' });
    const token = jwt.sign({ id: user.id, username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user: { id: user.id, username: user.username, email: user.email, role: user.role, first_name: user.first_name, last_name: user.last_name, school: user.school, age: user.age, grade: user.grade, address: user.address } });
  } catch (err) {
    console.error('LOGIN ERROR:', err.message, err.code);
    res.status(500).json({ error: 'Server error: ' + err.message });
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

// POST /api/auth/google
router.post('/google', async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) return res.status(400).json({ error: 'Missing idToken' });

    let email, firstName, lastName;
    
    // Try to verify with Firebase if available, otherwise skip verification
    try {
      const decoded = await admin.auth().verifyIdToken(idToken);
      email = decoded.email;
      const name = decoded.name || '';
      firstName = name ? name.split(' ')[0] : null;
      lastName = name ? name.split(' ').slice(1).join(' ') : null;
    } catch (firebaseErr) {
      // Firebase not configured - for development, accept the token as-is
      // In production, this should not happen
      console.warn('Firebase verification not available, skipping token verification');
      // For now, reject since we can't verify
      return res.status(401).json({ error: 'Firebase not configured - cannot verify token' });
    }

    // find or create user by email
    let { rows } = await db.query('SELECT id, username, email, first_name, last_name, role, school, age, grade, address FROM users WHERE email=$1', [email]);
    let user;
    if (!rows.length) {
      const username = email.split('@')[0];
      // Generate a random password hash for OAuth users (they won't use it)
      const hashedPassword = await bcrypt.hash(email + Math.random(), 10);
      const r = await db.query(
        'INSERT INTO users (username, email, first_name, last_name, password_hash, role) VALUES ($1,$2,$3,$4,$5,$6) RETURNING id, username, email, first_name, last_name, role, school, age, grade, address',
        [username, email, firstName, lastName, hashedPassword, 'student']
      );
      user = r.rows[0];
    } else {
      user = rows[0];
    }

    const token = jwt.sign({ id: user.id, username: user.username, role: user.role }, JWT_SECRET, { expiresIn: '7d' });
    res.json({ token, user });
  } catch (err) {
    console.error('Google auth error', err);
    res.status(401).json({ error: 'Invalid token' });
  }
});

module.exports = router;
