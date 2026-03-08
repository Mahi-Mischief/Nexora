const db = require('../db');

let ensuredSchema = false;

function isValidRole(role) {
  return role === 'student' || role === 'teacher' || role === 'admin';
}

function normalizeUsername(input, email) {
  const candidate = (input || '').trim() || (email ? email.split('@')[0] : 'user');
  const sanitized = candidate
    .toLowerCase()
    .replace(/[^a-z0-9_]/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 64);
  return sanitized || 'user';
}

async function ensureFirebaseSchema() {
  if (ensuredSchema) return;
  await db.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS firebase_uid VARCHAR(128) UNIQUE');
  await db.query('ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL');
  ensuredSchema = true;
}

async function getUniqueUsername(baseUsername) {
  let username = baseUsername;
  let attempt = 0;

  while (attempt < 25) {
    const { rows } = await db.query('SELECT id FROM users WHERE LOWER(username)=LOWER($1)', [username]);
    if (!rows.length) return username;
    attempt += 1;
    username = `${baseUsername}_${attempt}`.slice(0, 64);
  }

  return `${baseUsername}_${Date.now()}`.slice(0, 64);
}

async function ensureLocalUserFromFirebase(decodedToken, options = {}) {
  await ensureFirebaseSchema();

  const firebaseUid = decodedToken.uid;
  const email = (decodedToken.email || '').trim().toLowerCase();
  const name = (decodedToken.name || '').trim();
  const requestedUsername = options.username;
  const requestedRole = options.role;

  if (!firebaseUid || !email) {
    throw new Error('Firebase token must include uid and email');
  }

  let userRes = await db.query(
    'SELECT id, username, email, role, first_name, last_name, school, age, grade, address, firebase_uid FROM users WHERE firebase_uid=$1 OR LOWER(email)=LOWER($2) ORDER BY id LIMIT 1',
    [firebaseUid, email]
  );

  if (!userRes.rows.length) {
    const baseUsername = normalizeUsername(requestedUsername, email);
    const uniqueUsername = await getUniqueUsername(baseUsername);
    const firstName = name ? name.split(' ')[0] : null;
    const lastName = name ? name.split(' ').slice(1).join(' ') || null : null;
    const role = isValidRole(requestedRole) ? requestedRole : 'student';

    userRes = await db.query(
      'INSERT INTO users (firebase_uid, username, email, password_hash, role, first_name, last_name, created_at) VALUES ($1,$2,$3,$4,$5,$6,$7,now()) RETURNING id, username, email, role, first_name, last_name, school, age, grade, address',
      [firebaseUid, uniqueUsername, email, null, role, firstName, lastName]
    );

    return userRes.rows[0];
  }

  const currentUser = userRes.rows[0];
  const updates = [];
  const params = [];
  let idx = 1;

  if (!currentUser.firebase_uid) {
    updates.push(`firebase_uid=$${idx++}`);
    params.push(firebaseUid);
  }

  if (requestedUsername && requestedUsername.trim() && requestedUsername.trim() !== currentUser.username) {
    const uniqueUsername = await getUniqueUsername(normalizeUsername(requestedUsername, email));
    updates.push(`username=$${idx++}`);
    params.push(uniqueUsername);
  }

  if (isValidRole(requestedRole) && requestedRole !== currentUser.role) {
    updates.push(`role=$${idx++}`);
    params.push(requestedRole);
  }

  if (updates.length) {
    params.push(currentUser.id);
    await db.query(`UPDATE users SET ${updates.join(', ')} WHERE id=$${idx}`, params);
  }

  const refreshed = await db.query(
    'SELECT id, username, email, role, first_name, last_name, school, age, grade, address FROM users WHERE id=$1',
    [currentUser.id]
  );
  return refreshed.rows[0];
}

module.exports = {
  ensureFirebaseSchema,
  ensureLocalUserFromFirebase,
};
