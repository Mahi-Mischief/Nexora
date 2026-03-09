const db = require('./db');

const MARKER = '[AUTO-FBLA-SEED]';

const GENERAL_TITLES = [
  'FBLA Chapter Strategy Session',
  'Competitive Event Practice Lab',
  'Leadership Workshop: Public Speaking',
  'NLC Preparation Roundtable',
  'FBLA Team Collaboration Sprint',
  'Business Case Study Review',
];

const VOLUNTEERING_TITLES = [
  'FBLA Community Service Outreach',
  'Volunteer Shift: School Supply Drive',
  'Neighborhood Business Support Day',
  'Volunteer Event: Financial Literacy Tutoring',
  'FBLA Service Project Planning',
  'Local Nonprofit Volunteer Team-Up',
];

const LOCATIONS = [
  'Main Campus Auditorium',
  'Business Lab Room 301',
  'Media Center',
  'Community Center Hall',
  'School Cafeteria',
  'Innovation Lab',
];

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function pick(arr) {
  return arr[randomInt(0, arr.length - 1)];
}

function startOfWeekMonday(date) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  const day = d.getDay(); // 0=Sun,1=Mon
  const diff = day === 0 ? -6 : 1 - day;
  d.setDate(d.getDate() + diff);
  return d;
}

function endOfWeekSunday(monday) {
  const d = new Date(monday);
  d.setDate(d.getDate() + 6);
  d.setHours(23, 59, 59, 999);
  return d;
}

function endOfMayOfYear(year) {
  return new Date(year, 4, 31, 23, 59, 59, 999);
}

function dateAtTime(baseDate, hour, minute) {
  const d = new Date(baseDate);
  d.setHours(hour, minute, 0, 0);
  return d;
}

async function hasEventTypeColumn() {
  const { rows } = await db.query(
    `SELECT 1
       FROM information_schema.columns
      WHERE table_name = 'events' AND column_name = 'event_type'
      LIMIT 1`
  );
  return rows.length > 0;
}

async function seededCountForUserWeek(userId, weekStart, weekEnd) {
  const { rows } = await db.query(
    `SELECT COUNT(*)::int AS count
       FROM events
      WHERE created_by = $1
        AND date >= $2
        AND date <= $3
        AND description LIKE $4`,
    [userId, weekStart, weekEnd, `%${MARKER}%`]
  );
  return rows[0]?.count || 0;
}

async function insertEvent(userId, eventDate, type, hasEventType) {
  const isVolunteering = type === 'volunteering';
  const title = isVolunteering ? pick(VOLUNTEERING_TITLES) : pick(GENERAL_TITLES);
  const location = pick(LOCATIONS);
  const description = `${MARKER} ${
    isVolunteering
      ? 'Participate in chapter-led service to build leadership through impact.'
      : 'Develop FBLA-ready skills through guided chapter activities and collaboration.'
  }`;

  if (hasEventType) {
    await db.query(
      `INSERT INTO events (title, description, date, location, created_by, event_type)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [title, description, eventDate, location, userId, type]
    );
    return;
  }

  await db.query(
    `INSERT INTO events (title, description, date, location, created_by)
     VALUES ($1, $2, $3, $4, $5)`,
    [title, description, eventDate, location, userId]
  );
}

async function run() {
  const hasType = await hasEventTypeColumn();
  const { rows: users } = await db.query('SELECT id FROM users ORDER BY id');
  if (!users.length) {
    console.log('No users found. Nothing to seed.');
    return;
  }

  const now = new Date();
  let weekStart = startOfWeekMonday(now);
  const cutoff = endOfMayOfYear(now.getFullYear());

  let inserted = 0;
  while (weekStart <= cutoff) {
    const weekEnd = endOfWeekSunday(weekStart);

    for (const user of users) {
      const userId = user.id;
      const existing = await seededCountForUserWeek(userId, weekStart, weekEnd);
      let remaining = Math.max(0, 2 - existing);
      if (remaining === 0) continue;

      // Pick two distinct weekdays (Mon-Fri offsets 0..4)
      const dayA = randomInt(0, 4);
      let dayB = randomInt(0, 4);
      while (dayB === dayA) dayB = randomInt(0, 4);
      const chosenDays = [dayA, dayB];

      const plan = [
        { dayOffset: chosenDays[0], type: 'general', hour: randomInt(15, 17), minute: [0, 15, 30, 45][randomInt(0, 3)] },
        { dayOffset: chosenDays[1], type: 'volunteering', hour: randomInt(16, 18), minute: [0, 15, 30, 45][randomInt(0, 3)] },
      ];

      for (const p of plan) {
        if (remaining <= 0) break;
        const day = new Date(weekStart);
        day.setDate(day.getDate() + p.dayOffset);
        const eventDate = dateAtTime(day, p.hour, p.minute);

        await insertEvent(userId, eventDate, p.type, hasType);
        inserted += 1;
        remaining -= 1;
      }
    }

    weekStart = new Date(weekStart);
    weekStart.setDate(weekStart.getDate() + 7);
  }

  console.log(`Seed complete. Inserted ${inserted} placeholder events.`);
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('Seed failed:', err.message || err);
    process.exit(1);
  });
