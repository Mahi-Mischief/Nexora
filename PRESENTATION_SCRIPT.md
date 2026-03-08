# NEXORA - App Presentation Script

## Introduction (1-2 minutes)
"Hello everyone! Today I'm excited to present **NEXORA**, a comprehensive FBLA event management and student engagement platform. NEXORA stands for 'Next-Era Organization for Resources and Activities,' and it's designed to streamline how teachers and students interact with FBLA events, volunteer opportunities, and team management."

---

## App Overview & Features (2-3 minutes)

### For Students:
- **AI Chatbot (Nex)**: Get instant answers about FBLA events, competitions, and recommendations
- **Event Calendar**: View all FBLA events and volunteering opportunities
- **Team Management**: Join teams, track tasks, and collaborate with teammates
- **Activity Logging**: Log volunteer hours and track your contributions
- **Direct Messaging**: Communicate with teachers and peers
- **News & Announcements**: Stay updated with the latest FBLA news

### For Teachers:
- **Event Management**: Create and manage both FBLA events and volunteering opportunities
- **Team Oversight**: View all registered teams with approval statuses
- **Student Approvals**: Approve or reject team join requests
- **Student Management**: Track all students and their activities
- **Announcements**: Post important updates for all students

---

## Technical Architecture - The Coding Part (3-4 minutes)

### Frontend: Flutter Framework
"The frontend is built with **Flutter**, Google's cross-platform framework. This means NEXORA runs on web, iOS, and Android from a single codebase."

#### **State Management with Riverpod**
```dart
// Example: AuthProvider manages user authentication state
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>
```
- Riverpod provides reactive state management
- When user logs in/out, the entire UI updates automatically
- Clean separation between UI and business logic

#### **Key Components & Modules**

**1. Screens (UI Layer) - 20+ screens organized by role:**
- `home_screen.dart` - Main navigation hub with role-based tabs
- `ai_chat_screen.dart` - Nex chatbot with staged responses
- `teacher_events_screen.dart` - Comprehensive event management dashboard
- `calendar_screen.dart` - Event calendar with volunteering section
- `team_questionnaire_screen.dart` - Team creation wizard

**2. Services (Business Logic Layer) - 12 service modules:**
```dart
// API Service - Centralized HTTP client
class Api {
  static String get baseUrl => 'http://localhost:3000';
  static Future<http.Response> post(String path, {Map? body, String? token})
  static Future<http.Response> get(String path, {String? token})
}

// Team Service - Manages all team operations
class TeamService {
  static Future<List<Map<String, dynamic>>> getMyTeam(String token)
  static Future<Map<String, dynamic>> createTeam(data, token)
  static Future<void> addTask(teamId, title, token)
}

// Event Service - Handles events and volunteering
class EventService {
  static Future<List<Map<String, dynamic>>> fetchEvents({String? eventType})
  // eventType can be 'general' for FBLA events or 'volunteering'
}
```

**3. Authentication Flow:**
```dart
// Login → Token Storage → Role-Based Navigation
AuthService.login() → SharedPreferences.setString('token')
                    → Navigate to HomeScreen with role tabs
```

**4. Theme Management:**
```dart
// Custom dark theme throughout the app
ThemeData darkTheme = ThemeData(
  primaryColor: Color(0xFF0E1A2B),  // Deep navy blue
  scaffoldBackgroundColor: Color(0xFF0E1A2B),
  cardTheme: CardTheme(color: Color(0xFF1A2332))
)
```

---

## Backend Architecture (3-4 minutes)

### Tech Stack: Node.js + Express + PostgreSQL

#### **RESTful API Routes (8 modules):**

**1. Authentication (`routes/auth.js`)**
```javascript
POST /auth/signup    // Register new user
POST /auth/login     // Login with JWT token
POST /auth/logout    // Logout user
GET  /auth/me        // Get current user info
```

**2. Teams (`routes/teams.js`)**
```javascript
POST /teams           // Create new team
GET  /teams/my-team   // Get user's team
POST /teams/:id/join  // Join a team
PUT  /teams/:id/tasks/:taskId/toggle  // Toggle task completion
```

**3. Events (`routes/events.js`)**
```javascript
GET  /events?event_type=general      // Get FBLA events
GET  /events?event_type=volunteering // Get volunteer opportunities
POST /events                         // Create new event
PUT  /events/:id                     // Update event
DELETE /events/:id                   // Delete event
```

**4. Teacher Routes (`routes/teacher.js`)**
```javascript
GET  /teacher/teams      // Get all teams for approval
GET  /teacher/students   // Get all students
PUT  /teacher/teams/:id  // Approve/reject team
```

#### **Middleware: JWT Authentication**
```javascript
// middleware/auth.js
const jwt = require('jsonwebtoken');

function authenticateToken(req, res, next) {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.sendStatus(401);
  
  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
}
```

---

## Database Design - The SQL Part (4-5 minutes)

### PostgreSQL Schema with 9 Related Tables

#### **1. Users Table - The Foundation**
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  username VARCHAR(64) UNIQUE NOT NULL,
  email VARCHAR(128) UNIQUE NOT NULL,
  password_hash VARCHAR(256) NOT NULL,
  role VARCHAR(32) DEFAULT 'student',
  first_name VARCHAR(64),
  last_name VARCHAR(64),
  school VARCHAR(128),
  age INT,
  grade VARCHAR(32),
  created_at TIMESTAMP DEFAULT now()
);
```
- **SERIAL PRIMARY KEY**: Auto-incrementing ID
- **UNIQUE constraints**: Prevent duplicate usernames/emails
- **role**: Determines app permissions (student/teacher)

#### **2. Events Table - Dual Purpose**
```sql
CREATE TABLE events (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  date TIMESTAMP NOT NULL,
  location VARCHAR(255),
  event_type VARCHAR(64) DEFAULT 'general',  -- 'general' or 'volunteering'
  created_by INT REFERENCES users(id),
  created_at TIMESTAMP DEFAULT now()
);
```
- **event_type**: Distinguishes FBLA events from volunteering opportunities
- **Foreign Key**: created_by links to users table

#### **3. Teams Table - Event Registration**
```sql
CREATE TABLE teams (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  school VARCHAR(128) NOT NULL,
  event_type VARCHAR(64) NOT NULL,
  event_name VARCHAR(255) NOT NULL,
  member_count INT NOT NULL,
  created_by INT NOT NULL REFERENCES users(id),
  approval_status VARCHAR(32) DEFAULT 'pending',
  approved_by INT REFERENCES users(id),
  approved_at TIMESTAMP,
  UNIQUE(created_by)  -- One team per user
);
```

#### **4. Team Members Table - Many-to-Many Relationship**
```sql
CREATE TABLE team_members (
  id SERIAL PRIMARY KEY,
  team_id INT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  user_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  approval_status VARCHAR(32) DEFAULT 'pending',
  UNIQUE(team_id, user_id)  -- Prevent duplicate memberships
);
```
- **ON DELETE CASCADE**: When team is deleted, all members are removed
- **Composite uniqueness**: Same user can't join same team twice

#### **5. Team Tasks Table - Task Management**
```sql
CREATE TABLE team_tasks (
  id SERIAL PRIMARY KEY,
  team_id INT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
  title VARCHAR(255) NOT NULL,
  is_completed BOOLEAN DEFAULT false,
  created_by_id INT NOT NULL REFERENCES users(id),
  created_at TIMESTAMP DEFAULT now(),
  updated_at TIMESTAMP DEFAULT now()
);
```

#### **6. Student Activities Table - Hour Tracking**
```sql
CREATE TABLE student_activities (
  id SERIAL PRIMARY KEY,
  student_id INT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity_type VARCHAR(64) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  hours DECIMAL(5,2) DEFAULT 0,  -- Supports fractional hours
  date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT now()
);
```

#### **7. Messages & Approvals - Communication System**
```sql
CREATE TABLE messages (
  id SERIAL PRIMARY KEY,
  from_user_id INT REFERENCES users(id),
  to_user_id INT REFERENCES users(id),
  content TEXT,
  type VARCHAR(32) DEFAULT 'message',
  status VARCHAR(32) DEFAULT 'sent'
);

CREATE TABLE approvals (
  id SERIAL PRIMARY KEY,
  message_id INT REFERENCES messages(id),
  student_id INT REFERENCES users(id),
  status VARCHAR(32) DEFAULT 'pending',
  decided_at TIMESTAMP
);
```

### **Database Relationships:**
```
users (1) ────< (many) teams           // One user creates one team
teams (1) ────< (many) team_members    // One team has many members
teams (1) ────< (many) team_tasks      // One team has many tasks
users (1) ────< (many) student_activities  // One student logs many activities
users (1) ────< (many) messages        // One user sends/receives many messages
```

### **Key SQL Concepts Used:**
1. **Primary Keys**: `SERIAL PRIMARY KEY` for auto-incrementing IDs
2. **Foreign Keys**: `REFERENCES` for maintaining referential integrity
3. **Cascading Deletes**: `ON DELETE CASCADE` to clean up related data
4. **Unique Constraints**: Prevent duplicates at database level
5. **Default Values**: `DEFAULT 'pending'` for status fields
6. **Timestamps**: Automatic tracking with `DEFAULT now()`

---

## Advanced Features (2-3 minutes)

### 1. AI Chatbot with Staged Responses
```dart
// Pre-configured responses for common questions
String _mockResponse(String query) {
  if (query.toLowerCase().contains('fbla')) {
    return '''### FBLA (Future Business Leaders of America)
---
FBLA is a student organization that helps high school students...
* Leadership development
* Business skills
* Networking opportunities''';
  }
}
```

### 2. Real-time Event Filtering
```dart
// Students see events separated by type
EventService.fetchEvents(eventType: 'general')       // FBLA Events
EventService.fetchEvents(eventType: 'volunteering')  // Volunteer Ops
```

### 3. Role-Based Navigation
```dart
// Different tabs for students vs teachers
final studentTabs = ['Home', 'Nex', 'Events', 'Calendar', 'Activities'];
final teacherTabs = ['Home', 'Nex', 'Events', 'Calendar', 'Approvals', 'Students'];
```

### 4. Database Migration System
```javascript
// add_event_type.js - Adds event_type column safely
await pool.query(`
  ALTER TABLE events 
  ADD COLUMN IF NOT EXISTS event_type VARCHAR(64) DEFAULT 'general'
`);
```

---

## Security & Best Practices (1-2 minutes)

### 1. **JWT Authentication**
- Tokens stored in SharedPreferences (mobile) or localStorage (web)
- All API requests include `Authorization: Bearer <token>`
- Token verification on backend before processing requests

### 2. **Password Security**
```javascript
const bcrypt = require('bcrypt');
const hashedPassword = await bcrypt.hash(password, 10);
```

### 3. **SQL Injection Prevention**
```javascript
// Using parameterized queries
const result = await pool.query(
  'SELECT * FROM users WHERE email = $1',
  [email]
);
```

### 4. **Input Validation**
- Frontend: Flutter form validators
- Backend: Express middleware validation

---

## Deployment & Performance (1 minute)

### Current Setup:
- **Frontend**: Flutter Web (can deploy to Firebase Hosting, Netlify, Vercel)
- **Backend**: Node.js on local server (port 3000)
- **Database**: PostgreSQL (local instance)

### Production Considerations:
- Backend → Deploy to Heroku, Railway, or AWS
- Database → Managed PostgreSQL (Heroku Postgres, AWS RDS)
- Environment Variables → `.env` for sensitive configs
- CORS configured for cross-origin requests

---

## Demo Walkthrough (3-4 minutes)

### Student Flow:
1. **Login** → JWT token received
2. **Chat with Nex** → Ask "What events should I go for?"
3. **View Events** → See FBLA events and volunteering opportunities
4. **Create Team** → Fill questionnaire for event
5. **Add Tasks** → Team collaboration
6. **Log Activities** → Track volunteer hours

### Teacher Flow:
1. **Login** → Access teacher dashboard
2. **Events Page** → View all teams with status (approved/pending/rejected)
3. **Create Volunteering** → Add new opportunity
4. **Approvals** → Review and approve team join requests
5. **Student Management** → View all students and their info

---

## Technical Achievements & Challenges (2 minutes)

### What We Accomplished:
✅ **Full-Stack Development**: Complete frontend + backend + database
✅ **Cross-Platform**: Single codebase runs on web, iOS, Android
✅ **Relational Database**: 9 tables with complex relationships
✅ **RESTful API**: 8 route modules with JWT authentication
✅ **Role-Based Access**: Different features for students vs teachers
✅ **Real-Time Updates**: Hot reload, state management
✅ **Custom Theming**: Consistent dark theme across all screens

### Challenges Overcome:
- **Asset Loading**: Hot reload doesn't refresh assets → Full restart required
- **Database Migrations**: Adding columns without breaking existing data
- **State Management**: Keeping UI in sync with backend data
- **CORS Issues**: Configuring backend for web requests
- **Role Segregation**: Ensuring students can't access teacher-only features

---

## Future Enhancements (1 minute)

### Planned Features:
- 📱 **Push Notifications** for event reminders
- 📊 **Analytics Dashboard** for teachers to track student engagement
- 🏆 **Leaderboard** for volunteer hours and event participation
- 📁 **File Uploads** for event materials and resources
- 💬 **Real-Time Chat** using WebSockets
- 🔍 **Advanced Search** with filters and tags
- 🌐 **Multi-Language Support** for accessibility

---

## Conclusion (1 minute)

"NEXORA demonstrates a complete understanding of:
- **Modern app development** with Flutter and Dart
- **Backend architecture** with Node.js and Express
- **Database design** with PostgreSQL and relational modeling
- **API development** with RESTful principles
- **Authentication** with JWT tokens
- **State management** with Riverpod
- **Full software development lifecycle** from planning to deployment

This project showcases real-world skills in building scalable, maintainable, and user-friendly applications. Thank you for your time, and I'm happy to answer any questions!"

---

## Q&A Preparation

**Possible Questions:**

**Q: Why Flutter instead of React Native?**
A: Flutter offers better performance with native compilation, a rich widget library, and excellent hot reload for rapid development.

**Q: Why PostgreSQL instead of MongoDB?**
A: PostgreSQL provides strong relational integrity with foreign keys, ACID compliance, and complex query support—essential for our team/event relationships.

**Q: How does authentication work?**
A: We use JWT tokens. Upon login, the server generates a signed token containing user info. The client stores it and includes it in all subsequent requests. The server verifies the signature before processing.

**Q: Can this scale to thousands of users?**
A: Yes! The architecture is designed for scalability:
- Stateless API for horizontal scaling
- Database indexing on foreign keys
- Connection pooling for database efficiency
- Can add caching layer (Redis) for frequently accessed data

**Q: What about data privacy?**
A: Passwords are hashed with bcrypt, never stored in plain text. JWTs expire. SQL injection is prevented with parameterized queries. Role-based access ensures students can't access teacher data.

---

**Total Presentation Time: 15-20 minutes**
