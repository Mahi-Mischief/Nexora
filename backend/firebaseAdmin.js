const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

// Supports either:
// 1) FIREBASE_SERVICE_ACCOUNT_JSON with full JSON string
// 2) FIREBASE_SERVICE_ACCOUNT with path to JSON file
const serviceAccountPath = process.env.FIREBASE_SERVICE_ACCOUNT;
const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;

function normalizePrivateKey(value) {
  if (!value || typeof value !== 'string') return value;
  return value.replace(/\\n/g, '\n');
}

function initializeFromJson(jsonString) {
  const parsed = JSON.parse(jsonString);
  if (parsed.private_key) parsed.private_key = normalizePrivateKey(parsed.private_key);
  admin.initializeApp({
    credential: admin.credential.cert(parsed),
  });
  console.log('firebaseAdmin: initialized from FIREBASE_SERVICE_ACCOUNT_JSON');
}

function initializeFromFile(filePath) {
  if (!filePath || !fs.existsSync(filePath)) {
    console.warn('firebaseAdmin: service account file not found at', filePath);
    return;
  }
  const serviceAccount = require(filePath);
  if (serviceAccount.private_key) {
    serviceAccount.private_key = normalizePrivateKey(serviceAccount.private_key);
  }
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
  });
  console.log('firebaseAdmin: initialized from service account file');
}

try {
  if (serviceAccountJson) {
    initializeFromJson(serviceAccountJson);
  } else if (serviceAccountPath) {
    initializeFromFile(path.resolve(serviceAccountPath));
  } else {
    console.warn('firebaseAdmin: no Firebase credentials configured (set FIREBASE_SERVICE_ACCOUNT_JSON or FIREBASE_SERVICE_ACCOUNT)');
  }
} catch (e) {
  // If the file isn't available, initialize without credentials (will fail verification calls).
  console.warn('firebaseAdmin: error loading service account:', e.message);
}

module.exports = admin;
