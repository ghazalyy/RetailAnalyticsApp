const express = require('express');
const router = express.Router();
const { register, login } = require('../controllers/authController');
const authenticateToken = require('../middlewares/authMiddleware');

router.post('/register', register);
router.post('/login', login);

router.get('/profile', authenticateToken, (req, res) => {
  res.json({ 
    message: 'Ini adalah data profil yang diproteksi', 
    userLogged: req.user 
  });
});

module.exports = router;