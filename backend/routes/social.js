const express = require('express');
const router = express.Router();
// For demo purposes we provide a mocked social feed. In production you'd integrate with Instagram/X APIs.

router.get('/feed', async (req, res) => {
  // Return mocked posts
  res.json({
    posts: [
      { id: 'p1', platform: 'instagram', text: 'Chapter meeting tonight at 6pm!', time: new Date().toISOString() },
      { id: 'p2', platform: 'x', text: 'Congrats to our competition winners!', time: new Date().toISOString() },
    ],
  });
});

module.exports = router;
