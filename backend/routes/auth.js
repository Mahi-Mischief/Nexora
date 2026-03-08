const express = require('express');
const admin = require('../firebaseAdmin');
const auth = require('../middleware/auth');
const { ensureFirebaseSchema, ensureLocalUserFromFirebase } = require('../services/firebase_user');

const router = express.Router();

// Legacy endpoint kept to avoid silent failures in older clients.
router.post('/signup', async (req, res) => {
  return res.status(410).json({
    error: 'Deprecated endpoint. Use Firebase Authentication on the client, then call POST /api/auth/sync with a Firebase ID token.',
  });
});

// Legacy endpoint kept to avoid silent failures in older clients.
router.post('/login', async (req, res) => {
  return res.status(410).json({
    error: 'Deprecated endpoint. Use Firebase Authentication on the client, then call POST /api/auth/sync with a Firebase ID token.',
  });
});

// POST /api/auth/google
// Accepts a Firebase ID token from Google sign-in, verifies it, and syncs local user.
router.post('/google', async (req, res) => {
  try {
    const { idToken } = req.body;
    if (!idToken) return res.status(400).json({ error: 'Missing idToken' });

    if (!admin.apps || admin.apps.length === 0) {
      return res.status(503).json({
        error: 'Firebase Admin is not configured on the backend. Set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT.',
      });
    }

    await ensureFirebaseSchema();
    const decoded = await admin.auth().verifyIdToken(idToken);
    const user = await ensureLocalUserFromFirebase(decoded, { role: 'student' });

    // Use Firebase ID token as the single auth token across the stack.
    return res.json({ token: idToken, user });
  } catch (err) {
    console.error('Google auth error:', err.message);
    return res.status(401).json({ error: 'Invalid Google token' });
  }
});

// POST /api/auth/sync
// Requires Bearer Firebase ID token and returns the mapped/upserted local user.
router.post('/sync', auth, async (req, res) => {
  try {
    if (!req.firebase) {
      return res.status(401).json({ error: 'Expected Firebase token' });
    }

    const { username, role } = req.body || {};
    const user = await ensureLocalUserFromFirebase(req.firebase, { username, role });
    return res.json({ user });
  } catch (err) {
    console.error('Auth sync error:', err.message);
    return res.status(500).json({ error: 'Failed to sync user' });
  }
});

// GET /api/auth/me
router.get('/me', auth, async (req, res) => {
  try {
    if (!req.firebase) {
      return res.status(401).json({ error: 'Expected Firebase token' });
    }
    const user = await ensureLocalUserFromFirebase(req.firebase, {});
    return res.json(user);
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token' });
  }
});

module.exports = router;
