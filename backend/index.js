const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');
const dashboardRoutes = require('./src/routes/dashboard');
const productRoutes = require('./src/routes/products');
const orderRoutes = require('./src/routes/order');
const authRoutes = require('./src/routes/auth');
const reportRoutes = require('./src/routes/reports');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors()); 
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Routes
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/reports', reportRoutes);

app.get('/', (req, res) => {
  res.send('Server Retail Analytics berjalan! 🚀');
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});