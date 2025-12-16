import pandas as pd
import json
import os
import numpy as np
from sqlalchemy import create_engine
import datetime

DB_USER = "root"
DB_PASS = ""
DB_HOST = "localhost"
DB_PORT = "3306"
DB_NAME = "db_retail"

DB_CONNECTION_STR = f"mysql+pymysql://{DB_USER}:{DB_PASS}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

script_dir = os.path.dirname(os.path.abspath(__file__))

try:
    csv_file = os.path.join(script_dir, 'train.csv')
    
    if not os.path.exists(csv_file):
        print(f"Error: File '{csv_file}' tidak ditemukan.")
        exit()

    df = pd.read_csv(csv_file)
    print(f"Data berhasil dimuat. Total baris: {len(df)}")
    
except Exception as e:
    print(f"Error saat membaca file: {e}")
    exit()

df.columns = df.columns.str.strip()

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

df['quantity'] = np.random.randint(1, 6, df.shape[0])
margin = np.random.uniform(0.10, 0.30, df.shape[0])
df['profit'] = df['sales'] * margin

df['orderDate'] = pd.to_datetime(df['orderDate'], dayfirst=True, errors='coerce')

invalid_dates = df['orderDate'].isna().sum()
if invalid_dates > 0:
    df = df.dropna(subset=['orderDate'])

try:
    engine = create_engine(DB_CONNECTION_STR)

    products_df = df[['productId', 'productName', 'category', 'subCategory', 'sales', 'quantity']].copy()
    products_df['price'] = products_df['sales'] / products_df['quantity']
    products_df = products_df.drop_duplicates(subset=['productId'])
    
    products_to_db = products_df[['productId', 'productName', 'category', 'subCategory', 'price']].copy()
    products_to_db.columns = ['id', 'name', 'category', 'subCategory', 'price']
    products_to_db['stock'] = 100
    
    products_to_db.to_sql('Product', engine, if_exists='append', index=False, chunksize=1000)
    print(f"Berhasil simpan {len(products_to_db)} produk.")

    sales_to_db = df[['orderId', 'orderDate', 'customerId', 'segment', 'region', 
                      'productId', 'category', 'sales', 'quantity', 'profit']].copy()
    
    sales_to_db.to_sql('Sale', engine, if_exists='append', index=False, chunksize=1000)
    print(f"Berhasil simpan {len(sales_to_db)} transaksi.")

except Exception as e:
    print(f"Error Database: {e}")
    exit()

summary_data = {
    "generated_at": str(datetime.datetime.now()),
    "kpi": {
        "total_sales": float(df['sales'].sum()),
        "total_profit": float(df['profit'].sum()),
        "total_orders": len(df)
    },
    "pie_chart_category": df.groupby('category')['sales'].sum().to_dict(),
    "line_chart_trend": df.groupby(df['orderDate'].dt.to_period("M"))['sales'].sum().to_dict()
}

summary_data["line_chart_trend"] = {str(k): v for k, v in summary_data["line_chart_trend"].items()}

output_dir = os.path.join(os.path.dirname(script_dir), 'backend')
os.makedirs(output_dir, exist_ok=True)
output_path = os.path.join(output_dir, 'dashboard_summary.json')

with open(output_path, 'w') as f:
    json.dump(summary_data, f, indent=4)

print(f"Selesai! File JSON disimpan di: {output_path}")