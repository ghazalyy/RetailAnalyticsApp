import pandas as pd
import os
import numpy as np
from sqlalchemy import create_engine, text
from decimal import Decimal
import datetime

DB_USER = "rUqEgqmF6CJ4tGd.root"
DB_PASS = "QcclYQGkGaT66GwG"
DB_HOST = "gateway01.ap-southeast-1.prod.aws.tidbcloud.com"
DB_PORT = "4000"
DB_NAME = "test"

DB_URL = (
    f"mysql+pymysql://{DB_USER}:{DB_PASS}"
    f"@{DB_HOST}:{DB_PORT}/{DB_NAME}?ssl_verify_cert=true"
)

engine = create_engine(DB_URL)
with engine.connect() as conn:
    print("✅ Connected to TiDB Cloud")

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CSV_PATH = os.path.join(BASE_DIR, "train.csv")

df = pd.read_csv(CSV_PATH)
df.columns = df.columns.str.strip()

df = df.rename(columns={
    "Order ID": "orderId",
    "Order Date": "orderDate",
    "Customer ID": "customerId",
    "Segment": "segment",
    "Region": "region",
    "Product ID": "productId",
    "Product Name": "productName",
    "Category": "category",
    "Sub-Category": "subCategory",
    "Sales": "sales"
})

df["quantity"] = np.random.randint(1, 6, len(df))
df["profit"] = df["sales"] * np.random.uniform(0.1, 0.3, len(df))
df["orderDate"] = pd.to_datetime(df["orderDate"], errors="coerce")
df = df.dropna(subset=["orderDate"])

engine = create_engine(DB_URL)

with engine.begin() as conn:

    products = df[[
        "productId",
        "productName",
        "category",
        "subCategory",
        "sales",
        "quantity"
    ]].copy()

    products["price"] = products["sales"] / products["quantity"]
    products = products.drop_duplicates("productId")

    for _, p in products.iterrows():
        conn.execute(text("""
            INSERT INTO Product (id, name, category, subCategory, price, stock, image)
            VALUES (:id, :name, :category, :subCategory, :price, 100, '')
            ON DUPLICATE KEY UPDATE
              price = VALUES(price)
        """), {
            "id": str(p["productId"]),
            "name": p["productName"],
            "category": p["category"],
            "subCategory": p["subCategory"],
            "price": Decimal(str(round(p["price"], 2)))
        })

    for _, s in df.iterrows():
        conn.execute(text("""
            INSERT INTO Sale
            (orderId, orderDate, customerId, segment, region,
             productId, category, sales, quantity, profit)
            VALUES
            (:orderId, :orderDate, :customerId, :segment, :region,
             :productId, :category, :sales, :quantity, :profit)
        """), {
            "orderId": str(s["orderId"]),
            "orderDate": s["orderDate"].to_pydatetime(),
            "customerId": str(s["customerId"]),
            "segment": s["segment"],
            "region": s["region"],
            "productId": str(s["productId"]),
            "category": s["category"],
            "sales": Decimal(str(round(s["sales"], 2))),
            "quantity": int(s["quantity"]),
            "profit": Decimal(str(round(s["profit"], 2)))
        })

print("✅ ETL selesai — data sesuai schema Prisma")
