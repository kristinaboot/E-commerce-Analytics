from pathlib import Path

import pandas as pd


ROOT_DIR = Path(__file__).resolve().parents[0]
RAW_DATA_PATH = ROOT_DIR / "data" / "raw" / "Online Retail.xlsx"
PROCESSED_DIR = ROOT_DIR / "data" / "processed"
CLEAN_DATA_PATH = PROCESSED_DIR / "online_retail_clean.csv"
ORDERS_DATA_PATH = PROCESSED_DIR / "orders.csv"


def normalize_columns(df: pd.DataFrame) -> pd.DataFrame:
    """
    Converts column names to snake_case
    """
    rename_map = {
        "InvoiceNo": "invoice_no",
        "StockCode": "stock_code",
        "Description": "description",
        "Quantity": "quantity",
        "InvoiceDate": "invoice_date",
        "UnitPrice": "unit_price",
        "CustomerID": "customer_id",
        "Country": "country",
    }

    return df.rename(columns=rename_map)


def load_raw_data(path: Path) -> pd.DataFrame:
    """
    Loads the original Excel
    """
    if not path.exists():
        raise FileNotFoundError(
            f"Файл не найден: {path}\n"
            f"Скачай Online Retail.xlsx и положи его в data/raw/"
        )

    df = pd.read_excel(path)
    df = normalize_columns(df)
    return df


def clean_data(df: pd.DataFrame) -> pd.DataFrame:
    """
    Clears data for sales analytics.
    - Cancelled orders begin with C in invoice_no;
    - Rows without a customer_id cannot be used for customer/RFM/retention analytics;
    - quantity <= 0 and unit_price <= 0 are excluded from primary sales analytics.
    """
    df = df.copy()

    df["invoice_no"] = df["invoice_no"].astype(str)
    df["stock_code"] = df["stock_code"].astype(str)
    df["description"] = df["description"].astype("string")
    df["country"] = df["country"].astype("string")
    df["invoice_date"] = pd.to_datetime(df["invoice_date"])

    df["is_cancelled"] = df["invoice_no"].str.startswith("C")

    # base revenue on line
    df["line_revenue"] = df["quantity"] * df["unit_price"]

    # main dataset for sales analytic О
    # clean canceling, zero and unknown
    clean_df = df[
        (~df["is_cancelled"])
        & (df["quantity"] > 0)
        & (df["unit_price"] > 0)
        & (df["customer_id"].notna())
    ].copy()

    clean_df["customer_id"] = clean_df["customer_id"].astype(int).astype(str)

    clean_df["invoice_date"] = pd.to_datetime(clean_df["invoice_date"])
    clean_df["invoice_day"] = clean_df["invoice_date"].dt.date
    clean_df["invoice_month"] = clean_df["invoice_date"].dt.to_period("M").astype(str)
    clean_df["invoice_year"] = clean_df["invoice_date"].dt.year
    clean_df["invoice_hour"] = clean_df["invoice_date"].dt.hour
    clean_df["day_of_week"] = clean_df["invoice_date"].dt.day_name()

    clean_df["line_revenue"] = clean_df["quantity"] * clean_df["unit_price"]

    return clean_df


def build_orders_table(df: pd.DataFrame) -> pd.DataFrame:
    """
    create table orders on level invoice_no
    """
    orders = (
        df.groupby("invoice_no", as_index=False)
        .agg(
            customer_id=("customer_id", "first"),
            country=("country", "first"),
            invoice_date=("invoice_date", "min"),
            invoice_month=("invoice_month", "first"),
            total_quantity=("quantity", "sum"),
            order_revenue=("line_revenue", "sum"),
            unique_products=("stock_code", "nunique"),
        )
    )

    return orders


def print_basic_report(raw_df: pd.DataFrame, clean_df: pd.DataFrame, orders_df: pd.DataFrame) -> None:
    """
    make base report after cleaning
    """
    print("=== DATA QUALITY REPORT ===")
    print(f"Raw rows:             {len(raw_df):,}")
    print(f"Clean rows:           {len(clean_df):,}")
    print(f"Removed rows:         {len(raw_df) - len(clean_df):,}")
    print()
    print(f"Orders:               {orders_df['invoice_no'].nunique():,}")
    print(f"Customers:            {clean_df['customer_id'].nunique():,}")
    print(f"Products:             {clean_df['stock_code'].nunique():,}")
    print(f"Countries:            {clean_df['country'].nunique():,}")
    print(f"Total revenue:        £{clean_df['line_revenue'].sum():,.2f}")
    print(f"Date range:           {clean_df['invoice_date'].min()} — {clean_df['invoice_date'].max()}")


def main() -> None:
    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

    raw_df = load_raw_data(RAW_DATA_PATH)
    clean_df = clean_data(raw_df)
    orders_df = build_orders_table(clean_df)

    clean_df.to_csv(CLEAN_DATA_PATH, index=False)
    orders_df.to_csv(ORDERS_DATA_PATH, index=False)

    print_basic_report(raw_df, clean_df, orders_df)

    print()
    print(f"Saved clean data to: {CLEAN_DATA_PATH}")
    print(f"Saved orders data to: {ORDERS_DATA_PATH}")


if __name__ == "__main__":
    main()