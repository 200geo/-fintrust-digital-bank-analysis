# FinTrust Digital Bank — Business & Data Intelligence Analysis

**Programme:** AnalystLab Africa Experience Lab Internship (Data Analytics Track)
**Author:** George Collins Oluoch
**Tools:** Python (Pandas, NumPy, Matplotlib, Seaborn), SQL (MySQL), Power BI, Google Sheets/Excel

> All customers, transactions, and labels in this project are **synthetic**, created for educational purposes. `Risk_Review_Flag` is a synthetic educational target and is **not** a real fraud determination.

## Project Overview

FinTrust Digital Bank is a fictional digital bank used as the business scenario for a 4-week multidisciplinary data and AI internship. This repository holds the Data Analytics track's work: understanding the business problem, profiling and cleaning the data, answering business questions in SQL and Python, building a Power BI dashboard, and validating findings into management recommendations.

**Business problem:** FinTrust has growing volumes of customer and transaction data but lacks visibility into customer behaviour, transaction patterns, and risk-review indicators needed to support operational decisions and digital customer support.

## Key Findings

- **Risk factors compound.** Transactions that are both international and high-value (≥₦100,000) are flagged for risk review 50.8% of the time, nearly triple the baseline rate (17.1%), and well above either factor alone.
- **Transaction value is sharply concentrated.** Just 14.4% of transactions account for 67.4% of total transaction value.
- **The "Premium" customer segment does not have the highest transaction value.** SME and Student customers show higher median transaction values than Premium.
- **Digital engagement score does not predict transaction behaviour.** Tested four independent ways, all showing no relationship.
- **Customers often don't use their stated preferred channel.** Actual usage matches stated preference only ~47-49% of the time across all customer segments.

## Repository Structure


## Week-by-Week Summary

| Week | Focus | Key Deliverables |
|---|---|---|
| 1 | Understand & Plan | Business understanding, data profiling report, 8 analytical questions, KPI table, dashboard wireframe |
| 2 | Analyse & Prepare | Data quality workbook, SQL queries, Python visualisations, Power BI dashboard, business findings |
| 3 | Develop & Integrate | Advanced SQL/Python analysis, expanded dashboard, validated findings, management recommendations |
| 4 | Test, Refine & Present | Final SQL, final business insights & recommendations, final validation, recorded presentation |

## How to Explore This Repository

- **SQL:** open the `.sql` files in any MySQL-compatible client, or read them directly.
- **Python:** open the `.ipynb` notebooks in Jupyter or view them directly on GitHub.
- **Power BI:** open the `.pbix` files in Power BI Desktop (free), or view the static screenshots in `week4/`.

## Data Dictionary (summary)

| Table | Rows | Description |
|---|---|---|
| Customers | 1,500 | Customer demographics, segment, account type, engagement score, preferred channel |
| Transactions | 12,000 | Transaction-level data: type, amount, channel, status, international flag, risk-review flag |