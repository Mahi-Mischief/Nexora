const express = require('express');
const db = require('../db');
const verifyToken = require('../middleware/auth');
const PDFDocument = require('pdfkit');

const router = express.Router();

// Middleware to verify token and teacher role
router.use(verifyToken);

const verifyTeacher = (req, res, next) => {
  if (req.userRole !== 'teacher') {
    return res.status(403).json({ error: 'Access denied. Teacher role required.' });
  }
  next();
};

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
      `INSERT INTO student_activities (student_id, activity_type, title, description, hours, date)
       VALUES ($1, $2, $3, $4, $5, $6)
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
