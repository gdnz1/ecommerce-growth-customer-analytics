import os
import sys
import glob

if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")

import pandas as pd
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

# 1. .env dosyasındaki ortam değişkenlerini yükle
load_dotenv()

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_PORT = os.getenv("DB_PORT", "3306")
DB_USER = os.getenv("DB_USER", "admin")
DB_PASSWORD = os.getenv("DB_PASSWORD", "")
DB_NAME = os.getenv("DB_NAME", "ecommerce_analysis")

def get_engine():
    """SQLAlchemy MySQL bağlantı motorunu oluşturur."""
    connection_uri = f"mysql+pymysql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    return create_engine(connection_uri)

def run_sql_file(engine, file_path):
    """DDL SQL dosyalarını çalıştırarak tabloları oluşturur."""
    print(f"📄 SQL dosyası çalıştırılıyor: {file_path}")
    with open(file_path, "r", encoding="utf-8") as f:
        sql_commands = f.read().split(";")
        with engine.connect() as conn:
            for command in sql_commands:
                if command.strip():
                    conn.execute(text(command))
            conn.commit()

def load_data():
    engine = get_engine()
    
    # 1. Önce DDL scriptimizi çalıştırıp tabloların var olduğundan emin olalım
    run_sql_file(engine, "sql/01_schema/02_create_tables.sql")

    # 2. Yükleme sırası ve dosya-tablo eşleştirmeleri
    # DİKKAT: Foreign Key hiyerarşisine göre sıra belirlenmiştir!
    tables_config = [
        {
            "table": "customers",
            "file": "data/raw/olist_customers_dataset.csv",
            "dates": []
        },
        {
            "table": "sellers",
            "file": "data/raw/olist_sellers_dataset.csv",
            "dates": []
        },
        {
            "table": "products",
            "file": "data/raw/olist_products_dataset.csv",
            "dates": []
        },
        {
            "table": "product_category_name_translation",
            "file": "data/raw/product_category_name_translation.csv",
            "dates": []
        },
        {
            "table": "orders",
            "file": "data/raw/olist_orders_dataset.csv",
            "dates": [
                "order_purchase_timestamp",
                "order_approved_at",
                "order_delivered_carrier_date",
                "order_delivered_customer_date",
                "order_estimated_delivery_date"
            ]
        },
        {
            "table": "order_items",
            "file": "data/raw/olist_order_items_dataset.csv",
            "dates": ["shipping_limit_date"]
        },
        {
            "table": "order_payments",
            "file": "data/raw/olist_order_payments_dataset.csv",
            "dates": []
        },
        {
            "table": "order_reviews",
            "file": "data/raw/olist_order_reviews_dataset.csv",
            "dates": ["review_creation_date", "review_answer_timestamp"]
        }
    ]

    print("\n🚀 Veri yükleme işlemi başlıyor...")

    for config in tables_config:
        table_name = config["table"]
        file_path = config["file"]
        date_cols = config["dates"]

        if not os.path.exists(file_path):
            print(f"⚠️ Dosya bulunamadı: {file_path}, atlanıyor...")
            continue

        print(f"\n⏳ Yükleniyor: {table_name} ({file_path})...")
        
        # CSV dosyasını Pandas ile oku (tarih sütunlarını otomatik datetime yap)
        df = pd.read_csv(file_path, parse_dates=date_cols if date_cols else False)

        # Reviews tablosundaki olası tekrarları (duplicate review_id + order_id) temizle
        if table_name == "order_reviews":
            df = df.drop_duplicates(subset=["review_id", "order_id"])

        # MySQL'e hızlı toplu aktarım (batch insert)
        df.to_sql(
            name=table_name,
            con=engine,
            if_exists="append",
            index=False,
            chunksize=5000,
            method="multi"
        )
        print(f"✅ {table_name} tablosuna {len(df):,} satır başarıyla aktarıldı.")

    print("\n🎉 Tebrikler! Tüm veri seti MySQL veritabanına başarıyla yüklendi.")

if __name__ == "__main__":
    load_data()
