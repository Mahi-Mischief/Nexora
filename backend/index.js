const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const authRoutes = require('./routes/auth');
const usersRoutes = require('./routes/users');
const eventsRoutes = require('./routes/events');
const announcementsRoutes = require('./routes/announcements');
const messagesRoutes = require('./routes/messages');
const approvalsRoutes = require('./routes/approvals');
const socialRoutes = require('./routes/social');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan('dev'));

app.get('/', (req, res) => res.json({ status: 'ok', now: new Date() }));

app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/events', eventsRoutes);
app.use('/api/announcements', announcementsRoutes);
app.use('/api/messages', messagesRoutes);
app.use('/api/approvals', approvalsRoutes);
app.use('/api/social', socialRoutes);

app.listen(PORT, () => console.log(`NEXORA backend listening on ${PORT}`));
