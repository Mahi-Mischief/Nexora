-- SQL schema for NEXORA
CREATE TABLE IF NOT EXISTS users (
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
  address TEXT,
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS events (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT,
  date TIMESTAMP NOT NULL,
  location VARCHAR(255),
  created_by INT REFERENCES users(id),
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS announcements (
  id SERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT,
  created_by INT REFERENCES users(id),
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS messages (
  id SERIAL PRIMARY KEY,
  from_user_id INT REFERENCES users(id),
  to_user_id INT REFERENCES users(id),
  content TEXT,
  type VARCHAR(32) DEFAULT 'message',
  status VARCHAR(32) DEFAULT 'sent',
  created_at TIMESTAMP DEFAULT now()
);

CREATE TABLE IF NOT EXISTS approvals (
  id SERIAL PRIMARY KEY,
  message_id INT REFERENCES messages(id),
  student_id INT REFERENCES users(id),
  status VARCHAR(32) DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT now(),
  decided_at TIMESTAMP
);
