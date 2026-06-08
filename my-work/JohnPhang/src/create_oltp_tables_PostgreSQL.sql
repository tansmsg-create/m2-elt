-- =============================================================================
-- Olist OLTP source schema for Cloud SQL PostgreSQL
-- Purpose: create raw ecommerce source tables before loading CSV data from GCS.
-- Schema: oltp
--
-- Notes:
-- 1. Foreign key constraints are appended at the end after all tables exist.
-- 2. This schema includes ingestion lineage columns added by the Python loader:
--      created_at, updated_at, is_deleted, source_file, source_gcs_path, batch_name
-- 3. For initial loading into these pre-created tables, use append mode in pandas/db loader.
--    If pandas to_sql(if_exists='replace') is used, these DDL constraints will be dropped.
-- =============================================================================

CREATE SCHEMA IF NOT EXISTS oltp;

-- =============================================================================
-- 1. Customer master
-- Source file: olist_customers_dataset.csv
-- =============================================================================
CREATE TABLE IF NOT EXISTS oltp.olist_customers (
    customer_id              TEXT PRIMARY KEY,
    customer_unique_id       TEXT,
    customer_zip_code_prefix INTEGER,
    customer_city            TEXT,
    customer_state           TEXT,
-- lineage / audit columns
    created_at               TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at               TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_deleted               BOOLEAN DEFAULT FALSE,
    source_file              TEXT,
    source_gcs_path          TEXT,
    batch_name               TEXT
);

-- =============================================================================
-- 2. Geolocation lookup
-- Source file: olist_geolocation_dataset.csv
--
-- Note: geolocation_zip_code_prefix is not unique in the source, so no PK/FK is
-- declared here. Deduplicate this table later in Silver/dbt.
-- =============================================================================
CREATE TABLE IF NOT EXISTS oltp.olist_geolocation (
--    geolocation_id              BIGSERIAL PRIMARY KEY,
    geolocation_zip_code_prefix INTEGER,
    geolocation_lat             DOUBLE PRECISION,
    geolocation_lng             DOUBLE PRECISION,
    geolocation_city            TEXT,
    geolocation_state           TEXT,
 -- lineage / audit columns
    created_at                  TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at                  TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_deleted                  BOOLEAN DEFAULT FALSE,
    source_file                 TEXT,
    source_gcs_path             TEXT,
    batch_name                  TEXT
);

-- =============================================================================
-- 3. Product master
-- Source file: olist_products_dataset.csv
--
-- Note: keep source spelling in OLTP/Bronze. Rename lenght -> length in Silver.
-- =============================================================================
CREATE TABLE IF NOT EXISTS
  oltp.olist_products ( product_id TEXT
  PRIMARY KEY,
    product_category_name TEXT,
    product_name_lenght INTEGER,
    product_description_lenght INTEGER,
    product_photos_qty INTEGER,
    product_weight_g INTEGER,
    product_length_cm INTEGER,
    product_height_cm INTEGER,
    product_width_cm INTEGER,
    -- lineage / audit columns
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_deleted BOOLEAN DEFAULT FALSE,
    source_file TEXT,
    source_gcs_path TEXT,
    batch_name TEXT );

-- =============================================================================
-- 4. Seller master
-- Source file: olist_sellers_dataset.csv
-- =============================================================================
CREATE TABLE IF NOT EXISTS oltp.olist_sellers (
    seller_id              TEXT PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city            TEXT,
    seller_state           TEXT,
-- lineage / audit columns
    created_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at             TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_deleted             BOOLEAN DEFAULT FALSE,
    source_file            TEXT,
    source_gcs_path        TEXT,
    batch_name             TEXT
);

-- =============================================================================
-- 5. Product category translation lookup
-- Source file: product_category_name_translation.csv
-- =============================================================================
CREATE TABLE IF NOT EXISTS oltp.product_category_name_translation (
    product_category_name         TEXT PRIMARY KEY,
    product_category_name_english TEXT,
 -- lineage / audit columns
    created_at                    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at                    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_deleted                    BOOLEAN DEFAULT FALSE,
    source_file                   TEXT,
    source_gcs_path               TEXT,
    batch_name                    TEXT
);

-- =============================================================================
-- 6. Order header
-- Source file: olist_orders_dataset.csv
-- =============================================================================
CREATE TABLE IF NOT EXISTS oltp.olist_orders (
    order_id                      TEXT PRIMARY KEY,
    customer_id                   TEXT,
    order_status                  TEXT,
    order_purchase_timestamp      TIMESTAMPTZ,
    order_approved_at             TIMESTAMPTZ,
    order_delivered_carrier_date  TIMESTAMPTZ,
    order_delivered_customer_date TIMESTAMPTZ,
    order_estimated_delivery_date TIMESTAMPTZ,
 -- lineage / audit columns
    created_at                    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at                    TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_deleted                    BOOLEAN DEFAULT FALSE,
    source_file                   TEXT,
    source_gcs_path               TEXT,
    batch_name                    TEXT
);

-- =============================================================================
-- 7. Order items / order lines
-- Source file: olist_order_items_dataset.csv
--
-- Grain: one row per order_id + order_item_id.
-- =============================================================================
CREATE TABLE IF NOT EXISTS oltp.olist_order_items (
    order_id             TEXT,
    order_item_id        INTEGER,
    product_id           TEXT,
    seller_id            TEXT,
    shipping_limit_date  TIMESTAMPTZ,
    price                NUMERIC(12, 2),
    freight_value        NUMERIC(12, 2),
 -- lineage / audit columns
    created_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at           TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_deleted           BOOLEAN DEFAULT FALSE,
    source_file          TEXT,
    source_gcs_path      TEXT,
    batch_name           TEXT,

    CONSTRAINT pk_olist_order_items PRIMARY KEY (order_id, order_item_id)
);

-- =============================================================================
-- 8. Order payments
-- Source file: olist_order_payments_dataset.csv
--
-- Grain: one row per order_id + payment_sequential.
-- =============================================================================
CREATE TABLE IF NOT EXISTS oltp.olist_order_payments (
    order_id              TEXT,
    payment_sequential    INTEGER,
    payment_type          TEXT,
    payment_installments  INTEGER,
    payment_value         NUMERIC(12, 2),
-- lineage / audit columns
    created_at            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at            TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_deleted            BOOLEAN DEFAULT FALSE,
    source_file           TEXT,
    source_gcs_path       TEXT,
    batch_name            TEXT,

    CONSTRAINT pk_olist_order_payments PRIMARY KEY (order_id, payment_sequential)
);

-- =============================================================================
-- 9. Order reviews
-- Source file: olist_order_reviews_dataset.csv
--
-- Note: no primary key is declared here to avoid load failures if review_id or
-- order_id duplicates appear in the source. Enforce uniqueness/quality later in dbt.
-- =============================================================================
CREATE TABLE IF NOT EXISTS oltp.olist_order_reviews (
    review_id               TEXT,
    order_id                TEXT,
    review_score            INTEGER,
    review_comment_title    TEXT,
    review_comment_message  TEXT,
    review_creation_date    TIMESTAMPTZ,
    review_answer_timestamp TIMESTAMPTZ,
-- lineage / audit columns
    created_at              TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at              TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    is_deleted              BOOLEAN DEFAULT FALSE,
    source_file             TEXT,
    source_gcs_path         TEXT,
    batch_name              TEXT
);

-- =============================================================================
-- Helpful indexes for extraction and joins
-- =============================================================================
CREATE INDEX IF NOT EXISTS idx_olist_customers_unique_id
    ON oltp.olist_customers (customer_unique_id);

CREATE INDEX IF NOT EXISTS idx_olist_orders_customer_id
    ON oltp.olist_orders (customer_id);

CREATE INDEX IF NOT EXISTS idx_olist_orders_purchase_ts
    ON oltp.olist_orders (order_purchase_timestamp);

CREATE INDEX IF NOT EXISTS idx_olist_order_items_product_id
    ON oltp.olist_order_items (product_id);

CREATE INDEX IF NOT EXISTS idx_olist_order_items_seller_id
    ON oltp.olist_order_items (seller_id);

CREATE INDEX IF NOT EXISTS idx_olist_order_payments_order_id
    ON oltp.olist_order_payments (order_id);

CREATE INDEX IF NOT EXISTS idx_olist_order_reviews_order_id
    ON oltp.olist_order_reviews (order_id);

CREATE INDEX IF NOT EXISTS idx_olist_products_category_name
    ON oltp.olist_products (product_category_name);

CREATE INDEX IF NOT EXISTS idx_olist_geolocation_zip
    ON oltp.olist_geolocation (geolocation_zip_code_prefix);

-- =============================================================================
-- Foreign key constraints
-- Append-only section: add after all tables have been created and loaded.
--
-- If you plan to bulk load first and validate later, run the CREATE TABLE section
-- first, load the data, then run only this FK section.
-- =============================================================================

ALTER TABLE oltp.olist_orders
    ADD CONSTRAINT fk_olist_orders_customer
    FOREIGN KEY (customer_id)
    REFERENCES oltp.olist_customers (customer_id);

ALTER TABLE oltp.olist_order_items
    ADD CONSTRAINT fk_olist_order_items_order
    FOREIGN KEY (order_id)
    REFERENCES oltp.olist_orders (order_id);

ALTER TABLE oltp.olist_order_items
    ADD CONSTRAINT fk_olist_order_items_product
    FOREIGN KEY (product_id)
    REFERENCES oltp.olist_products (product_id);

ALTER TABLE oltp.olist_order_items
    ADD CONSTRAINT fk_olist_order_items_seller
    FOREIGN KEY (seller_id)
    REFERENCES oltp.olist_sellers (seller_id);

ALTER TABLE oltp.olist_order_payments
    ADD CONSTRAINT fk_olist_order_payments_order
    FOREIGN KEY (order_id)
    REFERENCES oltp.olist_orders (order_id);

ALTER TABLE oltp.olist_order_reviews
    ADD CONSTRAINT fk_olist_order_reviews_order
    FOREIGN KEY (order_id)
    REFERENCES oltp.olist_orders (order_id);

-- Optional FK, only enable after checking every non-null product_category_name
-- exists in product_category_name_translation. Some public Olist copies may have
-- categories without translations, so this is left commented for safer loading.
--
-- ALTER TABLE oltp.olist_products
--     ADD CONSTRAINT fk_olist_products_category_translation
--     FOREIGN KEY (product_category_name)
--     REFERENCES oltp.product_category_name_translation (product_category_name);
