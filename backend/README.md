NEXORA Backend (Node.js + Express)

Quick start (local PostgreSQL required):

1. Copy `.env.example` to `.env` and set `DATABASE_URL` and `JWT_SECRET`.

	If you want Google/Firebase login to work, also set one of:
	- `FIREBASE_SERVICE_ACCOUNT=absolute_path_to_service_account.json`
	- `FIREBASE_SERVICE_ACCOUNT_JSON={...full service account JSON...}`

2. Install dependencies:

```bash
cd backend
npm install
```

3. Seed database (creates tables and a demo admin):

```bash
npm run seed
```

4. Start server:

```bash
npm start
```

API endpoints (examples):

- `POST /api/auth/signup` (deprecated; Firebase auth is used on client)
- `POST /api/auth/login` (deprecated; Firebase auth is used on client)
- `POST /api/auth/sync` (Bearer Firebase ID token, optional `{ username, role }`)
- `GET /api/auth/me` (Bearer token)
- `POST /api/auth/google` { idToken } (requires Firebase Admin credentials above)
- `GET /api/events`
- `GET /api/announcements`
- `POST /api/messages` (Bearer token)
- `GET /api/social/feed`

Notes for Flutter integration:
- When running the Android emulator, use `http://10.0.2.2:3000` as the base URL to reach the host machine.
- Keep the splash screen short: fetch `GET /` or `GET /api/auth/me` and if the API responds, navigate forward; if the request takes longer than ~2s, proceed to the login screen and load remaining data in background.
