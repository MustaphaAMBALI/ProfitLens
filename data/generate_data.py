"""
ProfitLens - NovaBelle Dataset Generator
DTC Fashion & Apparel Brand | 24 Months | Jan 2023 - Dec 2024
Author: Mustapha Ambali
"""

# ── IMPORTS ──────────────────────────────────────────────────────────────────
import pandas as pd          # For building and saving tables (DataFrames)
import numpy as np           # For random number generation with controlled ranges
from faker import Faker      # For generating realistic fake names, IDs, dates
import random                # For weighted random choices
from datetime import date    # For working with date ranges
import os                    # For creating output folders

# Set a random seed so the dataset is reproducible every time you run it
# Without this, numbers change on every run - bad for a portfolio project
random.seed(42)
np.random.seed(42)
fake = Faker()
Faker.seed(42)

# ── OUTPUT FOLDER ─────────────────────────────────────────────────────────────
# All CSV files will be saved here
output_dir = "/home/claude/novabelle_data"
os.makedirs(output_dir, exist_ok=True)


# ═════════════════════════════════════════════════════════════════════════════
# TABLE 1: dim_products
# Every product NovaBelle sells, with its category and cost structure
# ═════════════════════════════════════════════════════════════════════════════

products = [
    # (product_id, product_name, category, unit_price, cogs_pct, weight_kg)
    # Outerwear - high price, high COGS, high returns = the problem category
    ("P001", "Classic Wool Coat",        "Outerwear",   189.99, 0.42, 1.2),
    ("P002", "Puffer Jacket Oversized",  "Outerwear",   159.99, 0.42, 0.9),
    ("P003", "Trench Coat Premium",      "Outerwear",   219.99, 0.42, 1.1),
    ("P004", "Quilted Vest",             "Outerwear",   99.99,  0.42, 0.5),

    # Dresses - mid price, mid returns
    ("P005", "Wrap Midi Dress",          "Dresses",     89.99,  0.38, 0.4),
    ("P006", "Linen Summer Dress",       "Dresses",     79.99,  0.38, 0.3),
    ("P007", "Velvet Evening Dress",     "Dresses",     129.99, 0.38, 0.5),
    ("P008", "Floral Maxi Dress",        "Dresses",     95.99,  0.38, 0.4),

    # Basics - low price, low returns, steady margin
    ("P009", "Essential Cotton Tee",     "Basics",      34.99,  0.35, 0.2),
    ("P010", "Ribbed Knit Sweater",      "Basics",      64.99,  0.35, 0.3),
    ("P011", "High Waist Leggings",      "Basics",      54.99,  0.35, 0.2),
    ("P012", "Classic Denim Jeans",      "Basics",      84.99,  0.35, 0.5),

    # Accessories - low price, lowest returns, highest net margin
    ("P013", "Leather Belt",             "Accessories", 39.99,  0.28, 0.2),
    ("P014", "Silk Scarf",               "Accessories", 49.99,  0.28, 0.1),
    ("P015", "Canvas Tote Bag",          "Accessories", 44.99,  0.28, 0.3),
    ("P016", "Knit Beanie",              "Accessories", 24.99,  0.28, 0.1),
]

# Build the products DataFrame (a table in Python/Pandas)
df_products = pd.DataFrame(products, columns=[
    "product_id", "product_name", "category",
    "unit_price", "cogs_pct", "weight_kg"
])

# Calculate COGS per unit directly in the table
df_products["cogs_per_unit"] = (
    df_products["unit_price"] * df_products["cogs_pct"]
).round(2)

print(f"Products created: {len(df_products)} products across 4 categories")


# ═════════════════════════════════════════════════════════════════════════════
# TABLE 2: dim_channels
# The three channels NovaBelle sells on, with their fee structures
# ═════════════════════════════════════════════════════════════════════════════

channels = [
    # (channel_id, channel_name, platform_fee_pct, fulfillment_cost, payment_fee_pct, shipping_cost)
    # Shopify - lowest fees, best margin per order
    ("CH01", "Shopify",     0.00,  0.00, 0.029, 7.20),
    # Amazon - highest fees + FBA cost = margin killer
    ("CH02", "Amazon",      0.17,  3.50, 0.00,  0.00),
    # TikTok Shop - low commission, low shipping, mostly organic traffic
    ("CH03", "TikTok Shop", 0.06,  0.00, 0.015, 6.50),
]

df_channels = pd.DataFrame(channels, columns=[
    "channel_id", "channel_name", "platform_fee_pct",
    "fulfillment_cost_per_order", "payment_fee_pct", "avg_shipping_cost"
])

print(f"Channels created: {len(df_channels)} channels")


# ═════════════════════════════════════════════════════════════════════════════
# TABLE 3: dim_customers
# 3,200 unique customers with acquisition channel and segment
# ═════════════════════════════════════════════════════════════════════════════

NUM_CUSTOMERS = 3200

# Customer segments - how valuable they are to the business
segments      = ["High Value", "Mid Value", "Low Value"]
segment_weights = [0.20, 0.45, 0.35]   # 20% high, 45% mid, 35% low value

# Where customers first came from - affects LTV and repeat behavior
acq_channels  = ["Paid Social", "Organic Search", "Email", "Referral", "Marketplace"]
acq_weights   = [0.40, 0.25, 0.15, 0.10, 0.10]

customers = []
for i in range(1, NUM_CUSTOMERS + 1):
    customers.append({
        "customer_id":          f"C{i:05d}",          # C00001, C00002...
        "customer_name":        fake.name(),
        "email":                fake.email(),
        "country":              random.choice(["US", "US", "US", "CA", "UK"]),
        "acquisition_channel":  random.choices(acq_channels, acq_weights)[0],
        "acquisition_date":     fake.date_between(
                                    start_date=date(2022, 10, 1),
                                    end_date=date(2024, 10, 1)
                                ),
        "customer_segment":     random.choices(segments, segment_weights)[0],
    })

df_customers = pd.DataFrame(customers)
print(f"Customers created: {len(df_customers)} customers")


# ═════════════════════════════════════════════════════════════════════════════
# TABLE 4: fact_orders  (THE MAIN TABLE - 18,500 orders)
# Every transaction NovaBelle made over 24 months
# This is where the profitability story lives
# ═════════════════════════════════════════════════════════════════════════════

NUM_ORDERS = 18500

# ── Channel distribution (% of total orders) ──────────────────────────────
# Shopify gets most orders, Amazon second, TikTok growing
channel_ids     = ["CH01", "CH02", "CH03"]
channel_weights = [0.45,   0.29,   0.26]

# ── Product weights by category (engineered to hit our GMV targets) ────────
# Within each category, products share orders roughly equally
category_weights = {
    "Outerwear":   0.38,
    "Dresses":     0.24,
    "Basics":      0.28,
    "Accessories": 0.10,
}

# Pre-build a list of product_ids grouped by category for fast lookup
products_by_category = {}
for cat in df_products["category"].unique():
    products_by_category[cat] = df_products[
        df_products["category"] == cat
    ]["product_id"].tolist()

# ── Return rates by category (engineered - Outerwear is the problem) ───────
return_rates = {
    "Outerwear":   0.31,   # 31% of Outerwear orders get returned
    "Dresses":     0.19,
    "Basics":      0.08,
    "Accessories": 0.05,
}

# ── Discount logic ──────────────────────────────────────────────────────────
# 22% of orders have a discount
# Discounts are deeper in Q4 (Oct-Dec) to simulate seasonal sales
DISCOUNT_RATE     = 0.22
BASE_DISCOUNT_PCT = 0.28   # 28% average discount depth

# ── Seasonal demand pattern ─────────────────────────────────────────────────
# More orders in Q4 (holiday season), fewer in Q1
# These weights apply to each month (Jan=index 0, Dec=index 11)
monthly_weights = [
    0.06, 0.06, 0.07, 0.07,   # Jan-Apr: slow
    0.08, 0.08, 0.08, 0.09,   # May-Aug: building
    0.09, 0.10, 0.11, 0.11,   # Sep-Dec: peak season
]

# Build a weighted list of dates across 24 months
all_dates = []
for year in [2023, 2024]:
    for month in range(1, 13):
        weight = monthly_weights[month - 1]
        # Number of orders this month = total orders * weight / 2 years
        count = int(NUM_ORDERS * weight / 2)
        for _ in range(count):
            # Random day within the month
            day = random.randint(1, 28)   # Max 28 to avoid Feb issues
            all_dates.append(date(year, month, day))

# Shuffle dates so orders aren't grouped by month in the table
random.shuffle(all_dates)

# Trim or pad to exactly NUM_ORDERS
while len(all_dates) < NUM_ORDERS:
    all_dates.append(fake.date_between(
        start_date=date(2023, 1, 1),
        end_date=date(2024, 12, 31)
    ))
all_dates = all_dates[:NUM_ORDERS]

# ── Generate orders ─────────────────────────────────────────────────────────
orders = []

for i in range(NUM_ORDERS):
    order_date  = all_dates[i]
    order_month = order_date.month

    # Pick a channel for this order
    channel_id  = random.choices(channel_ids, channel_weights)[0]

    # Pick a product category (weighted), then a product within that category
    category    = random.choices(
                    list(category_weights.keys()),
                    list(category_weights.values())
                  )[0]
    product_id  = random.choice(products_by_category[category])

    # Look up product details
    product_row = df_products[df_products["product_id"] == product_id].iloc[0]
    unit_price  = product_row["unit_price"]
    cogs_unit   = product_row["cogs_per_unit"]

    # Most orders are qty 1; occasionally 2 (realistic for fashion)
    quantity    = random.choices([1, 2], weights=[0.88, 0.12])[0]

    # Gross revenue before any discount
    gross_rev   = round(unit_price * quantity, 2)

    # ── Discount logic ───────────────────────────────────────────────────────
    # Higher chance of discount in Q4 and for Outerwear/Dresses
    is_q4       = order_month in [10, 11, 12]
    is_high_return_cat = category in ["Outerwear", "Dresses"]

    # Adjust discount probability based on season and category
    discount_prob = DISCOUNT_RATE
    if is_q4:
        discount_prob += 0.15          # Much more discounting in Q4
    if is_high_return_cat:
        discount_prob += 0.05          # Outerwear and Dresses discounted more

    has_discount   = random.random() < discount_prob
    discount_depth = 0.0

    if has_discount:
        # Q4 discounts are slightly deeper
        if is_q4:
            discount_depth = round(random.uniform(0.25, 0.40), 2)
        else:
            discount_depth = round(random.uniform(0.10, 0.28), 2)

    discount_amount = round(gross_rev * discount_depth, 2)
    net_order_rev   = round(gross_rev - discount_amount, 2)

    # ── Return logic ─────────────────────────────────────────────────────────
    # Returns happen more on Amazon (easier returns process)
    channel_return_multiplier = 1.3 if channel_id == "CH02" else 1.0
    effective_return_rate = min(
        return_rates[category] * channel_return_multiplier, 0.95
    )
    is_returned    = random.random() < effective_return_rate

    # Return happens 5-21 days after order
    return_date    = None
    refund_amount  = 0.0
    if is_returned:
        return_days  = random.randint(5, 21)
        return_date  = date(
            order_date.year,
            order_date.month,
            min(order_date.day + return_days, 28)
        )
        # Full refund on returned amount
        refund_amount = net_order_rev

    # Pick a customer for this order
    customer_id = f"C{random.randint(1, NUM_CUSTOMERS):05d}"

    orders.append({
        "order_id":       f"ORD{i+1:06d}",
        "order_date":     order_date,
        "customer_id":    customer_id,
        "channel_id":     channel_id,
        "product_id":     product_id,
        "category":       category,
        "quantity":       quantity,
        "unit_price":     unit_price,
        "gross_revenue":  gross_rev,
        "discount_depth": discount_depth,
        "discount_amount": discount_amount,
        "net_revenue":    net_order_rev,
        "cogs_total":     round(cogs_unit * quantity, 2),
        "is_returned":    is_returned,
        "return_date":    return_date,
        "refund_amount":  refund_amount,
    })

df_orders = pd.DataFrame(orders)
print(f"Orders created: {len(df_orders):,} orders")
print(f"Total GMV: ${df_orders['gross_revenue'].sum():,.0f}")
print(f"Total Net Revenue (after discounts): ${df_orders['net_revenue'].sum():,.0f}")
print(f"Overall Return Rate: {df_orders['is_returned'].mean():.1%}")


# ═════════════════════════════════════════════════════════════════════════════
# TABLE 5: fact_costs
# All variable costs attached to each order
# This is what transforms revenue into contribution margin
# ═════════════════════════════════════════════════════════════════════════════

# Look up channel details for cost calculations
channel_lookup = df_channels.set_index("channel_id").to_dict("index")

costs = []
for _, order in df_orders.iterrows():
    ch       = channel_lookup[order["channel_id"]]
    net_rev  = order["net_revenue"]
    is_ret   = order["is_returned"]

    # Platform fee (Amazon 17%, TikTok 6%, Shopify 0%)
    platform_fee = round(net_rev * ch["platform_fee_pct"], 2)

    # Payment processing (Shopify 2.9%, TikTok 1.5%, Amazon 0% - included in referral)
    payment_fee  = round(net_rev * ch["payment_fee_pct"], 2)

    # Fulfillment cost (Amazon FBA flat fee, others 0)
    fulfillment  = ch["fulfillment_cost_per_order"]

    # Shipping cost (Shopify and TikTok only)
    shipping     = ch["avg_shipping_cost"] if order["channel_id"] != "CH02" else 0.0

    # Packaging cost - flat per order
    packaging    = round(random.uniform(1.20, 2.50), 2)

    # Ad spend allocated per order by channel
    # Shopify 12% of net rev, Amazon 10%, TikTok 3%
    ad_spend_pct = {"CH01": 0.12, "CH02": 0.10, "CH03": 0.03}
    ad_spend     = round(net_rev * ad_spend_pct[order["channel_id"]], 2)

    # Return shipping cost - brand pays return shipping on returned orders
    return_shipping = round(random.uniform(5.0, 9.0), 2) if is_ret else 0.0

    # Total variable cost for this order
    total_variable_cost = round(
        order["cogs_total"] + platform_fee + payment_fee +
        fulfillment + shipping + packaging + ad_spend + return_shipping, 2
    )

    # Contribution margin = net revenue minus all variable costs
    # If the order was returned, net revenue is 0 (refunded) but costs still happened
    effective_net_rev = 0.0 if is_ret else net_rev
    contribution_margin = round(effective_net_rev - total_variable_cost, 2)

    costs.append({
        "order_id":              order["order_id"],
        "platform_fee":          platform_fee,
        "payment_fee":           payment_fee,
        "fulfillment_cost":      fulfillment,
        "shipping_cost":         shipping,
        "packaging_cost":        packaging,
        "ad_spend_allocated":    ad_spend,
        "return_shipping_cost":  return_shipping,
        "total_variable_cost":   total_variable_cost,
        "contribution_margin":   contribution_margin,
    })

df_costs = pd.DataFrame(costs)
print(f"\nCosts table created: {len(df_costs):,} rows")
print(f"Total Contribution Margin: ${df_costs['contribution_margin'].sum():,.0f}")


# ═════════════════════════════════════════════════════════════════════════════
# QUICK STORY VALIDATION
# Before saving, confirm the engineered story holds in the numbers
# ═════════════════════════════════════════════════════════════════════════════

print("\n── STORY VALIDATION ───────────────────────────────────────")

# Merge orders + costs + channel names for analysis
merged = df_orders.merge(df_costs, on="order_id")
merged = merged.merge(
    df_channels[["channel_id", "channel_name"]], on="channel_id"
)

# 1. Contribution margin by category
cat_margin = merged.groupby("category").agg(
    gmv=("gross_revenue", "sum"),
    contribution_margin=("contribution_margin", "sum")
).assign(
    cm_pct=lambda x: (x["contribution_margin"] / x["gmv"] * 100).round(1)
).sort_values("cm_pct")

print("\nContribution Margin % by Category:")
print(cat_margin[["gmv", "contribution_margin", "cm_pct"]].to_string())

# 2. Contribution margin by channel
ch_margin = merged.groupby("channel_name").agg(
    gmv=("gross_revenue", "sum"),
    contribution_margin=("contribution_margin", "sum")
).assign(
    cm_pct=lambda x: (x["contribution_margin"] / x["gmv"] * 100).round(1),
    gmv_share=lambda x: (x["gmv"] / x["gmv"].sum() * 100).round(1),
    profit_share=lambda x: (
        x["contribution_margin"] / x["contribution_margin"].sum() * 100
    ).round(1)
).sort_values("cm_pct")

print("\nChannel GMV Share vs Profit Share:")
print(ch_margin[["gmv_share", "profit_share", "cm_pct"]].to_string())

# 3. The smoking gun: Outerwear on Amazon with discounts
smoking_gun = merged[
    (merged["category"]     == "Outerwear") &
    (merged["channel_id"]   == "CH02") &
    (merged["discount_amount"] > 0)
]
sg_cm = smoking_gun["contribution_margin"].mean()
print(f"\nSMOKING GUN - Avg contribution margin per Outerwear order on Amazon (discounted):")
print(f"  ${sg_cm:.2f} per order")
print("  (Negative = NovaBelle loses money on every one of these sales)")

print("\n── END VALIDATION ──────────────────────────────────────────")


# ═════════════════════════════════════════════════════════════════════════════
# SAVE ALL TABLES TO CSV
# ═════════════════════════════════════════════════════════════════════════════

df_products.to_csv(f"{output_dir}/dim_products.csv",  index=False)
df_channels.to_csv(f"{output_dir}/dim_channels.csv",  index=False)
df_customers.to_csv(f"{output_dir}/dim_customers.csv", index=False)
df_orders.to_csv(f"{output_dir}/fact_orders.csv",     index=False)
df_costs.to_csv(f"{output_dir}/fact_costs.csv",       index=False)

print("\nAll tables saved to /home/claude/novabelle_data/")
print("Files: dim_products, dim_channels, dim_customers, fact_orders, fact_costs")
