#Tugas Day 2
#Soal 01: ongkos kirim 2025
SELECT
  SUM(shipping_fee) AS total_shipping_fee,
  AVG(shipping_fee) AS avg_shipping_fee_per_order
FROM `toko_peralatan_dapur.orders`
WHERE EXTRACT(YEAR FROM sales_date) = 2025;

# Soal 02: Top 5 Produk
-- Top 5 produk berdasarkan Unit Terjual (Quantity)
SELECT
    product_name,
    SUM(quantity) AS total_units_sold
FROM `toko_peralatan_dapur.orders`
WHERE status_clean = 'complete'
GROUP BY product_name
ORDER BY total_units_sold DESC
LIMIT 5;

-- Top 5 produk berdasarkan Revenue (Total Penjualan Bersih)
SELECT
    product_name,
    SUM(total) AS total_revenue
FROM `toko_peralatan_dapur.orders`
WHERE status_clean = 'complete'
GROUP BY product_name
ORDER BY total_revenue DESC
LIMIT 5;

#Soal 03: Q4 2025 Completed
SELECT
    COUNT(DISTINCT order_id) AS total_completed_orders,
    SUM(total) AS total_revenue
FROM `toko_peralatan_dapur.orders`
WHERE status_clean = 'complete'
    AND sales_date BETWEEN '2025-10-01' AND '2025-12-31';

#Soal 04: Kota Ongkir Termahal & Termurah
WITH city_shipping AS (
    SELECT
        city_clean,
        AVG(shipping_fee) AS avg_shipping
    FROM `toko_peralatan_dapur.orders`
    WHERE city_clean IS NOT NULL
    GROUP BY city_clean
)

SELECT
    MAX(avg_shipping) AS max_avg_shipping,
    MIN(avg_shipping) AS min_avg_shipping,
    MAX(avg_shipping) - MIN(avg_shipping) AS shipping_difference
FROM city_shipping;

#Soal 05: Refund Analysis
WITH sales_stats AS (
    SELECT
        SUM(CASE WHEN status_clean = 'refund' THEN total ELSE 0 END) AS total_refund,
        SUM(CASE WHEN EXTRACT(YEAR FROM sales_date) = 2025 THEN total ELSE 0 END) AS gross_sales_2025
    FROM `toko_peralatan_dapur.orders`
)

SELECT
    total_refund,
    gross_sales_2025,
    ROUND((total_refund / gross_sales_2025) * 100, 2) AS refund_percentage
FROM sales_stats;

#Soal 06: Top 5 Produk Berdasarkan Rata-rata Quantity
-- Minimal 50 pesanan complete
SELECT
    product_name,
    COUNT(order_id) AS total_completed_orders,
    AVG(quantity) AS avg_quantity_per_order
FROM `toko_peralatan_dapur.orders`
WHERE status_clean = 'complete'
GROUP BY product_name
HAVING COUNT(order_id) >= 50
ORDER BY avg_quantity_per_order DESC
LIMIT 5;

#Soal 07: Revenue Completed Tertinggi per Kategori
WITH monthly_revenue AS (
    SELECT
        category_clean,
        FORMAT_DATE('%Y-%m', sales_date) AS month,
        SUM(total) AS revenue
    FROM `toko_peralatan_dapur.orders`
    WHERE status_clean = 'complete'
      AND category_clean IS NOT NULL
      AND category_clean != '#REF!'
    GROUP BY category_clean, month
)

SELECT
    category_clean,
    month,
    revenue
FROM (
    SELECT *,
           ROW_NUMBER() OVER(
               PARTITION BY category_clean
               ORDER BY revenue DESC
           ) AS rn
    FROM monthly_revenue
)
WHERE rn = 1
ORDER BY category_clean;

#Soal 08: Produk yang Menyumbang 80% Revenue Completed
WITH product_revenue AS (
    SELECT
        product_name,
        SUM(total) AS revenue
    FROM `toko_peralatan_dapur.orders`
    WHERE status_clean = 'complete'
    GROUP BY product_name
),

ranking AS (
    SELECT
        *,
        SUM(revenue) OVER (ORDER BY revenue DESC) AS cumulative_revenue,
        SUM(revenue) OVER () AS total_revenue
    FROM product_revenue
)

SELECT
    COUNT(*) AS jumlah_produk_80_persen
FROM ranking
WHERE cumulative_revenue <= total_revenue * 0.8;

#Soal 09: Rata-rata Jeda Hari Antar Pesanan
WITH customer_orders AS (
    SELECT
        customer_name_clean,
        sales_date,
        LAG(sales_date) OVER (
            PARTITION BY customer_name_clean
            ORDER BY sales_date
        ) AS previous_order
    FROM `toko_peralatan_dapur.orders`
    WHERE status_clean = 'complete'
),

gap_days AS (
    SELECT
        customer_name_clean,
        DATE_DIFF(sales_date, previous_order, DAY) AS gap_day
    FROM customer_orders
    WHERE previous_order IS NOT NULL
),

customer_gap AS (
    SELECT
        customer_name_clean,
        COUNT(*) + 1 AS total_orders,
        AVG(gap_day) AS avg_gap_day
    FROM gap_days
    GROUP BY customer_name_clean
    HAVING total_orders > 5
)

SELECT *
FROM customer_gap
ORDER BY avg_gap_day
LIMIT 1;

#Soal 10: Produk dengan Refund Rate Tertinggi
WITH product_refund AS (
    SELECT
        product_name,
        COUNT(*) AS total_orders,
        COUNTIF(LOWER(status_clean) IN ('refund','refunded')) AS refund_orders,
        SUM(total) AS total_revenue
    FROM `toko_peralatan_dapur.orders`
    GROUP BY product_name
),

refund_analysis AS (
    SELECT
        product_name,
        total_orders,
        refund_orders,
        total_revenue,
        SAFE_DIVIDE(refund_orders, total_orders) AS refund_rate
    FROM product_refund
)

SELECT
    product_name,
    total_orders,
    refund_orders,
    ROUND(refund_rate * 100, 2) AS refund_rate,
    total_revenue,
    ROUND(
        GREATEST(refund_rate - 0.05, 0) * total_revenue,
        2
    ) AS potential_revenue_saved
FROM refund_analysis
WHERE refund_orders > 0
ORDER BY refund_rate DESC
LIMIT 1;

