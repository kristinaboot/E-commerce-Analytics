from pathlib import Path
import sqlite3

import pandas as pd
from prepare_data import ROOT_DIR

# CREATE SQL DATABASE FOR THIS PROJECT

PROCESSED_DIR = ROOT_DIR / "data" / "processed"
DB_PATH = ROOT_DIR / "data" / "processed" / "ecommerce_analytics.sqlite"

CLEAN_DATA_PATH = PROCESSED_DIR / "online_retail_clean.csv"
ORDERS_DATA_PATH = PROCESSED_DIR / "orders.csv"
CUSTOMERS_RFM_PATH = PROCESSED_DIR / "customers_rfm.csv"
COHORT_RETENTION_PATH = PROCESSED_DIR / "cohort_retention.csv"
RFM_SEGMENT_SUMMARY_PATH = PROCESSED_DIR / "rfm_segment_summary.csv"


def read_csv_if_exists(path: Path) -> pd.DataFrame | None:
    if not path.exists():
        print(f"Skipped: {path.name} does not exist")
        return None

    return pd.read_csv(path)


def main() -> None:
    if not CLEAN_DATA_PATH.exists():
        raise FileNotFoundError(
            f"Clean data file not found: {CLEAN_DATA_PATH}\n"
            "Run prepare_data.py first."
        )

    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)

    tables = {
        "online_retail_clean": read_csv_if_exists(CLEAN_DATA_PATH),
        "orders": read_csv_if_exists(ORDERS_DATA_PATH),
        "customers_rfm": read_csv_if_exists(CUSTOMERS_RFM_PATH),
        "cohort_retention": read_csv_if_exists(COHORT_RETENTION_PATH),
        "rfm_segment_summary": read_csv_if_exists(RFM_SEGMENT_SUMMARY_PATH),
    }

    with sqlite3.connect(DB_PATH) as conn:
        for table_name, df in tables.items():
            if df is None:
                continue

            df.to_sql(table_name, conn, if_exists="replace", index=False)
            print(f"Saved table: {table_name} ({len(df):,} rows)")

    print()
    print(f"SQLite database created: {DB_PATH}")


if __name__ == "__main__":
    main()
