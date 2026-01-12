const db = require('./db');

async function testTeamFunctionality() {
  try {
    console.log('\n=== Testing Team Functionality ===\n');

    // Get a test user (or create one)
    let userId;
    const userResult = await db.query(
      "SELECT id FROM users WHERE username = 'testuser' LIMIT 1"
    );

    if (userResult.rows.length === 0) {
      console.log('Creating test user...');
      const createResult = await db.query(
        `INSERT INTO users (username, email, password_hash, first_name, last_name, school)
         VALUES ('testuser', 'test@example.com', 'hash', 'Test', 'User', 'Test High School')
         RETURNING id`
      );
      userId = createResult.rows[0].id;
    } else {
      userId = userResult.rows[0].id;
    }

    console.log(`Using user ID: ${userId}`);

    // Test 1: Create a team
    console.log('\n1. Creating a team...');
    const teamResult = await db.query(
      `INSERT INTO teams (name, school, event_type, event_name, member_count, created_by)
       VALUES ('Test Team', 'Test High School', 'presentation', 'Business Plan', 3, $1)
       RETURNING id, name, school, event_type, event_name, member_count, created_by, created_at`,
      [userId]
    );
    const teamId = teamResult.rows[0].id;
    console.log('Team created:', teamResult.rows[0]);

    // Test 2: Add creator as team member
    console.log('\n2. Adding creator as team member...');
    await db.query(
      'INSERT INTO team_members (team_id, user_id) VALUES ($1, $2)',
      [teamId, userId]
    );
    console.log('Creator added to team');

    // Test 3: Get teams by school
    console.log('\n3. Fetching teams by school...');
    const schoolTeams = await db.query(
      `SELECT t.id, t.name, t.school, t.event_type, t.event_name, t.member_count, t.created_by, u.username, t.created_at
       FROM teams t
       JOIN users u ON t.created_by = u.id
       WHERE t.school = $1`,
      ['Test High School']
    );
    console.log('Teams found:', schoolTeams.rows);

    // Test 4: Get user's current team
    console.log('\n4. Fetching user\'s current team...');
    const userTeam = await db.query(
      `SELECT t.id, t.name, t.school, t.event_type, t.event_name, t.member_count, t.created_by, u.username
       FROM teams t
       JOIN team_members tm ON t.id = tm.team_id
       JOIN users u ON t.created_by = u.id
       WHERE tm.user_id = $1`,
      [userId]
    );
    console.log('User team:', userTeam.rows[0] || 'None');

    // Test 5: Create another user to test joining
    console.log('\n5. Creating another user to test joining...');
    const user2Result = await db.query(
      `INSERT INTO users (username, email, password_hash, first_name, last_name, school)
       VALUES ('testuser2', 'test2@example.com', 'hash', 'Test', 'User2', 'Test High School')
       RETURNING id`,
      []
    );
    const userId2 = user2Result.rows[0].id;
    console.log(`Created user2 ID: ${userId2}`);

    // Test 6: User2 joins the team
    console.log('\n6. User2 joining the team...');
    await db.query(
      'INSERT INTO team_members (team_id, user_id) VALUES ($1, $2)',
      [teamId, userId2]
    );
    console.log('User2 added to team');

    // Test 7: Check team members
    console.log('\n7. Checking team members...');
    const members = await db.query(
      `SELECT u.id, u.username FROM team_members tm
       JOIN users u ON tm.user_id = u.id
       WHERE tm.team_id = $1`,
      [teamId]
    );
    console.log('Team members:', members.rows);

    console.log('\n=== All tests completed successfully! ===\n');
    process.exit(0);
  } catch (error) {
    console.error('Error:', error.message);
    console.error(error);
    process.exit(1);
  }
}

testTeamFunctionality();
