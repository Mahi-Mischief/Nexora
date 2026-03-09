const jwt = require('jsonwebtoken');
require('dotenv').config();
const admin = require('../firebaseAdmin');
const { ensureLocalUserFromFirebase } = require('../services/firebase_user');

const secret = process.env.JWT_SECRET || 'dev_secret';

async function authMiddleware(req, res, next) {
  const auth = req.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) return res.status(401).json({ error: 'Missing token' });
  const token = auth.split(' ')[1];

  // Primary path: Firebase ID token
  if (admin.apps && admin.apps.length > 0) {
    try {
      const decoded = await admin.auth().verifyIdToken(token);
      const user = await ensureLocalUserFromFirebase(decoded);
      req.user = { id: user.id, username: user.username, role: user.role, firebase_uid: decoded.uid };
      req.userId = user.id;
      req.userRole = user.role;
      req.firebase = decoded;
      return next();
    } catch (_) {
      // Fall through to legacy JWT verification for compatibility.
    }
  }

  // Legacy fallback path: app-issued JWT
  try {
    const payload = jwt.verify(token, secret);
    req.user = payload; // { id, username, role }
    req.userId = payload.id;
    req.userRole = payload.role;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Invalid token' });
  }
}

module.exports = authMiddleware;
