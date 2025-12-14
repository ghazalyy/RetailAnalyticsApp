const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
const dashboardRoutes = require('./src/routes/dashboard');
const productRoutes = require('./src/routes/products');
const orderRoutes = require('./src/routes/order');
const authRoutes = require('./src/routes/auth');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors()); 
app.use(express.json());

// Routes
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/auth', authRoutes);

app.get('/', (req, res) => {
  res.send('Server Retail Analytics berjalan! 🚀');
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});