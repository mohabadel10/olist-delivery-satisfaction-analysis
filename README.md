# Olist E-Commerce: Delivery Performance & Customer Satisfaction

## Business question
Late deliveries and low review scores may be hurting Olist. **Where exactly is the problem
(regions, sellers, categories), what does it cost, and what should the company do first?**

## Dataset
[Brazilian E-Commerce Public Dataset by Olist](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
(Kaggle): about 100k orders from 2016 to 2018 across several related tables
(orders, items, customers, sellers, products, payments, reviews).
The raw CSV files are not included in this repo because of their size; download them from Kaggle.

## Tools
- **MySQL Workbench**: data loading, cleaning, and analysis (SQL)
- **Excel**: validation of key results
- **Power BI**: interactive dashboard

## Project structure
```
/sql         SQL scripts, in the order they should be run
/dashboard   Power BI file and screenshots
/report      Final report with recommendations
README.md
```

| File | Purpose |
|---|---|
| `sql/01_setup_and_load.sql` | Creates the database and bulk-loads the CSV files |
| `sql/02_data_exploration.sql` | Explores the data and finds quality problems |
| `sql/03_cleaning.sql` | Creates the clean views used for analysis |
| `sql/04_analysis.sql` | Analysis queries answering the business question |

## Data cleaning decisions
- **Only delivered orders** with a delivery date are used for delivery analysis (96,203 orders after filtering).
- **Incomplete months excluded.** Order volume before Jan 2017 and after Aug 2018 is tiny and
  incomplete, so the analysis covers Jan 2017 to Aug 2018 only.
- **Duplicate reviews removed.** 547 orders had more than one review; only the latest review
  per order is kept, so averages are not inflated.
- **Customers counted with `customer_unique_id`**, not `customer_id`, since a new `customer_id`
  is created for every order (99,441 IDs vs. 96,096 real customers).
- **Extreme deliveries kept.** 295 orders (0.3%) took more than 60 days. They look like real
  service failures, not data errors, so they stay in the analysis.
- Raw tables are never modified; cleaning is done through SQL views.

## Key findings
*In progress. Findings, dashboard, and recommendations will be added as the project is completed.*

## Status
- [x] Data loaded into MySQL
- [x] Data exploration
- [x] Data cleaning
- [ ] Delivery and satisfaction analysis
- [ ] Seller and category analysis
- [ ] Excel validation
- [ ] Power BI dashboard
- [ ] Final report with recommendations
