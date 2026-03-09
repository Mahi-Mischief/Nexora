const express = require('express');
const db = require('../db');
const verifyToken = require('../middleware/auth');
const PDFDocument = require('pdfkit');

const router = express.Router();

// Middleware to verify token and teacher role
router.use(verifyToken);

let teacherSchemaReady = false;

async function ensureTeacherSchema() {
  if (teacherSchemaReady) return;

  await db.query(`
    CREATE TABLE IF NOT EXISTS student_activities (
      id SERIAL PRIMARY KEY,
      student_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      activity_type VARCHAR(64) NOT NULL,
      title VARCHAR(255) NOT NULL,
      description TEXT,
      hours NUMERIC(8,2) NOT NULL,
      date DATE NOT NULL,
      approval_status VARCHAR(32) DEFAULT 'pending',
      approved_by INT REFERENCES users(id),
      approved_at TIMESTAMP,
      created_at TIMESTAMP DEFAULT now()
    )
  `);

  // Backfill columns for older databases where student_activities already exists.
  await db.query('ALTER TABLE student_activities ADD COLUMN IF NOT EXISTS approval_status VARCHAR(32) DEFAULT \'pending\'');
  await db.query('ALTER TABLE student_activities ADD COLUMN IF NOT EXISTS approved_by INT REFERENCES users(id)');
  await db.query('ALTER TABLE student_activities ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP');

  await db.query('ALTER TABLE teams ADD COLUMN IF NOT EXISTS approval_status VARCHAR(32) DEFAULT \'pending\'');
  await db.query('ALTER TABLE teams ADD COLUMN IF NOT EXISTS approved_by INT REFERENCES users(id)');
  await db.query('ALTER TABLE teams ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP');

  await db.query('ALTER TABLE team_members ADD COLUMN IF NOT EXISTS approval_status VARCHAR(32) DEFAULT \'pending\'');
  await db.query('ALTER TABLE team_members ADD COLUMN IF NOT EXISTS approved_by INT REFERENCES users(id)');
  await db.query('ALTER TABLE team_members ADD COLUMN IF NOT EXISTS approved_at TIMESTAMP');

  await db.query(`
    CREATE TABLE IF NOT EXISTS event_signups (
      id SERIAL PRIMARY KEY,
      event_id INT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
      student_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      status VARCHAR(32) NOT NULL DEFAULT 'pending',
      created_at TIMESTAMP DEFAULT now(),
      decided_by INT REFERENCES users(id),
      decided_at TIMESTAMP,
      UNIQUE(event_id, student_id)
    )
  `);

  // Backfill columns for older databases where event_signups already exists.
  await db.query('ALTER TABLE event_signups ADD COLUMN IF NOT EXISTS status VARCHAR(32) NOT NULL DEFAULT \'pending\'');
  await db.query('ALTER TABLE event_signups ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT now()');
  await db.query('ALTER TABLE event_signups ADD COLUMN IF NOT EXISTS decided_by INT REFERENCES users(id)');
  await db.query('ALTER TABLE event_signups ADD COLUMN IF NOT EXISTS decided_at TIMESTAMP');

  teacherSchemaReady = true;
}

const verifyTeacher = (req, res, next) => {
  const role = (req.userRole || req.user?.role || '').toLowerCase();
  if (role !== 'teacher') {
    return res.status(403).json({ error: 'Access denied. Teacher role required.' });
  }
  next();
};

router.use(async (req, res, next) => {
  try {
    await ensureTeacherSchema();
    next();
  } catch (e) {
    next(e);
  }
});

// ===== TEAM APPROVAL ENDPOINTS =====

/**
 * GET /api/teacher/teams
 * Get all teams (pending and approved) for teacher's school
 */
router.get('/teams', verifyTeacher, async (req, res) => {
  try {
    const { rows: userRows } = await db.query('SELECT school FROM users WHERE id = $1', [req.userId]);
    const teacherSchool = userRows[0]?.school;

    if (!teacherSchool) {
      return res.status(400).json({ error: 'Teacher school not set' });
    }

    const result = await db.query(
      `SELECT 
        t.id,
        t.name,
        t.school,
        t.event_type,
        t.event_name,
        t.member_count,
        t.approval_status,
        t.created_by,
        u.username as created_by_username,
        u.first_name as created_by_first_name,
        u.last_name as created_by_last_name,
        t.created_at,
        t.approved_at,
        COUNT(tm.user_id) as actual_member_count
      FROM teams t
      JOIN users u ON t.created_by = u.id
      LEFT JOIN team_members tm ON t.id = tm.team_id
      WHERE t.school = $1
      GROUP BY t.id, u.username, u.first_name, u.last_name
      ORDER BY t.approval_status ASC, t.created_at DESC`,
      [teacherSchool]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching teams:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/teacher/teams/:id/members
 * Get all members of a team (pending and approved)
 */
router.get('/teams/:id/members', verifyTeacher, async (req, res) => {
  try {
    const teamId = parseInt(req.params.id);

    const result = await db.query(
      `SELECT 
        tm.id,
        tm.user_id,
        tm.approval_status,
        tm.created_at,
        tm.approved_at,
        u.username,
        u.first_name,
        u.last_name,
        u.email,
        u.grade
      FROM team_members tm
      JOIN users u ON tm.user_id = u.id
      WHERE tm.team_id = $1
      ORDER BY tm.approval_status ASC, tm.created_at DESC`,
      [teamId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching team members:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PUT /api/teacher/teams/:id/approve
 * Approve a team
 */
router.put('/teams/:id/approve', verifyTeacher, async (req, res) => {
  try {
    const teamId = parseInt(req.params.id);

    const result = await db.query(
      `UPDATE teams 
       SET approval_status = 'approved', approved_by = $1, approved_at = now()
       WHERE id = $2
       RETURNING *`,
      [req.userId, teamId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Team not found' });
    }

    res.json({ success: true, team: result.rows[0] });
  } catch (error) {
    console.error('Error approving team:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PUT /api/teacher/teams/:id/reject
 * Reject a team
 */
router.put('/teams/:id/reject', verifyTeacher, async (req, res) => {
  try {
    const teamId = parseInt(req.params.id);

    const result = await db.query(
      `UPDATE teams 
       SET approval_status = 'rejected', approved_by = $1, approved_at = now()
       WHERE id = $2
       RETURNING *`,
      [req.userId, teamId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Team not found' });
    }

    res.json({ success: true, team: result.rows[0] });
  } catch (error) {
    console.error('Error rejecting team:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PUT /api/teacher/teams/:teamId/members/:memberId/approve
 * Approve a team member join request
 */
router.put('/teams/:teamId/members/:memberId/approve', verifyTeacher, async (req, res) => {
  try {
    const memberId = parseInt(req.params.memberId);

    const result = await db.query(
      `UPDATE team_members 
       SET approval_status = 'approved', approved_by = $1, approved_at = now()
       WHERE id = $2
       RETURNING *`,
      [req.userId, memberId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Member not found' });
    }

    res.json({ success: true, member: result.rows[0] });
  } catch (error) {
    console.error('Error approving member:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PUT /api/teacher/teams/:teamId/members/:memberId/reject
 * Reject a team member join request
 */
router.put('/teams/:teamId/members/:memberId/reject', verifyTeacher, async (req, res) => {
  try {
    const memberId = parseInt(req.params.memberId);

    const result = await db.query(
      `UPDATE team_members 
       SET approval_status = 'rejected', approved_by = $1, approved_at = now()
       WHERE id = $2
       RETURNING *`,
      [req.userId, memberId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Member not found' });
    }

    res.json({ success: true, member: result.rows[0] });
  } catch (error) {
    console.error('Error rejecting member:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// ===== STUDENT ACTIVITY ENDPOINTS =====

/**
 * GET /api/teacher/students
 * Get all students from teacher's school
 */
router.get('/students', verifyTeacher, async (req, res) => {
  try {
    const { rows: userRows } = await db.query('SELECT school FROM users WHERE id = $1', [req.userId]);
    const teacherSchool = userRows[0]?.school;

    if (!teacherSchool) {
      return res.status(400).json({ error: 'Teacher school not set' });
    }

    const result = await db.query(
      `SELECT 
        u.id,
        u.username,
        u.email,
        u.first_name,
        u.last_name,
        u.grade,
        u.school,
        COALESCE(SUM(sa.hours), 0) as total_hours,
        COUNT(sa.id) as activity_count
      FROM users u
      LEFT JOIN student_activities sa ON u.id = sa.student_id
      WHERE u.role = 'student' AND u.school = $1
      GROUP BY u.id
      ORDER BY u.last_name, u.first_name`,
      [teacherSchool]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching students:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/teacher/students/:id/activities
 * Get all activities for a specific student
 */
router.get('/students/:id/activities', verifyTeacher, async (req, res) => {
  try {
    const studentId = parseInt(req.params.id);

    const result = await db.query(
      `SELECT 
        id,
        student_id,
        activity_type,
        title,
        description,
        hours,
        date,
        created_at
      FROM student_activities
      WHERE student_id = $1
      ORDER BY date DESC`,
      [studentId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching activities:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/teacher/students/:id/activities
 * Add an activity for a student (teacher can log on behalf of student)
 */
router.post('/students/:id/activities', verifyTeacher, async (req, res) => {
  try {
    const studentId = parseInt(req.params.id);
    const { activity_type, title, description, hours, date } = req.body;

    if (!activity_type || !title || !hours || !date) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const result = await db.query(
      `INSERT INTO student_activities (student_id, activity_type, title, description, hours, date, approval_status)
       VALUES ($1, $2, $3, $4, $5, $6, 'approved')
       RETURNING *`,
      [studentId, activity_type, title, description || '', parseFloat(hours), date]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error('Error adding activity:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/teacher/approvals/activities
 * Pending volunteering/activity hour approvals in teacher's school
 */
router.get('/approvals/activities', verifyTeacher, async (req, res) => {
  try {
    const { rows: schoolRows } = await db.query('SELECT school FROM users WHERE id = $1', [req.userId]);
    const school = schoolRows[0]?.school;
    if (!school) return res.status(400).json({ error: 'Teacher school not set' });

    const { rows } = await db.query(
      `SELECT
        sa.id,
        sa.student_id,
        sa.activity_type,
        sa.title,
        sa.description,
        sa.hours,
        sa.date,
        sa.approval_status,
        sa.created_at,
        u.username,
        u.first_name,
        u.last_name,
        u.school
      FROM student_activities sa
      JOIN users u ON u.id = sa.student_id
      WHERE u.school = $1 AND COALESCE(sa.approval_status, 'pending') = 'pending'
      ORDER BY sa.created_at DESC`,
      [school],
    );

    res.json(rows);
  } catch (error) {
    console.error('Error fetching pending activities:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PUT /api/teacher/students/:studentId/activities/:activityId/approve
 */
router.put('/students/:studentId/activities/:activityId/approve', verifyTeacher, async (req, res) => {
  try {
    const activityId = parseInt(req.params.activityId);
    const { rows } = await db.query(
      `UPDATE student_activities
       SET approval_status = 'approved', approved_by = $1, approved_at = now()
       WHERE id = $2
       RETURNING *`,
      [req.userId, activityId],
    );
    if (!rows.length) return res.status(404).json({ error: 'Activity not found' });
    res.json(rows[0]);
  } catch (error) {
    console.error('Error approving activity:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PUT /api/teacher/students/:studentId/activities/:activityId/reject
 */
router.put('/students/:studentId/activities/:activityId/reject', verifyTeacher, async (req, res) => {
  try {
    const activityId = parseInt(req.params.activityId);
    const { rows } = await db.query(
      `UPDATE student_activities
       SET approval_status = 'rejected', approved_by = $1, approved_at = now()
       WHERE id = $2
       RETURNING *`,
      [req.userId, activityId],
    );
    if (!rows.length) return res.status(404).json({ error: 'Activity not found' });
    res.json(rows[0]);
  } catch (error) {
    console.error('Error rejecting activity:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/teacher/approvals/signups
 * Pending event/volunteering signups for teacher's school
 */
router.get('/approvals/signups', verifyTeacher, async (req, res) => {
  try {
    const { rows: schoolRows } = await db.query('SELECT school FROM users WHERE id = $1', [req.userId]);
    const school = schoolRows[0]?.school;
    if (!school) return res.status(400).json({ error: 'Teacher school not set' });

    const { rows } = await db.query(
      `SELECT
        es.id,
        es.event_id,
        es.student_id,
        es.status,
        es.created_at,
        e.title AS event_title,
        e.date AS event_date,
        e.event_type,
        u.username,
        u.first_name,
        u.last_name,
        u.school
      FROM event_signups es
      JOIN events e ON e.id = es.event_id
      JOIN users u ON u.id = es.student_id
      WHERE e.school = $1 AND es.status = 'pending'
      ORDER BY es.created_at DESC`,
      [school],
    );

    res.json(rows);
  } catch (error) {
    console.error('Error fetching pending signups:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PUT /api/teacher/events/:eventId/signups/:signupId/approve
 */
router.put('/events/:eventId/signups/:signupId/approve', verifyTeacher, async (req, res) => {
  try {
    const signupId = parseInt(req.params.signupId);
    const { rows } = await db.query(
      `UPDATE event_signups
       SET status = 'approved', decided_by = $1, decided_at = now()
       WHERE id = $2
       RETURNING *`,
      [req.userId, signupId],
    );
    if (!rows.length) return res.status(404).json({ error: 'Signup not found' });
    res.json(rows[0]);
  } catch (error) {
    console.error('Error approving signup:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PUT /api/teacher/events/:eventId/signups/:signupId/reject
 */
router.put('/events/:eventId/signups/:signupId/reject', verifyTeacher, async (req, res) => {
  try {
    const signupId = parseInt(req.params.signupId);
    const { rows } = await db.query(
      `UPDATE event_signups
       SET status = 'rejected', decided_by = $1, decided_at = now()
       WHERE id = $2
       RETURNING *`,
      [req.userId, signupId],
    );
    if (!rows.length) return res.status(404).json({ error: 'Signup not found' });
    res.json(rows[0]);
  } catch (error) {
    console.error('Error rejecting signup:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/teacher/students/:id/pdf
 * Generate PDF log of student's volunteering hours
 */
router.get('/students/:id/pdf', verifyTeacher, async (req, res) => {
  try {
    const studentId = parseInt(req.params.id);

    // Get student info
    const { rows: studentRows } = await db.query(
      'SELECT id, username, first_name, last_name, email, school, grade FROM users WHERE id = $1',
      [studentId]
    );

    if (studentRows.length === 0) {
      return res.status(404).json({ error: 'Student not found' });
    }

    const student = studentRows[0];

    // Get activities
    const { rows: activities } = await db.query(
      `SELECT activity_type, title, description, hours, date
       FROM student_activities
       WHERE student_id = $1
       ORDER BY date DESC`,
      [studentId]
    );

    const totalHours = activities.reduce((sum, a) => sum + parseFloat(a.hours), 0);

    // Create PDF
    const doc = new PDFDocument({ margin: 50 });
    
    // Set response headers
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="FBLA_Log_${student.username}.pdf"`);
    
    doc.pipe(res);

    // Header
    doc.fontSize(20).text('FBLA Volunteering Hours Log', { align: 'center' });
    doc.moveDown();
    doc.fontSize(12).text(`Student: ${student.first_name || ''} ${student.last_name || ''} (${student.username})`, { align: 'center' });
    doc.text(`Email: ${student.email}`, { align: 'center' });
    doc.text(`School: ${student.school || 'N/A'}`, { align: 'center' });
    doc.text(`Grade: ${student.grade || 'N/A'}`, { align: 'center' });
    doc.moveDown();
    doc.fontSize(14).text(`Total Hours: ${totalHours.toFixed(2)}`, { align: 'center', underline: true });
    doc.moveDown(2);

    // Activities table
    if (activities.length === 0) {
      doc.fontSize(12).text('No activities logged yet.', { align: 'center' });
    } else {
      doc.fontSize(10);
      activities.forEach((activity, index) => {
        const activityDate = new Date(activity.date).toLocaleDateString();
        doc.fontSize(11).text(`${index + 1}. ${activity.title}`, { underline: true });
        doc.fontSize(9);
        doc.text(`   Type: ${activity.activity_type}`);
        doc.text(`   Date: ${activityDate}`);
        doc.text(`   Hours: ${parseFloat(activity.hours).toFixed(2)}`);
        if (activity.description) {
          doc.text(`   Description: ${activity.description}`);
        }
        doc.moveDown(0.5);
      });
    }

    // Footer
    doc.moveDown(2);
    doc.fontSize(8).text(`Generated on ${new Date().toLocaleDateString()}`, { align: 'center' });

    doc.end();
  } catch (error) {
    console.error('Error generating PDF:', error.message);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
