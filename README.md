# Olist E-Commerce: Delivery Performance & Customer Satisfaction

**SQL (MySQL) · Excel · Power BI**

![Dashboard overview](dashboard/dashboard_overview.png)

## Business question
Late deliveries and low review scores may be hurting Olist. **Where exactly is the problem
(regions, sellers, categories), how much does it hurt customer satisfaction, and what should the
company do first?**

## Summary of findings
- **6.8% of delivered orders arrive late** (6,531 of 96,203). Customers with a late order gave an
  average of **2.27 stars vs. 4.29** for on-time orders, and **62.4% of them left 1-2 stars
  (vs. 9.2%)**.
- **Lateness comes in waves.** Three months (Nov 2017, Feb 2018, Mar 2018) hold about **48% of all
  late orders** while containing about 22% of orders, and every state gets worse in them.
- **Geography matters far more than sellers or product categories.** The Northeast has the highest
  late rates, even in normal months, and Rio de Janeiro (RJ) is the largest problem state after
  the peaks are taken into account.
- **The later the order, the worse the rating:** 4.29 on time, 3.29 (1-3 days late), 2.10 (4-7 days),
  1.70 (8+ days).

## Dataset
[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
(Kaggle): about 100k orders from 2016 to 2018 across 8 related tables used here (orders, order items,
customers, sellers, products, payments, reviews, category translation).
The raw CSV files are not included in this repo because of their size; download them from Kaggle.

## Tools and workflow
1. **MySQL Workbench:** bulk load, data exploration, cleaning (SQL views), and analysis
   (joins, CTEs, window functions, `CASE`).
2. **Excel:** cross-check of key results with a pivot table. Total orders, late orders, late rate,
   and every state's figures **matched the SQL results exactly**.
3. **Power BI:** interactive dashboard (KPI cards, state and month slicers, drill-down by category).

## Project structure
```
/sql         SQL scripts, run in order
/dashboard   Power BI file (.pbix) and screenshots
/excel       Excel validation workbook
README.md
```

| File | Purpose |
|---|---|
| `sql/01_setup_and_load.sql` | Creates the database and bulk-loads the CSV files |
| `sql/02_data_exploration.sql` | Explores the data and finds quality problems |
| `sql/03_cleaning.sql` | Creates the clean views used for analysis |
| `sql/04_analysis.sql` | Analysis queries, findings, and the Power BI dataset view |

## Data cleaning decisions
- **Only delivered orders** with a delivery date are used (96,203 orders after filtering).
- **Incomplete months excluded.** Order volume before Jan 2017 and after Aug 2018 is tiny, so the
  analysis covers **Jan 2017 to Aug 2018**.
- **Duplicate reviews removed.** 547 orders had more than one review; only the latest review per
  order is kept, so averages are not inflated.
- **Customers counted with `customer_unique_id`**, not `customer_id`, because a new `customer_id`
  is created for every order (99,441 IDs vs. 96,096 real customers).
- **A bug I found and fixed:** my first "late" flag compared timestamps, which marked 1,291 orders
  delivered on the promised day as late. I noticed it when two calculations of the same metric
  did not match. The fix compares calendar days, and the late rate changed from 8.1% to **6.8%**.
  Every result was re-run after the fix.
- **Extreme deliveries kept.** 295 orders (0.3%) took more than 60 days. They look like real
  service failures, not data errors.
- Raw tables are never modified; cleaning is done through SQL views.

## Key findings

### 1. Customer satisfaction drops sharply with delay
| Delivery | Avg review | Orders |
|---|---|---|
| On time | 4.29 | 89,181 |
| 1-3 days late | 3.29 | 1,851 |
| 4-7 days late | 2.10 | 1,748 |
| 8+ days late | 1.70 | 2,779 |

The 8+ days group is the largest late group. This is an association; other factors can also
affect ratings.

### 2. Lateness is concentrated in three peak months
Late rate is about 3-7% in most months, but **Nov 2017 (12.4%), Feb 2018 (14.1%), and Mar 2018
(19.0%)** stand out. Together they hold 3,158 late orders (about 48% of the total).
- In Nov 2017 average delivery time rose from 11.7 to 15.1 days while the promised time stayed
  about the same, and order volume peaked (7,288 orders).
- Feb and Mar 2018 had slow deliveries without higher volume than January, so volume alone does
  not explain them. The data cannot tell why.
- In **every state**, the late rate is higher in these months than in the others.

### 3. Where: two different geographic problems
- **Volume problem:** SP (1,817 late orders) and RJ (1,495) account for about 51% of all late orders;
  the top 5 states (SP, RJ, MG, BA, RS) about 70%.
- **RJ:** 12.1% late versus 4.5% for SP and 4.6% for MG, even though RJ borders both. About 58% of
  RJ's late orders fall in the three peak months (31.2% late in those months vs. 6.6% in the
  others). RJ deliveries take 16.2 days on average versus 12.3 for MG, with a promise only 2.1 days
  longer.
- **Northeast:** highest late rates (AL 21.5%, MA 17.5%, SE 15.4%, PI 13.9%, CE 13.8%, BA 12.2%).
  Even outside the peak months, the Northeast sits around 7-10% late versus 2-4% in the South and
  Southeast.
- **Cross-state orders** are late 8.1% of the time versus 4.5% for same-state orders.

### 3. Sellers and product categories are not the main driver
- The 15 worst sellers (with 100+ orders) account for only about 6.6% of all late orders.
- The 10 highest late rates by category range from 7.3% to 8.1%, close to the 6.8% overall.

## Recommendations (in priority order)

**1. Plan capacity for peak periods.**
*Evidence:* three months hold ~48% of late orders, and all states are hit.
*Action:* agree extra carrier capacity before known peaks (e.g. Black Friday), monitor late rate
weekly during peaks, and set an alert threshold that triggers extra support.

**2. Fix delivery into Rio de Janeiro first.**
*Evidence:* second-largest source of late orders, slower than neighbouring MG, and the promise is
short relative to similar states.
*Action:* review carriers and hubs serving RJ, and re-check the delivery estimate shown to RJ
customers. *Rough estimate:* if RJ matched SP's late rate (4.5%), there would be about 940 fewer
late orders (12,310 × (12.1% − 4.5%)), roughly 14% of all late orders.

**3. Address the Northeast structurally.**
*Evidence:* high late rates even outside peaks, and cross-state orders are late almost twice as often.
*Action:* test longer, more realistic delivery promises on long routes, and explore carrier options
or seller/fulfilment presence closer to the Northeast. *Trade-off:* longer promises can reduce
conversion, so test before rolling out.

**4. Act early on orders heading for a long delay.**
*Evidence:* satisfaction collapses at 4+ days late (2.10 and 1.70 stars) and 62.4% of customers
with a late order leave 1-2 stars.
*Action:* flag orders at risk, send proactive updates, and offer support or compensation before the
customer complains. Track whether the share of 1-2 star reviews among late orders falls.

**5. Do not prioritize individual sellers or product categories for delivery problems.**
*Evidence:* the worst 15 sellers cause ~6.6% of late orders and categories barely differ.
*Action:* focus effort on regions, carriers, and peak planning instead.

## Limitations
- **Association, not proof of cause.** Late deliveries and low ratings move together, but other
  factors also affect reviews.
- **Cost is measured in customer satisfaction, not money.** Revenue lost to late orders was not analyzed.
- **Only delivered orders are included.** Orders still in transit when the data was collected are
  missing, so the last months (Jun-Aug 2018) may look better than they really were.
- **Power BI category and seller fields use the first item of each order.** For orders with several
  items this is an approximation; the SQL queries count orders exactly.
- Data covers 2017-2018 only, so patterns may have changed since.


## Author
Mohab Adel · [GitHub](https://github.com/mohabadel10)
