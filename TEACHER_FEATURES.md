# Teacher Features - NEXORA

This document outlines the teacher-specific features implemented in NEXORA.

## Overview

Teachers have a completely different interface from students, with specialized tools for managing teams, events, and tracking student activities.

## Features

### 1. Team Management
**Location:** Teams tab in teacher navigation

Teachers can:
- View all teams from their school
- See team approval status (pending/approved/rejected)
- Approve or reject team creation requests
- View all team members
- Approve or reject individual join requests
- Monitor team composition and member counts

**Backend Endpoints:**
- `GET /api/teacher/teams` - List all teams
- `GET /api/teacher/teams/:id/members` - List team members
- `PUT /api/teacher/teams/:id/approve` - Approve a team
- `PUT /api/teacher/teams/:id/reject` - Reject a team
- `PUT /api/teacher/teams/:teamId/members/:memberId/approve` - Approve member
- `PUT /api/teacher/teams/:teamId/members/:memberId/reject` - Reject member

### 2. Event Management
**Location:** Calendar tab in teacher navigation

Teachers can:
- Create new events with date, time, location, and description
- Edit existing events
- Delete events
- View all events in calendar format
- Events are visible to all students

**Backend Endpoints:**
- `POST /api/events` - Create event (teachers only)
- `PUT /api/events/:id` - Update event (teachers only)
- `DELETE /api/events/:id` - Delete event (teachers only)
- `GET /api/events` - View all events (everyone)

### 3. Student Dashboard
**Location:** Students tab in teacher navigation

Teachers can:
- View all students from their school
- See total volunteering hours per student
- See activity count per student
- Click on any student to view detailed activity log

**Student Detail View:**
- View all activities with dates, hours, and descriptions
- Add new activities on behalf of students
- Download PDF log of all student activities
- Filter by activity type (volunteering, FBLA events, community service, etc.)

**Backend Endpoints:**
- `GET /api/teacher/students` - List all students with summary stats
- `GET /api/teacher/students/:id/activities` - Get student's activities
- `POST /api/teacher/students/:id/activities` - Add activity for student
- `GET /api/teacher/students/:id/pdf` - Generate PDF log

### 4. PDF Generation
Teachers can generate official FBLA volunteering hour logs for any student. The PDF includes:
- Student information (name, email, school, grade)
- Total hours summary
- Detailed list of all activities with:
  - Activity title and type
  - Date performed
  - Hours contributed
  - Description
- Official timestamp

**Format:** Professional PDF document suitable for college applications and FBLA records

## Database Schema Changes

### Teams Table
Added approval workflow:
```sql
- approval_status VARCHAR(32) DEFAULT 'pending'
- approved_by INT REFERENCES users(id)
- approved_at TIMESTAMP
```

### Team Members Table
Added approval workflow:
```sql
- approval_status VARCHAR(32) DEFAULT 'pending'
- approved_by INT REFERENCES users(id)
- approved_at TIMESTAMP
```

### Student Activities Table (New)
```sql
CREATE TABLE student_activities (
  id SERIAL PRIMARY KEY,
  student_id INT NOT NULL REFERENCES users(id),
  activity_type VARCHAR(64) NOT NULL,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  hours DECIMAL(5,2) DEFAULT 0,
  date DATE NOT NULL,
  created_at TIMESTAMP DEFAULT now()
)
```

## Frontend Implementation

### Services
- **TeacherService** (`lib/services/teacher_service.dart`): Centralized API calls for all teacher features

### Screens
- **TeacherTeamsScreen** (`lib/screens/teacher_teams_screen.dart`): Team management UI
- **TeacherStudentsScreen** (`lib/screens/teacher_students_screen.dart`): Student dashboard
- **StudentActivitiesDetailScreen**: Individual student activity detail and management
- **TeacherCalendarScreen** (`lib/screens/teacher_calendar_screen.dart`): Event creation and management

### Navigation
The home screen automatically detects teacher role and shows different bottom navigation:
- **Students:** Home | Nex | Events | Activities | Resources
- **Teachers:** Home | Nex | Calendar | Teams | Students

## Setup & Migration

### Run Database Migration
```bash
cd backend
node migrate.js
```

### Install Dependencies
```bash
cd backend
npm install  # Installs pdfkit and other dependencies
```

### Start Backend
```bash
npm start
```

## Usage Guide

### For Teachers

1. **Managing Teams:**
   - Navigate to Teams tab
   - View all pending team requests with orange status
   - Tap on a team to expand details
   - Click "Approve Team" or "Reject" buttons
   - Click "View Members" to see and approve individual join requests

2. **Creating Events:**
   - Navigate to Calendar tab
   - Tap the "+" icon in the app bar
   - Fill in event details (title, description, date, time, location)
   - Event appears on calendar for all users
   - Tap on event to edit or delete

3. **Tracking Student Activities:**
   - Navigate to Students tab
   - View list of all students with hours summary
   - Tap on a student to see detailed activities
   - Use "+" button to add new activities
   - Tap PDF icon to download official log

### For Admins

Students and teachers are distinguished by the `role` column in the `users` table:
- `role = 'student'` → Student interface
- `role = 'teacher'` → Teacher interface

Update a user to teacher:
```sql
UPDATE users SET role = 'teacher' WHERE email = 'teacher@school.com';
```

## Security

- All teacher endpoints verify the user role via JWT token
- Middleware `verifyTeacher` ensures only teachers can access teacher routes
- Teachers can only manage teams/students from their own school
- PDF downloads require valid authentication token

## Testing

To test teacher features:
1. Create a teacher account or update an existing user's role to 'teacher'
2. Log in with the teacher account
3. Navigate through Teams, Calendar, and Students tabs
4. Create a student account and log some activities (or add via teacher interface)
5. Test PDF generation and team approval workflows

## Future Enhancements

Potential additions:
- Bulk approve/reject for teams and members
- Email notifications when teams are approved/rejected
- Export student data to CSV/Excel
- Activity templates for quick entry
- Statistical reports and charts
- Customizable PDF branding
