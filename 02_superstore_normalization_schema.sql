-- POSTGRESQL_DB_SCHEME_NORMALIZED
CREATE TABLE IF NOT EXISTS calendar (
    date_id INT PRIMARY KEY,
    full_date DATE NOT NULL UNIQUE, 
    date_year SMALLINT NOT NULL,
    date_month SMALLINT NOT NULL, 
    date_day SMALLINT NOT NULL,
    month_year TEXT NOT NULL,
    weekday TEXT NOT NULL,
    week_of_year SMALLINT NOT NULL,
    quarter SMALLINT NOT NULL,
    is_holiday BOOL NOT NULL DEFAULT FALSE
);


CREATE TABLE IF NOT EXISTS customers (
    customer_id TEXT PRIMARY KEY,
    customer_name TEXT NOT NULL,
    customer_segment TEXT NOT NULL,
    country TEXT NOT NULL,
    region TEXT NOT NULL,
    state TEXT NOT NULL,
    city TEXT NOT NULL,
    geopoint TEXT
);

CREATE TABLE IF NOT EXISTS products (
    product_id TEXT PRIMARY KEY,
    product_category TEXT,
    product_subcategory TEXT,
    product_name TEXT
);

CREATE TABLE IF NOT EXISTS orders (
    order_id TEXT PRIMARY KEY,
    customer_id TEXT NOT NULL,
    order_date_id INT NOT NULL,
    ship_date_id INT NOT NULL,
    ship_mode TEXT NOT NULL,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    
    CONSTRAINT fk_orders_order_date
        FOREIGN KEY (order_date_id) REFERENCES calendar(date_id),
    
    CONSTRAINT fk_orders_ship_date
        FOREIGN KEY (ship_date_id) REFERENCES calendar(date_id)
);

CREATE TABLE IF NOT EXISTS order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    sales NUMERIC(12,2) NOT NULL,

    CONSTRAINT fk_order_items_orders
        FOREIGN KEY (order_id) REFERENCES orders(order_id),
    
    CONSTRAINT fk_order_items_products
        FOREIGN KEY (product_id) REFERENCES products(product_id)
);