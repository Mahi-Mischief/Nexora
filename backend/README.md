NEXORA Backend (Node.js + Express)

Quick start (local PostgreSQL required):

1. Copy `.env.example` to `.env` and set `DATABASE_URL` and `JWT_SECRET`.

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

- `POST /api/auth/signup` { username, email, password }
- `POST /api/auth/login` { usernameOrEmail, password }
- `GET /api/auth/me` (Bearer token)
- `GET /api/events`
- `GET /api/announcements`
- `POST /api/messages` (Bearer token)
- `GET /api/social/feed`

Notes for Flutter integration:
- When running the Android emulator, use `http://10.0.2.2:3000` as the base URL to reach the host machine.
- Keep the splash screen short: fetch `GET /` or `GET /api/auth/me` and if the API responds, navigate forward; if the request takes longer than ~2s, proceed to the login screen and load remaining data in background.
