const express = require('express');
const db = require('../db');
const verifyToken = require('../middleware/auth');

const router = express.Router();

// Middleware to verify token
router.use(verifyToken);

/**
 * GET /api/teams/school?school=value
 * Fetch all teams in a given school
 */
router.get('/school', async (req, res) => {
  try {
    const { school } = req.query;
    if (!school) {
      return res.status(400).json({ error: 'School is required' });
    }

    const result = await db.query(
      `SELECT 
        t.id, 
        t.name, 
        t.school, 
        t.event_type, 
        t.event_name, 
        t.member_count, 
        t.created_by, 
        u.username as created_by_username,
        t.created_at,
        COUNT(tm.user_id) as actual_member_count
      FROM teams t
      JOIN users u ON t.created_by = u.id
      LEFT JOIN team_members tm ON t.id = tm.team_id
      WHERE t.school = $1
      GROUP BY t.id, t.name, t.school, t.event_type, t.event_name, t.member_count, t.created_by, u.username, t.created_at
      ORDER BY t.created_at DESC`,
      [school]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching teams:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * GET /api/teams/user/current
 * Fetch the current user's team
 */
router.get('/user/current', async (req, res) => {
  try {
    const userId = req.userId;

    const result = await db.query(
      `SELECT 
        t.id, 
        t.name, 
        t.school, 
        t.event_type, 
        t.event_name, 
        t.member_count, 
        t.created_by, 
        u.username as created_by_username,
        t.created_at
      FROM teams t
      JOIN team_members tm ON t.id = tm.team_id
      JOIN users u ON t.created_by = u.id
      WHERE tm.user_id = $1
      LIMIT 1`,
      [userId]
    );

    if (result.rows.length === 0) {
      return res.json(null);
    }

    res.json(result.rows[0]);
  } catch (error) {
    console.error('Error fetching user team:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/teams
 * Create a new team
 * Body: { name, school, event_type, event_name, member_count }
 */
router.post('/', async (req, res) => {
  try {
    const { name, school, event_type, event_name, member_count } = req.body;
    const userId = req.userId;

    // Validate input
    if (!name || !school || !event_type || !event_name || !member_count) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    // Check if user already has a team
    const existingTeam = await db.query(
      'SELECT id FROM team_members WHERE user_id = $1',
      [userId]
    );

    if (existingTeam.rows.length > 0) {
      return res.status(400).json({ error: 'User already has a team' });
    }

    // Create team
    const createTeamResult = await db.query(
      `INSERT INTO teams (name, school, event_type, event_name, member_count, created_by)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, name, school, event_type, event_name, member_count, created_by, created_at`,
      [name, school, event_type, event_name, member_count, userId]
    );

    const team = createTeamResult.rows[0];

    // Add creator as team member
    await db.query(
      'INSERT INTO team_members (team_id, user_id) VALUES ($1, $2)',
      [team.id, userId]
    );

    // Get creator username
    const userResult = await db.query('SELECT username FROM users WHERE id = $1', [userId]);
    const createdByUsername = userResult.rows[0]?.username || 'Unknown';

    res.status(201).json({
      ...team,
      created_by_username: createdByUsername,
    });
  } catch (error) {
    console.error('Error creating team:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/teams/:id/join
 * Join an existing team
 */
router.post('/:id/join', async (req, res) => {
  try {
    const teamId = parseInt(req.params.id);
    const userId = req.userId;

    // Check if user already has a team
    const existingTeam = await db.query(
      'SELECT id FROM team_members WHERE user_id = $1',
      [userId]
    );

    if (existingTeam.rows.length > 0) {
      return res.status(400).json({ error: 'User already has a team' });
    }

    // Check if team exists
    const teamResult = await db.query(
      'SELECT id FROM teams WHERE id = $1',
      [teamId]
    );

    if (teamResult.rows.length === 0) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Add user to team
    await db.query(
      'INSERT INTO team_members (team_id, user_id) VALUES ($1, $2)',
      [teamId, userId]
    );

    res.json({ success: true, message: 'Successfully joined team' });
  } catch (error) {
    console.error('Error joining team:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/teams/:id/leave
 * Leave a team
 */
router.post('/:id/leave', async (req, res) => {
  try {
    const teamId = parseInt(req.params.id);
    const userId = req.userId;

    // Check if user is in this team
    const memberResult = await db.query(
      'SELECT id FROM team_members WHERE team_id = $1 AND user_id = $2',
      [teamId, userId]
    );

    if (memberResult.rows.length === 0) {
      return res.status(400).json({ error: 'User is not a member of this team' });
    }

    // Check if user is the team creator
    const teamResult = await db.query(
      'SELECT created_by FROM teams WHERE id = $1',
      [teamId]
    );

    if (teamResult.rows[0].created_by === userId) {
      // If creator leaves, delete the entire team
      await db.query('DELETE FROM teams WHERE id = $1', [teamId]);
    } else {
      // Otherwise just remove the user from the team
      await db.query(
        'DELETE FROM team_members WHERE team_id = $1 AND user_id = $2',
        [teamId, userId]
      );
    }

    res.json({ success: true, message: 'Successfully left team' });
  } catch (error) {
    console.error('Error leaving team:', error.message);
    res.status(500).json({ error: error.message });
  }
});

// ===== TASK ENDPOINTS =====

/**
 * GET /api/teams/:id/tasks
 * Fetch all tasks for a team
 */
router.get('/:id/tasks', async (req, res) => {
  try {
    const teamId = parseInt(req.params.id);

    const result = await db.query(
      `SELECT 
        t.id,
        t.team_id,
        t.title,
        t.is_completed,
        t.created_by_id,
        u.username as created_by,
        t.created_at,
        t.updated_at
      FROM team_tasks t
      JOIN users u ON t.created_by_id = u.id
      WHERE t.team_id = $1
      ORDER BY t.created_at DESC`,
      [teamId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error('Error fetching team tasks:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * POST /api/teams/:id/tasks
 * Create a new task for a team
 * Body: { title }
 */
router.post('/:id/tasks', async (req, res) => {
  try {
    const teamId = parseInt(req.params.id);
    const userId = req.userId;
    const { title } = req.body;

    if (!title) {
      return res.status(400).json({ error: 'Title is required' });
    }

    // Verify team exists
    const teamResult = await db.query(
      'SELECT id FROM teams WHERE id = $1',
      [teamId]
    );

    if (teamResult.rows.length === 0) {
      return res.status(404).json({ error: 'Team not found' });
    }

    // Create task
    const taskResult = await db.query(
      `INSERT INTO team_tasks (team_id, title, created_by_id)
       VALUES ($1, $2, $3)
       RETURNING id, team_id, title, is_completed, created_by_id, created_at`,
      [teamId, title, userId]
    );

    const task = taskResult.rows[0];

    // Get creator username
    const userResult = await db.query('SELECT username FROM users WHERE id = $1', [userId]);
    const createdBy = userResult.rows[0]?.username || 'Unknown';

    res.status(201).json({
      ...task,
      created_by: createdBy,
    });
  } catch (error) {
    console.error('Error creating task:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * PUT /api/teams/:id/tasks/:taskId
 * Update a task (toggle completion status)
 * Body: { is_completed }
 */
router.put('/:id/tasks/:taskId', async (req, res) => {
  try {
    const teamId = parseInt(req.params.id);
    const taskId = parseInt(req.params.taskId);
    const { is_completed } = req.body;

    // Verify task belongs to team
    const taskResult = await db.query(
      'SELECT id FROM team_tasks WHERE id = $1 AND team_id = $2',
      [taskId, teamId]
    );

    if (taskResult.rows.length === 0) {
      return res.status(404).json({ error: 'Task not found' });
    }

    // Update task
    const updateResult = await db.query(
      `UPDATE team_tasks 
       SET is_completed = $1, updated_at = now()
       WHERE id = $2
       RETURNING id, team_id, title, is_completed, created_by_id, created_at, updated_at`,
      [is_completed, taskId]
    );

    res.json(updateResult.rows[0]);
  } catch (error) {
    console.error('Error updating task:', error.message);
    res.status(500).json({ error: error.message });
  }
});

/**
 * DELETE /api/teams/:id/tasks/:taskId
 * Delete a task
 */
router.delete('/:id/tasks/:taskId', async (req, res) => {
  try {
    const teamId = parseInt(req.params.id);
    const taskId = parseInt(req.params.taskId);

    // Verify task belongs to team
    const taskResult = await db.query(
      'SELECT id FROM team_tasks WHERE id = $1 AND team_id = $2',
      [taskId, teamId]
    );

    if (taskResult.rows.length === 0) {
      return res.status(404).json({ error: 'Task not found' });
    }

    // Delete task
    await db.query('DELETE FROM team_tasks WHERE id = $1', [taskId]);

    res.json({ success: true, message: 'Task deleted' });
  } catch (error) {
    console.error('Error deleting task:', error.message);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;
