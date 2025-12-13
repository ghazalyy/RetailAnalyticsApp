import pandas as pd
import json
import os
import numpy as np
from sqlalchemy import create_engine
import datetime

# ==========================================
# KONFIGURASI DATABASE (MYSQL)
# ==========================================
DB_USER = "root"
DB_PASS = ""       
DB_HOST = "localhost"
DB_PORT = "3306"
DB_NAME = "db_retail" 

# String koneksi MySQL
DB_CONNECTION_STR = f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# ==========================================
# 1. READ DATA (Dari File Lokal)
# ==========================================
print("--- [1/4] Membaca File CSV ---")
try:
    csv_file = 'train.csv'
    
    if not os.path.exists(csv_file):
        print(f"Error: File '{csv_file}' tidak ditemukan di folder ini.")
        print("Pastikan file csv hasil download diletakkan satu folder dengan script.")
        exit()

    df = pd.read_csv(csv_file)
    print(f"Data berhasil dimuat. Total baris: {len(df)}")
    
except Exception as e:
    print(f"Error saat membaca file: {e}")
    exit()

# ==========================================
# 2. TRANSFORM & DATA SYNTHESIS
# ==========================================
print("\n--- [2/4] Transformasi & Pembuatan Data Dummy ---")

# 1. Bersihkan spasi di nama kolom (jaga-jaga)
df.columns = df.columns.str.strip()

# 2. Rename kolom sesuai Schema Database
# Mapping hanya untuk kolom yang BENAR-BENAR ADA di file train.csv Anda
column_mapping = {
    'Order ID': 'orderId',
    'Order Date': 'orderDate',
    'Customer ID': 'customerId',
    'Segment': 'segment',
    'Region': 'region',
    'Product ID': 'productId',
    'Product Name': 'productName',
    'Category': 'category',
    'Sub-Category': 'subCategory',
    'Sales': 'sales'
}

df = df.rename(columns=column_mapping)

# 3. GENERATE DATA HILANG (Karena train.csv tidak punya Quantity & Profit)
print("   -> Membuat data dummy 'Quantity' (Random 1-5)...")
# Kita buat random quantity antara 1 sampai 5
df['quantity'] = np.random.randint(1, 6, df.shape[0])

print("   -> Membuat data dummy 'Profit' (Margin acak 10-30%)...")
# Profit = Sales * (10% sampai 30%)
# Ini biar datanya terlihat masuk akal di grafik
margin = np.random.uniform(0.10, 0.30, df.shape[0]) 
df['profit'] = df['sales'] * margin

# 4. Parsing Tanggal (PENTING: Format file Anda dd/mm/yyyy)
print("   -> Parsing tanggal...")
df['orderDate'] = pd.to_datetime(df['orderDate'], dayfirst=True, errors='coerce')

# Cek jika ada tanggal yang gagal baca
invalid_dates = df['orderDate'].isna().sum()
if invalid_dates > 0:
    print(f"   [Warning] Ada {invalid_dates} baris dengan format tanggal salah, akan dihapus.")
    df = df.dropna(subset=['orderDate'])

# ==========================================
# 3. LOAD TO DATABASE
# ==========================================
print("\n--- [3/4] Upload ke Database MySQL ---")

try:
    engine = create_engine(DB_CONNECTION_STR)

    # --- A. Tabel Product ---
    print("   -> Insert Tabel Product...")
    # Siapkan dataframe khusus produk
    products_df = df[['productId', 'productName', 'category', 'subCategory', 'sales', 'quantity']].copy()
    
    # Hitung harga satuan (Price = Sales / Quantity)
    products_df['price'] = products_df['sales'] / products_df['quantity']
    
    # Ambil 1 data unik per Product ID
    products_df = products_df.drop_duplicates(subset=['productId'])
    
    # Format kolom sesuai tabel Product di Prisma
    products_to_db = products_df[['productId', 'productName', 'category', 'subCategory', 'price']].copy()
    products_to_db.columns = ['id', 'name', 'category', 'subCategory', 'price']
    products_to_db['stock'] = 100 # Default stock
    
    # Masukkan ke DB
    products_to_db.to_sql('Product', engine, if_exists='append', index=False, chunksize=1000)
    print(f"      Berhasil simpan {len(products_to_db)} produk.")

    # --- B. Tabel Sale ---
    print("   -> Insert Tabel Sale...")
    sales_to_db = df[['orderId', 'orderDate', 'customerId', 'segment', 'region', 
                      'productId', 'category', 'sales', 'quantity', 'profit']].copy()
    
    sales_to_db.to_sql('Sale', engine, if_exists='append', index=False, chunksize=1000)
    print(f"      Berhasil simpan {len(sales_to_db)} transaksi.")

except Exception as e:
    print(f"\n[ERROR DATABASE]: {e}")
    if "1062" in str(e):
        print("Penyebab: Data duplikat (Duplicate Entry). Mungkin data sudah masuk sebelumnya.")
    else:
        print("Tips: Pastikan XAMPP nyala dan 'npx prisma db push' sudah dijalankan.")
    exit()

# ==========================================
# 4. JSON SUMMARY
# ==========================================
print("\n--- [4/4] Generate Dashboard Summary JSON ---")

summary_data = {
    "generated_at": str(datetime.datetime.now()),
    "kpi": {
        "total_sales": float(df['sales'].sum()),
        "total_profit": float(df['profit'].sum()),
        "total_orders": len(df)
    },
    "pie_chart_category": df.groupby('category')['sales'].sum().to_dict(),
    # Group by Bulan (YYYY-MM)
    "line_chart_trend": df.groupby(df['orderDate'].dt.to_period("M"))['sales'].sum().to_dict()
}

# Convert key periode ke string biar bisa jadi JSON
summary_data["line_chart_trend"] = {str(k): v for k, v in summary_data["line_chart_trend"].items()}

with open('dashboard_summary.json', 'w') as f:
    json.dump(summary_data, f, indent=4)

print("Selesai! File 'dashboard_summary.json' siap dipakai.")