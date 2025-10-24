--Key Data Marts (витрины)

--1 GENERAL VIEW
CREATE OR REPLACE VIEW v_sales_report AS
SELECT
    --id
    oi.order_item_id,
    o.order_id,
    p.product_id,
    c.customer_id,

    --order items
    oi.sales,

    --products
    p.product_name,
    p.product_category,
    p.product_subcategory,

    --customer and geo
    c.customer_name,
    c.customer_segment,
    c.country,
    c.region,
    c.state,
    c.city,
    c.geopoint,

	--orders
    o.ship_mode,
    cal_order.full_date AS order_date,
    cal_ship.full_date AS ship_date,

	--calculated
    (cal_ship.full_date - cal_order.full_date) AS ship_time_days,

	--time details
    cal_order.date_year AS order_year,
    cal_order.date_month AS order_month,
    cal_order.date_day AS order_day,
    cal_order.weekday AS order_weekday,
    cal_order.quarter AS order_quarter,
    cal_order.is_holiday AS is_order_on_holiday

FROM order_items AS oi
LEFT JOIN orders AS o ON oi.order_id = o.order_id
LEFT JOIN products AS p ON oi.product_id = p.product_id
LEFT JOIN customers AS c ON o.customer_id = c.customer_id
LEFT JOIN calendar AS cal_order ON o.order_date_id = cal_order.date_id
LEFT JOIN calendar AS cal_ship ON o.ship_date_id = cal_ship.date_id;


--2 COHORT ANALYSIS
--first purchase/order
CREATE OR REPLACE VIEW cohort_analysis AS
WITH customer_first_purchase AS (
    SELECT
        o.customer_id,
        MIN(o.order_date_id) AS first_purchase_date_id
    FROM orders o
    GROUP BY o.customer_id
),
--cohort
customer_cohort AS (
    SELECT
        cfp.customer_id,
        cal.date_year AS first_purchase_year,
        cal.quarter AS first_purchase_quarter,
        CONCAT(cal.date_year, ' Q', cal.quarter) AS first_purchase_cohort
    FROM customer_first_purchase cfp
    JOIN calendar cal 
        ON cfp.first_purchase_date_id = cal.date_id
),
--customer and quarter agg
customer_quarterly_sales AS (
    SELECT
        o.customer_id,
        cal.date_year AS purchase_year,
        cal.quarter AS purchase_quarter,
        CONCAT(cal.date_year, ' Q', cal.quarter) AS purchase_period,
        SUM(oi.sales) AS total_sales,
        COUNT(DISTINCT o.order_id) AS total_orders
    FROM orders o
    JOIN order_items oi 
        ON o.order_id = oi.order_id
    JOIN calendar cal 
        ON o.order_date_id = cal.date_id
    GROUP BY
        o.customer_id,
        cal.date_year,
        cal.quarter
)

--JOINS
SELECT
    c.customer_id,
    c.customer_name,
    c.customer_segment,
    c.country,
    c.region,
    c.state,
    c.city,

    --cohort
    cc.first_purchase_year,
    cc.first_purchase_quarter,
    cc.first_purchase_cohort,

    --current quarter
    cqs.purchase_year,
    cqs.purchase_quarter,
    cqs.purchase_period,

    --cohort index
    ( (cqs.purchase_year - cc.first_purchase_year) * 4
      + (cqs.purchase_quarter - cc.first_purchase_quarter) ) AS cohort_index_quarter,

    cqs.total_sales,
    cqs.total_orders

FROM customer_quarterly_sales cqs
JOIN customers c 
    ON cqs.customer_id = c.customer_id
JOIN customer_cohort cc 
    ON cqs.customer_id = cc.customer_id;
	
--3 RPR and CRR VIEW	
CREATE OR REPLACE VIEW customer_yearly_activity AS
WITH customer_yearly_stats AS (
	--agg by client and year
    SELECT
        o.customer_id,
        cal.date_year AS purchase_year,
        COUNT(DISTINCT o.order_id) AS total_orders_year,
        SUM(oi.sales) AS total_sales_year
    FROM orders o
    JOIN calendar cal 
        ON o.order_date_id = cal.date_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    GROUP BY
        o.customer_id,
        cal.date_year
)
--previous_purchase_year
SELECT
    cys.customer_id,
    cys.purchase_year,
    cys.total_orders_year,
    cys.total_sales_year,
    
    LAG(cys.purchase_year, 1) OVER (
        PARTITION BY cys.customer_id 
        ORDER BY cys.purchase_year
    ) AS previous_purchase_year
    
FROM customer_yearly_stats cys;