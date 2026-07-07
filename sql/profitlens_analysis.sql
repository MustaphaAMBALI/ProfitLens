-- PROFITLENS | NOVABELLE DTC FASHION BRAND
-- E-commerce Revenue & Profitability Analysis
-- Author: Mustapha Ambali
-- Period: Jan 2023 - Dec 2024


-- ============================================================
-- SECTION 1: DATA CLEANING
-- ============================================================
   
-- Checking for duplicates in dim_customers
SELECT 
    customer_id,
    email,
    COUNT(*) AS occurrence
FROM dim_customers
GROUP BY customer_id, email
HAVING COUNT(*) > 1;                -- Result: No duplicates


-- Checking for duplicates in fact_costs
SELECT 
    order_id,
    COUNT(*) AS occurrence
FROM fact_costs
GROUP BY order_id
HAVING COUNT(*) > 1;                -- Result: No duplicates


-- Checking for duplicates in fact_orders
SELECT 
    order_id,
    order_date,
    COUNT(*) AS occurrence
FROM fact_orders
GROUP BY order_id, order_date
HAVING COUNT(*) > 1;                -- Result: No duplicates


-- Checking for NULL values in fact_orders
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id   IS NULL THEN 1 ELSE 0 END) AS null_order_id,
    SUM(CASE WHEN order_date IS NULL THEN 1 ELSE 0 END) AS null_order_date
FROM fact_orders;                  -- Result: Zero NULLs


-- Checking for NULL values in fact_costs
SELECT
    COUNT(*) AS total_rows,
    SUM(CASE WHEN order_id IS NULL THEN 1 ELSE 0 END) AS null_order_id
FROM fact_costs;                -- Result: Zero NULLs



-- ============================================================
-- SECTION 2: EXPLORATORY DATA ANALYSIS
-- ============================================================

-- 3 sales channels
SELECT DISTINCT channel_name
FROM dim_channels;

-- 3 customer segments: High Value, Mid Value, Low Value
SELECT DISTINCT customer_segment
FROM dim_customers;

-- 3,200 total customers
SELECT COUNT(customer_id) AS total_customers
FROM dim_customers;

-- 5 acquisition channels
SELECT DISTINCT acquisition_channel
FROM dim_customers;

-- 4 product categories
SELECT DISTINCT category
FROM dim_products;

-- 16 total products
SELECT COUNT(*) AS total_products
FROM dim_products;

-- 18,500 total orders
SELECT COUNT(*) AS total_orders
FROM fact_orders;


-- ============================================================
-- SECTION 3: CORE PROFITABILITY ANALYSIS
-- ============================================================

-- ── 3.1 Brand-Level Margin Waterfall ────────────────────────
-- Shows the full journey from GMV to Contribution Margin
-- KEY FORMULA:
--   GMV - Discounts = Net Revenue
--   Net Revenue - Refunds = Retained Revenue
--   Retained Revenue - Total Variable Cost = Contribution Margin
-- NOTE: total_variable_cost already contains COGS, shipping,
--       platform fees, payment fees, packaging, ad spend,
--       fulfillment and return shipping.

SELECT
    SUM(o.gross_revenue) AS gmv,
    SUM(o.discount_amount) AS total_discounts,
    SUM(o.net_revenue) AS net_revenue,
    SUM(o.refund_amount) AS total_refunds,
    SUM(o.net_revenue) - SUM(o.refund_amount) AS retained_revenue,
    SUM(c.total_variable_cost) AS total_variable_cost,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost) AS contribution_margin,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / SUM(o.gross_revenue) * 100, 2
    ) AS contribution_margin_pct
FROM fact_orders o
LEFT JOIN fact_costs c ON o.order_id = c.order_id;
-- Result: GMV $2,230,219 | CM $132,945 | CM% 5.96%
-- 5.96% is a critical threat - healthy DTC fashion target is 30%+


-- ── 3.2 Monthly Trend Analysis ───────────────────────────────
-- Tracks margin performance across all 24 months

SELECT
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month_no,
    FORMAT(o.order_date, 'MMM yyyy') AS month_name,
    SUM(o.gross_revenue) AS gmv,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost) AS contribution_margin,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / SUM(o.gross_revenue) * 100, 2
    ) AS contribution_margin_pct
FROM fact_orders o
LEFT JOIN fact_costs c ON o.order_id = c.order_id
GROUP BY
    YEAR(o.order_date),
    MONTH(o.order_date),
    FORMAT(o.order_date, 'MMM yyyy')
ORDER BY
    YEAR(o.order_date),
    MONTH(o.order_date);


-- ── 3.3 Channel Profitability ────────────────────────────────
-- Shows GMV share vs actual profit contribution per channel

SELECT
    ch.channel_name,
    SUM(o.gross_revenue) AS gmv,
    ROUND(SUM(o.gross_revenue)
        / SUM(SUM(o.gross_revenue)) OVER () * 100, 2) AS gmv_share_pct,
    SUM(c.platform_fee) AS platform_fees,
    SUM(c.fulfillment_cost) AS fulfillment_cost,
    SUM(c.ad_spend_allocated) AS ad_spend,
    SUM(c.return_shipping_cost) AS return_shipping,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost) AS contribution_margin,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / SUM(o.gross_revenue) * 100, 2
    ) AS contribution_margin_pct,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / SUM(SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost)) OVER () * 100, 2
    ) AS profit_share_pct
FROM fact_orders o
LEFT JOIN fact_costs c  ON o.order_id  = c.order_id
LEFT JOIN dim_channels ch ON o.channel_id = ch.channel_id
GROUP BY ch.channel_name;
-- KEY INSIGHT: Amazon = 29% GMV share but negative profit share
-- TikTok Shop = 26% GMV but 65%+ of total profit


-- ── 3.4 Amazon Cost Decomposition ───────────────────────────
-- Tests whether ad spend or platform fees cause Amazon's losses
-- INSIGHT: Removing platform fees recovers $60K vs $18K for ads
-- Root cause = Amazon's 17% referral fee, not marketing spend

SELECT
    ch.channel_name,
    SUM(o.gross_revenue) AS gmv,
    SUM(c.platform_fee) AS platform_fees,
    SUM(c.ad_spend_allocated) AS ad_spend,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost) AS contribution_margin,
    -- What margin would look like without ad spend
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost)
        + SUM(c.ad_spend_allocated) AS cm_without_ad_spend,
    -- What margin would look like without platform fees
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost)
        + SUM(c.platform_fee) AS cm_without_platform_fee
FROM fact_orders o
LEFT JOIN fact_costs c  ON o.order_id  = c.order_id
LEFT JOIN dim_channels ch ON o.channel_id = ch.channel_id
GROUP BY ch.channel_name;


-- ── 3.5 Discount Impact Analysis ────────────────────────────
-- Compares discounted vs full-price orders across all categories

-- Overall discount vs full-price comparison
SELECT
    CASE
        WHEN o.discount_amount > 0 THEN 'Discounted'
        ELSE 'Full-Price'
    END AS order_type,
    COUNT(o.order_id) AS total_orders,
    SUM(o.gross_revenue) AS gmv,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost) AS contribution_margin,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / SUM(o.gross_revenue) * 100, 2
    ) AS contribution_margin_pct
FROM fact_orders o
LEFT JOIN fact_costs c ON o.order_id = c.order_id
GROUP BY
    CASE
        WHEN o.discount_amount > 0 THEN 'Discounted'
        ELSE 'Full-Price'
    END;
-- Result: Discounted = -5.37% | Full-Price = 10.94%
-- Every discounted sale destroys margin


-- Discount impact broken down by product category
SELECT
    p.category,
    CASE
        WHEN o.discount_amount > 0 THEN 'Discounted'
        ELSE 'Full-Price'
    END AS order_type,
    COUNT(o.order_id) AS total_orders,
    SUM(o.gross_revenue) AS gmv,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost) AS contribution_margin,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / SUM(o.gross_revenue) * 100, 2
    ) AS contribution_margin_pct
FROM fact_orders o
LEFT JOIN fact_costs c  ON o.order_id  = c.order_id
LEFT JOIN dim_products p ON o.product_id = p.product_id
GROUP BY
    p.category,
    CASE
        WHEN o.discount_amount > 0 THEN 'Discounted'
        ELSE 'Full-Price'
    END
ORDER BY p.category, order_type;
-- KEY INSIGHT: Discounted Outerwear CM = -11.59%
-- NovaBelle's biggest GMV category is their biggest margin destroyer


-- ── 3.6 Customer Segment Performance 

SELECT
    c.customer_segment,
    COUNT(o.order_id) AS total_orders,
    SUM(o.gross_revenue) AS gmv,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(cost.total_variable_cost) AS contribution_margin,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(cost.total_variable_cost))
        / SUM(o.gross_revenue) * 100, 2
    ) AS contribution_margin_pct,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(cost.total_variable_cost))
        / COUNT(o.order_id), 2
    ) AS avg_cm_per_order
FROM fact_orders o
LEFT JOIN fact_costs cost ON o.order_id = cost.order_id
LEFT JOIN dim_customers c ON o.customer_id = c.customer_id
GROUP BY c.customer_segment;
-- Result: High Value $8.70 | Low Value $7.01 | Mid Value $6.63
-- Mid-Value underperforms Low-Value per order - worth investigating


-- ── 3.7 Segment x Category x Discount Cross Analysis ────────
-- Tests hypothesis: are Mid-Value customers buying more
-- discounted Outerwear than other segments?
-- FINDING: All segments buy discounted Outerwear at ~12%
-- Problem is universal - not a segment issue, it's a
-- product and pricing strategy issue

SELECT
    c.customer_segment,
    p.category,
    CASE
        WHEN o.discount_amount > 0 THEN 'Discounted'
        ELSE 'Full-Price'
    END AS order_type,
    COUNT(o.order_id) AS total_orders,
    SUM(o.gross_revenue) AS gmv
FROM fact_orders o
LEFT JOIN dim_customers c ON o.customer_id = c.customer_id
LEFT JOIN dim_products p  ON o.product_id  = p.product_id
GROUP BY
    c.customer_segment,
    p.category,
    CASE
        WHEN o.discount_amount > 0 THEN 'Discounted'
        ELSE 'Full-Price'
    END
ORDER BY c.customer_segment, p.category;


-- ── 3.8 Category Profitability with Return Rates ─────────────
-- Shows return rate impact on each category's margin

SELECT
    p.category,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN o.is_returned = 1 THEN 1 ELSE 0 END) AS returned_orders,
    ROUND(
        SUM(CASE WHEN o.is_returned = 1 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(o.order_id), 2
    ) AS return_rate_pct,
    SUM(o.gross_revenue) AS gmv,
    SUM(o.refund_amount) AS total_refunds,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost) AS contribution_margin,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / SUM(o.gross_revenue) * 100, 2
    ) AS contribution_margin_pct
FROM fact_orders o
LEFT JOIN fact_costs c  ON o.order_id  = c.order_id
LEFT JOIN dim_products p ON o.product_id = p.product_id
GROUP BY p.category
ORDER BY contribution_margin_pct;
-- Outerwear will show highest return rate AND worst margin
-- connecting the two problems visually in the dashboard


-- ============================================================
-- SECTION 4: SQL VIEWS FOR POWER BI
-- ============================================================

-- ── VIEW 1: v_brand_waterfall ────────────────────────────────
-- Single-row brand summary for KPI cards and waterfall chart
-- This is Page 1 of the dashboard

CREATE VIEW v_brand_waterfall AS (
SELECT
    SUM(o.gross_revenue) AS gmv,
    SUM(o.discount_amount) AS total_discounts,
    SUM(o.net_revenue) AS net_revenue,
    SUM(o.refund_amount) AS total_refunds,
    SUM(o.net_revenue) - SUM(o.refund_amount) AS retained_revenue,
    SUM(c.total_variable_cost) AS total_variable_cost,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost) AS contribution_margin,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / SUM(o.gross_revenue) * 100, 2
    ) AS contribution_margin_pct
FROM fact_orders o
LEFT JOIN fact_costs c ON o.order_id = c.order_id
);


-- ── VIEW 2: v_monthly_performance ───────────────────────────
-- Monthly GMV and margin trend across 24 months
-- Feeds the trend line chart on Page 1

CREATE VIEW v_monthly_performance AS (
SELECT
    YEAR(o.order_date) AS year,
    MONTH(o.order_date) AS month_no,
    FORMAT(o.order_date, 'MMM yyyy') AS month_name,
    SUM(o.gross_revenue) AS gmv,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost) AS contribution_margin,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / SUM(o.gross_revenue) * 100, 2
    ) AS contribution_margin_pct
FROM fact_orders o
LEFT JOIN fact_costs c ON o.order_id = c.order_id
GROUP BY
    YEAR(o.order_date),
    MONTH(o.order_date),
    FORMAT(o.order_date, 'MMM yyyy')
);


-- ── VIEW 3: v_channel_profitability ─────────────────────────
-- Channel-level P&L with GMV share vs profit share
-- Feeds Page 3: Channel P&L
-- The GMV share vs profit share gap is the Amazon story

CREATE VIEW v_channel_profitability AS (
SELECT
    ch.channel_name,
    COUNT(o.order_id) AS total_orders,
    SUM(o.gross_revenue) AS gmv,
    ROUND(SUM(o.gross_revenue)
        / SUM(SUM(o.gross_revenue)) OVER () * 100, 2) AS gmv_share_pct,
    SUM(c.platform_fee) AS platform_fees,
    SUM(c.fulfillment_cost) AS fulfillment_cost,
    SUM(c.ad_spend_allocated) AS ad_spend,
    SUM(c.shipping_cost) AS shipping_cost,
    SUM(c.return_shipping_cost) AS return_shipping,
    SUM(o.refund_amount) AS total_refunds,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost) AS contribution_margin,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / SUM(o.gross_revenue) * 100, 2
    ) AS contribution_margin_pct,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / SUM(SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost)) OVER () * 100, 2
    ) AS profit_share_pct
FROM fact_orders o
LEFT JOIN fact_costs c    ON o.order_id   = c.order_id
LEFT JOIN dim_channels ch ON o.channel_id = ch.channel_id
GROUP BY ch.channel_name
);


-- ── VIEW 4: v_category_profitability ────────────────────────
-- Product category P&L with return rates and discount breakdown
-- Feeds Page 2: Product Profitability

CREATE VIEW v_category_profitability AS
SELECT
    p.category,
    COUNT(o.order_id) AS total_orders,
    SUM(CASE WHEN o.is_returned = 1 THEN 1 ELSE 0 END) AS returned_orders,
    ROUND(
        SUM(CASE WHEN o.is_returned = 1 THEN 1 ELSE 0 END)
        * 100.0 / COUNT(o.order_id), 2
    ) AS return_rate_pct,
    SUM(o.gross_revenue) AS gmv,
    SUM(o.discount_amount) AS total_discounts,
    SUM(o.refund_amount) AS total_refunds,
    SUM(c.total_variable_cost) AS total_variable_cost,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost) AS contribution_margin,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / SUM(o.gross_revenue) * 100, 2
    ) AS contribution_margin_pct
FROM fact_orders o
LEFT JOIN fact_costs c  ON o.order_id  = c.order_id
LEFT JOIN dim_products p ON o.product_id = p.product_id
GROUP BY p.category;


-- ── VIEW 5: v_discount_impact ────────────────────────────────
-- Discounted vs full-price performance by category
-- Feeds Page 4: Discount & Customer Analysis
-- Shows the break-even problem on discounted Outerwear

CREATE VIEW v_discount_impact AS
SELECT
    p.category,
    CASE
        WHEN o.discount_amount > 0 THEN 'Discounted'
        ELSE 'Full-Price'
    END                                                         AS order_type,
    COUNT(o.order_id)                                           AS total_orders,
    SUM(o.gross_revenue)                                        AS gmv,
    SUM(o.discount_amount)                                      AS total_discounts,
    SUM(o.refund_amount)                                        AS total_refunds,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost)                            AS contribution_margin,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / SUM(o.gross_revenue) * 100, 2
    )                                                           AS contribution_margin_pct,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / COUNT(o.order_id), 2
    )                                                           AS avg_cm_per_order
FROM fact_orders o
LEFT JOIN fact_costs c  ON o.order_id  = c.order_id
LEFT JOIN dim_products p ON o.product_id = p.product_id
GROUP BY
    p.category,
    CASE
        WHEN o.discount_amount > 0 THEN 'Discounted'
        ELSE 'Full-Price'
    END;


-- ── VIEW 6: v_segment_performance ───────────────────────────
-- Customer segment P&L with per-order margin
-- Feeds Page 4: Discount & Customer Analysis

CREATE VIEW v_segment_performance AS
SELECT
    c.customer_segment,
    COUNT(o.order_id) AS total_orders,
    SUM(o.gross_revenue) AS gmv,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(cost.total_variable_cost) AS contribution_margin,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(cost.total_variable_cost))
        / SUM(o.gross_revenue) * 100, 2
    ) AS contribution_margin_pct,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(cost.total_variable_cost))
        / COUNT(o.order_id), 2
    ) AS avg_cm_per_order
FROM fact_orders o
LEFT JOIN fact_costs cost ON o.order_id      = cost.order_id
LEFT JOIN dim_customers c ON o.customer_id   = c.customer_id
GROUP BY c.customer_segment;


ALTER VIEW v_monthly_performance AS
SELECT
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS month_date,
    YEAR(o.order_date)                                          AS year,
    MONTH(o.order_date)                                         AS month_no,
    FORMAT(o.order_date, 'MMM yyyy')                            AS month_name,
    SUM(o.gross_revenue)                                        AS gmv,
    SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost)                            AS contribution_margin,
    ROUND(
        (SUM(o.net_revenue) - SUM(o.refund_amount)
        - SUM(c.total_variable_cost))
        / SUM(o.gross_revenue) * 100, 2
    )                                                           AS contribution_margin_pct
FROM fact_orders o
LEFT JOIN fact_costs c ON o.order_id = c.order_id
GROUP BY
    DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1),
    YEAR(o.order_date),
    MONTH(o.order_date),
    FORMAT(o.order_date, 'MMM yyyy')


SELECT * FROM v_brand_waterfall;
SELECT * FROM v_category_profitability;
SELECT * FROM v_channel_profitability;
SELECT * FROM v_discount_impact;
SELECT * FROM v_monthly_performance;
SELECT * FROM v_segment_performance;
