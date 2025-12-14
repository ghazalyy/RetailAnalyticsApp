🛒 Retail Analytics & POS App
Aplikasi Fullstack Retail Management yang menggabungkan fitur Point of Sales (Kasir) untuk operasional sehari-hari dan Business Intelligence (BI) Dashboard untuk analisis performa bisnis.

Proyek ini dibangun untuk mendemonstrasikan integrasi antara Data Science (ETL/Analytics), Backend API, dan Mobile Frontend.

🌟 Fitur Utama
📱 Frontend (Flutter)
Role-Based Access Control (RBAC):

Admin: Akses penuh ke Dashboard Analitik & Manajemen Produk.

Staff: Akses terbatas hanya ke Katalog Produk & Transaksi (Kasir).

BI Dashboard: Visualisasi data real-time termasuk Total Sales, Profit, Tren Penjualan (Line Chart), dan Kategori Terlaris (Pie Chart).

Katalog Produk: List produk dengan Infinite Scroll (Pagination), Pencarian (Search), dan Detail Produk.

Transaksi: Fitur "Beli Langsung" yang terintegrasi ke database.

UI Modern: Mendukung Dark Mode & Light Mode.

🔙 Backend (Express.js & MySQL)
RESTful API: Endpoint untuk Auth, Products, Dashboard, dan Orders.

Database ORM: Menggunakan Prisma untuk manajemen skema dan query database yang aman.

Authentication: Sistem Login/Register aman dengan password hashing (bcrypt).

📊 Data Pipeline (Python ETL)
Automated ETL: Script Python untuk men-download dataset (Kaggle), membersihkan data (cleaning), melakukan data synthesis (stok/profit), dan memuatnya ke MySQL.

Pre-calculated Analytics: Men-generate ringkasan JSON agar Dashboard loading instan tanpa query berat.

🛠️ Tech Stack
Mobile: Flutter, Provider, Fl_Chart, Google Fonts.

Backend: Node.js, Express.js, Prisma ORM.

Database: MySQL.

Data Science: Python, Pandas, SQLAlchemy.

🚀 Panduan Instalasi & Menjalankan
Ikuti langkah-langkah ini secara berurutan agar aplikasi berjalan lancar.

Prasyarat
Node.js & NPM

Python 3.x

Flutter SDK

MySQL (via XAMPP/Laragon/Docker)

1. Setup Database & Backend
Nyalakan MySQL. Buat database kosong bernama db_retail.

Masuk ke folder backend/root, buat file .env:

```Bash
DATABASE_URL="mysql://root:@localhost:3306/db_retail"
PORT=3000
```

Install dependensi dan setup database:

```Bash
npm install
npx prisma db push
```

Jalankan Seeding (Membuat akun Admin & Staff otomatis):

```Bash
npx prisma db seed
```

Jalankan Server:

```Bash
npm run dev
```

(Pastikan terminal menampilkan: Server running on http://localhost:3000)

2. Setup Data (ETL Python)
Agar dashboard tidak kosong, kita perlu memuat data penjualan historis.

Pastikan file train.csv (Dataset Superstore) ada di folder yang sama dengan script python.

Install library python:

```Bash
pip install pandas sqlalchemy pymysql
```

Jalankan script ETL:

```Bash
python etl_pipeline.py
```

(Tunggu hingga proses insert ke MySQL selesai dan file dashboard_summary.json terbentuk).

3. Setup Frontend (Flutter)
Masuk ke folder project flutter:

```Bash
cd retail_app
```

Install library:
```Bash

flutter pub get
```

PENTING: Konfigurasi IP Address

Buka lib/services/api_service.dart.

Jika pakai Emulator Android: Gunakan 10.0.2.2.

Jika pakai HP Fisik: Ganti dengan IP Laptop (misal 192.168.1.x).

Jika pakai Chrome: Gunakan localhost.

Jalankan aplikasi:

```bash

flutter run
```