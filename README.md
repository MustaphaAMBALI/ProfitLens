# ProfitLens | E-commerce Revenue & Profitability Audit

**Tools:** Python · SQL Server · Power BI  
**Industry:** DTC Fashion & Apparel  
**Period:** Jan 2023 – Dec 2024  
**Records:** 18,500 orders across 3 sales channels

---

<img width="703" height="404" alt="Screenshot 2026-07-07 145648" src="https://github.com/user-attachments/assets/91c1952f-e600-43ff-b9fd-b5ebbdd6769c" />

---

## Business Problem

NovaBelle is a direct-to-consumer fashion brand selling premium apparel across Shopify, Amazon, and TikTok Shop. Despite consistent revenue growth over 24 months, profit never matched expectations. The founder needed to understand where the money was going and which business decisions were actively destroying margin.

NovaBelle brought in an analyst to answer one question: **we made $2.2M in sales — where did it go?**

---

## Key Findings

**1. Amazon is destroying margin, not building it.**  
Amazon generates 29% of NovaBelle's GMV but delivers a -6.47% contribution margin. After accounting for Amazon's 17% referral fee, FBA fulfillment costs, sponsored product spend, and a return rate amplified by Amazon's lenient returns policy, every Amazon sale costs NovaBelle more than it earns. Removing platform fees alone would recover $60K — three times more than removing ad spend ($18K), confirming the fee structure, not marketing inefficiency, is the root cause.

**2. Discounted Outerwear is NovaBelle's single biggest margin destroyer.**  
Outerwear drives 38% of GMV and receives the most ad spend. But discounted Outerwear produces -11.59% contribution margin across all customer segments. The damage is universal — High Value, Mid Value, and Low Value customers buy discounted Outerwear at the same rate (~12%). This is not a targeting problem. It is a pricing and discount policy problem that is actively funded by NovaBelle's own marketing budget.

**3. TikTok Shop is the hidden profit engine.**  
TikTok Shop generates 26% of GMV but contributes 65% of total profit at a 14.68% contribution margin. Its cost structure is fundamentally different — lower commission fees, near-zero CAC through organic content, and lower return rates. NovaBelle has been underinvesting in its most capital-efficient channel while scaling its most destructive one.

---

## Recommendations

**1. Exit or restructure Amazon operations.**  
Redirect Amazon inventory and ad spend to Shopify and TikTok Shop. A 10% GMV shift from Amazon to TikTok Shop would add approximately $18,000 to annual contribution margin without additional ad spend.

**2. Implement a discount floor policy on Outerwear immediately.**  
No discount exceeding 15% should be applied to Outerwear until COGS and return rates are reviewed and renegotiated with suppliers. Current discount depth averages 28% on a category that cannot sustain it.

**3. Scale TikTok Shop aggressively.**  
Increase content output and inventory allocation to TikTok Shop. At 14.68% CM with largely organic traffic, it is NovaBelle's most profitable growth lever with the lowest incremental cost.

---

## Dashboard Pages

| Page | Title | Audience | Key Visual |
|------|-------|----------|------------|
| 1 | Executive Summary | Founder / CEO | Margin waterfall from GMV to contribution margin |
| 2 | Product Profitability | Merchandising team | Scatter plot: GMV vs CM% revealing the Outerwear problem |
| 3 | Channel P&L | Channel manager | GMV share vs profit share gap by channel |
| 4 | Discount & Customer Analysis | Marketing / CRM team | Discounted vs full-price CM% by category |

---

## Data Architecture

The dataset was generated programmatically using Python to simulate 24 months of realistic DTC fashion brand operations. Business scenarios were engineered before data generation — seasonal demand patterns, channel-specific cost structures, return rate differentials, and discount behavior were all defined first, then the data was built to reflect them. This mirrors how a real analyst would validate a hypothesis against structured data rather than reverse-engineering a story from random numbers.

**Star Schema:**

```
fact_orders ──── dim_products
     │
     ├────────── dim_channels
     │
     ├────────── dim_customers
     │
fact_costs  ──── fact_orders
```

Raw tables were loaded directly into Power BI to preserve full filter context and enable dynamic DAX calculations across all slicers and cross-filtering interactions. SQL views were built separately as the documented analytical layer and are available in the `/sql` folder.

---

## Tools & Skills Demonstrated

| Tool | Usage |
|------|-------|
| Python | Dataset generation with engineered business scenarios using NumPy, Pandas, and Faker |
| SQL Server | Star schema design, data cleaning, profitability analysis, window functions, CTEs, and six analytical views |
| Power BI | Four-page interactive dashboard, DAX measures including SWITCH, CALCULATE, DIVIDE, MAXX, MINX, and dynamic waterfall chart |

---

## Repository Structure

```
ProfitLens/
├── README.md
├── data/
│   └── generate_data.py          # Python script to regenerate the dataset
├── sql/
│   └── profitlens_analysis.sql   # Full SQL analysis script including views
├── dashboard/
│   └── ProfitLens.pbix           # Power BI dashboard file
└── assets/
    └── dashboard_preview.png     # Dashboard screenshot for README preview
```

---

## How To Run This Project

**1. Generate the data**
```bash
pip install pandas numpy faker
python data/generate_data.py
```
This creates five CSV files in a `/novabelle_data` folder.

**2. Load into SQL Server**  
Import the five CSV files into a database called `NovaBelle` using SQL Server Management Studio. Run `sql/profitlens_analysis.sql` to create the analytical views.

**3. Open the dashboard**  
Open `dashboard/ProfitLens.pbix` in Power BI Desktop. Update the data source connection to point to your local SQL Server instance. Refresh the data.

---

## About This Project

ProfitLens is the first of three portfolio projects built to demonstrate e-commerce revenue and profitability analytics. It was designed around a real business problem — the gap between reported revenue and actual profit — that affects thousands of DTC brands operating across multiple sales channels today.

The fictional brand NovaBelle was deliberately constructed so that the data tells a commercially credible story, not a technically convenient one. Every finding in this dashboard reflects a pattern that exists in real e-commerce businesses.

---

*Built by Mustapha Ambali | E-commerce Revenue & Profitability Analyst*  
*[LinkedIn](https://linkedin.com/in/mustapha-ambali) · [Portfolio](https://mustaphaambali.github.io)*

