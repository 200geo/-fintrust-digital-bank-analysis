-- Creating The DataBase and Loading Both Customers and Transaction Data
CREATE DATABASE fintrust;
USE fintrust;

CREATE TABLE customers (
    Customer_ID VARCHAR(20),
    Customer_Name VARCHAR(100),
    Age INT,
    Gender VARCHAR(20),
    City VARCHAR(30),
    Customer_Segment VARCHAR(20),
    Account_Type VARCHAR(20),
    Tenure_Months INT,
    Digital_Engagement_Score DECIMAL(5,1),
    Monthly_Income_Band VARCHAR(20),
    Preferred_Channel VARCHAR(20),
    Account_Status VARCHAR(20)
);

CREATE TABLE transactions (
    Transaction_ID VARCHAR(20),
    Customer_ID VARCHAR(20),
    Transaction_DateTime VARCHAR(30),
    Transaction_Type VARCHAR(30),
    Amount_NGN DECIMAL(12,2),
    Channel VARCHAR(20),
    Device_Type VARCHAR(20),
    Location VARCHAR(30),
    International_Transaction VARCHAR(5),
    Transaction_Status VARCHAR(20),
    Risk_Review_Flag VARCHAR(5)
);

-- Confirming Data Loaded Successfully
SELECT * FROM customers;
SELECT COUNT(*) FROM customers;

SELECT * FROM transactions;
SELECT COUNT(*) FROM transactions;

ALTER TABLE transactions ADD COLUMN Transaction_Date_Clean DATETIME;

SET SQL_SAFE_UPDATES = 0;

UPDATE transactions
SET Transaction_Date_Clean = STR_TO_DATE(Transaction_DateTime, '%c/%e/%Y %H:%i');

SET SQL_SAFE_UPDATES = 1;

SELECT MIN(Transaction_Date_Clean), MAX(Transaction_Date_Clean) FROM transactions;
SELECT COUNT(*) FROM transactions WHERE Transaction_Date_Clean IS NULL;

SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM transactions;
SELECT COUNT(DISTINCT Transaction_ID) FROM transactions;
DESCRIBE transactions;


-- FinTrust Week 2: SQL Business Analysis
-- Data: cleaned FinTrust customer and transaction data (MySQL, database: fintrust)
-- Date column: Transaction_Date_Clean (converted from text with STR_TO_DATE)
-- Note: Risk_Review_Flag is synthetic and is not a real fraud determination.

-- Question 1: Which channels handle the most transactions, and what share of
-- each channel's transactions is flagged for risk review?

SELECT
    Channel,
    COUNT(*) AS total_transactions,
    SUM(Risk_Review_Flag = 'Yes') AS flagged,
    ROUND(SUM(Risk_Review_Flag = 'Yes') * 100.0 / COUNT(*), 1) AS flag_rate_pct
FROM transactions
GROUP BY Channel
ORDER BY total_transactions DESC;

/*
Business Interpretation:
Mobile App carries the highest transaction volume by a wide margin (43% of all
transactions), consistent with the Part C finding. However, its risk-review
flag rate (19.4%) is close to the overall average, not notably high or low.
Web and ATM have the highest flag rates (21.3% and 21.2%), while USSD has the
lowest (17.3%). The spread across channels (17.3% to 21.3%) is much narrower
than the international-vs-domestic split found in Part C (18.9% vs 36.9%),
suggesting channel alone is a weak signal for risk review compared to
international status. This tells the risk team that flagged transactions are
not concentrated in one channel, review resources should be spread across
channels rather than focused on a single one.
*/

-- Question 2: How does typical transaction value (median and mean) differ
-- across customer segments?

WITH ranked AS (
    SELECT
        c.Customer_Segment,
        t.Amount_NGN,
        PERCENT_RANK() OVER (
            PARTITION BY c.Customer_Segment
            ORDER BY t.Amount_NGN
        ) AS pr
    FROM transactions t
    JOIN customers c ON t.Customer_ID = c.Customer_ID
)
SELECT
    Customer_Segment,
    COUNT(*) AS total_transactions,
    ROUND(AVG(Amount_NGN), 2) AS mean_amount,
    ROUND(AVG(CASE WHEN pr BETWEEN 0.49 AND 0.51 THEN Amount_NGN END), 2) AS approx_median
FROM ranked
GROUP BY Customer_Segment
ORDER BY mean_amount DESC;

/*
Business Interpretation:
SME customers have the highest typical transaction value by both measures,
consistent with business-related transactions tending to be larger. Premium
customers rank third by median value, below both SME and Student, confirming
the Part C finding that the "Premium" label does not correspond to the
highest transaction amounts. This suggests Premium status reflects a
different criterion (tenure, income band, or engagement) rather than
transaction size, a distinction product and marketing teams should be aware
of when targeting "high value" customers by segment label alone.
*/

-- Question 3: Which transaction types are most common, and which contribute
-- the most total value?

SELECT
    Transaction_Type,
    COUNT(*) AS total_transactions,
    SUM(Amount_NGN) AS total_value,
    ROUND(AVG(Amount_NGN), 2) AS mean_amount
FROM transactions
GROUP BY Transaction_Type
ORDER BY total_transactions DESC;

/*
Business Interpretation:
Transfer is the busiest transaction type by volume and also generates the
most total value (NGN 237.9m), making it FinTrust's most significant
transaction type in both dimensions. Deposit is a notable exception to the
volume-value relationship: despite having the second-lowest transaction
count, it has by far the highest average transaction size (NGN 98,633) and
the second-highest total value (NGN 130.99m). This means monitoring or
capacity planning based on transaction count alone would understate the
financial significance of deposits. Airtime/Data, by contrast, is
high-frequency but low-value, consistent with routine small top-ups, and
represents minimal financial exposure despite steady volume.
*/

-- Question 4: How does transaction volume vary by month, day of week, and
-- hour of day?

SELECT MONTH(Transaction_Date_Clean) AS month_num, COUNT(*) AS total_transactions
FROM transactions GROUP BY month_num ORDER BY month_num;

SELECT DAYNAME(Transaction_Date_Clean) AS day_of_week, COUNT(*) AS total_transactions
FROM transactions GROUP BY day_of_week ORDER BY total_transactions DESC;

SELECT HOUR(Transaction_Date_Clean) AS hour_of_day, COUNT(*) AS total_transactions
FROM transactions GROUP BY hour_of_day ORDER BY hour_of_day;

/*
Business Interpretation:
Transaction volume shows no meaningful time-based pattern in this dataset.
Monthly counts track the number of days in each month exactly, weekday
volumes are within a narrow band with no weekend or weekday effect, and hour-
of-day volume is perfectly uniform at 500 transactions per hour, every hour,
including overnight. This uniformity does not reflect real banking behaviour,
where activity would concentrate in daytime and business hours, and indicates
the data was generated evenly across the three-month window rather than
modelling genuine usage patterns. As a result, FinTrust should not use this
dataset to inform time-based decisions such as staffing or system-capacity
planning by hour or day; any such planning would need real transaction
timestamps. This is a limitation of the synthetic dataset, not a finding
about FinTrust's actual customers.
*/

-- Question 5: What share of transactions are failed, reversed, or pending,
-- and does this differ by channel or transaction type?

-- By channel
SELECT Channel, COUNT(*) AS total_transactions,
    SUM(Transaction_Status = 'Successful') AS successful,
    SUM(Transaction_Status = 'Failed') AS failed,
    SUM(Transaction_Status = 'Reversed') AS reversed,
    SUM(Transaction_Status = 'Pending') AS pending,
    ROUND(SUM(Transaction_Status <> 'Successful') * 100.0 / COUNT(*), 1) AS non_success_rate_pct
FROM transactions GROUP BY Channel ORDER BY non_success_rate_pct DESC;

-- By transaction type
SELECT Transaction_Type, COUNT(*) AS total_transactions,
    SUM(Transaction_Status = 'Successful') AS successful,
    SUM(Transaction_Status = 'Failed') AS failed,
    SUM(Transaction_Status = 'Reversed') AS reversed,
    SUM(Transaction_Status = 'Pending') AS pending,
    ROUND(SUM(Transaction_Status <> 'Successful') * 100.0 / COUNT(*), 1) AS non_success_rate_pct
FROM transactions GROUP BY Transaction_Type ORDER BY non_success_rate_pct DESC;

/*
Business Interpretation:
Non-success rates are narrow and consistent across both channels (8.3% to
10.3%) and transaction types (8.8% to 10.5%), with no single channel or type
standing out as a major driver of failures, reversals, or pending
transactions. This is a materially different picture from risk-review
flagging (Question 1 and Part C), where international status produced a
sharp difference (18.9% vs 36.9%); here, no comparable outlier exists.
Because Mobile App carries the highest volume, it still generates the largest
absolute number of non-successful transactions and remains the priority for
support effort in practical terms, but this is a volume effect, not evidence
that Mobile App itself is less reliable per transaction. FinTrust's
transaction failure and reversal issues appear to be spread evenly across the
business rather than concentrated in a fixable weak point.
*/

-- Question 6: Do transactions flagged for risk review differ from unflagged
-- ones in amount and in international status?

SELECT
    Risk_Review_Flag,
    COUNT(*) AS total_transactions,
    ROUND(AVG(Amount_NGN), 2) AS mean_amount,
    SUM(International_Transaction = 'Yes') AS international_count,
    ROUND(SUM(International_Transaction = 'Yes') * 100.0 / COUNT(*), 1) AS international_pct
FROM transactions
GROUP BY Risk_Review_Flag;

/*
Business Interpretation:
Flagged transactions have a notably higher mean amount (NGN 68,786 vs
NGN 41,324, about 66% higher), a larger gap than the median comparison found
in Part C (NGN 13,541 vs NGN 9,591), because the mean is more sensitive to a
small number of very large flagged transactions. Flagged transactions are
also more than twice as likely to be international (7.5% vs 3.1%), confirming
the strong link found in Part C. However, the majority of flagged
transactions (92.5%) are still domestic, so international status alone would
miss most flagged activity if used as a sole screening rule. Amount and
international status both move in the same direction as the flag, but
neither is a clean dividing line on its own, supporting the view that
FinTrust's risk-review process combines multiple factors rather than relying
on any single one.
*/

-- Question 7: Do customers with higher digital engagement scores transact more often, or use different channels?
SELECT
    c.Customer_ID,
    c.Digital_Engagement_Score,
    COUNT(t.Transaction_ID) AS transaction_count
FROM customers c
LEFT JOIN transactions t ON c.Customer_ID = t.Customer_ID
GROUP BY c.Customer_ID, c.Digital_Engagement_Score;


SELECT
    CASE
        WHEN Digital_Engagement_Score < 30 THEN '1: Below 30'
        WHEN Digital_Engagement_Score < 50 THEN '2: 30-49'
        WHEN Digital_Engagement_Score < 70 THEN '3: 50-69'
        ELSE '4: 70+'
    END AS engagement_band,
    COUNT(*) AS num_customers,
    ROUND(AVG(transaction_count), 2) AS avg_transactions_per_customer
FROM (
    SELECT c.Customer_ID, c.Digital_Engagement_Score, COUNT(t.Transaction_ID) AS transaction_count
    FROM customers c
    LEFT JOIN transactions t ON c.Customer_ID = t.Customer_ID
    GROUP BY c.Customer_ID, c.Digital_Engagement_Score
) AS per_customer
GROUP BY engagement_band
ORDER BY engagement_band;

/*
Business Interpretation:
Digital engagement score shows no meaningful relationship with how often a
customer transacts. Average transactions per customer are nearly identical
across all four engagement bands (7.85 to 8.05), with no upward trend from
low to high engagement. This suggests Digital_Engagement_Score, as currently
defined, measures something other than transaction frequency, possibly app
usage or session activity rather than banking activity itself. FinTrust
should not assume that customers scored as highly "engaged" are its most
active transactors; if engagement is meant to correlate with value or
activity, this finding suggests the score's definition or calculation may
need review with the team that produces it.
*/

-- Question 8: What share of customers' transactions go through their stated preferred channel, and does it differ by segment?
-- Note: filtered to Mobile App, Web, and USSD transactions only, since POS and ATM cannot match a stated preferred channel (customers can only select Mobile App, Web, or USSD as their preference).

SELECT
    c.Customer_Segment,
    COUNT(*) AS total_transactions,
    SUM(t.Channel = c.Preferred_Channel) AS matched_preferred,
    ROUND(SUM(t.Channel = c.Preferred_Channel) * 100.0 / COUNT(*), 1) AS match_rate_pct
FROM transactions t
JOIN customers c ON t.Customer_ID = c.Customer_ID
WHERE t.Channel IN ('Mobile App', 'Web', 'USSD')
GROUP BY c.Customer_Segment
ORDER BY match_rate_pct DESC;

/*
Business Interpretation:
Across all segments, customers use their stated preferred channel for
roughly 47-49% of eligible transactions, meaning slightly over half the time
customers transact through a channel other than the one they named as
preferred. The gap between segments is small (SME highest at 49.2%, Everyday
lowest at 46.8%), so this is a consistent pattern across the customer base
rather than a segment-specific issue. This suggests "preferred channel," as
currently captured, may reflect an initial signup choice rather than ongoing
behaviour, and should not be relied on alone to predict which channel a
customer will actually use. For channel investment decisions, actual usage
data (Question 1's channel volumes) is a more reliable guide than stated
preference.
*/


-- Advanced Query 1: Exact median transaction value by customer segment
-- (closes Week 3 Gap #1: Week 2's PERCENT_RANK median was an approximation)

WITH numbered AS (
    SELECT
        c.Customer_Segment,
        t.Amount_NGN,
        ROW_NUMBER() OVER (PARTITION BY c.Customer_Segment ORDER BY t.Amount_NGN) AS rn,
        COUNT(*) OVER (PARTITION BY c.Customer_Segment) AS total_rows
    FROM transactions t
    JOIN customers c ON t.Customer_ID = c.Customer_ID
)
SELECT
    Customer_Segment,
    ROUND(AVG(Amount_NGN), 2) AS exact_median
FROM numbered
WHERE rn IN (FLOOR((total_rows + 1) / 2), FLOOR((total_rows + 2) / 2))
GROUP BY Customer_Segment
ORDER BY exact_median DESC;

/*
Validation note: Week 2's PERCENT_RANK approximation was within NGN 15-78 of
the exact median for every segment (under 1% in each case), and the ranking
of segments (SME > Student > Premium > Everyday) is unchanged. The
approximation was directionally reliable but not numerically exact; this
query provides the precise figures.
*/

-- Advanced Query 2: Does tenure predict transaction frequency?
-- (Gap #2: testing a second variable against the same question engagement
-- score failed to answer in Week 2)

SELECT
    CASE
        WHEN c.Tenure_Months < 24 THEN '1: Under 2 years'
        WHEN c.Tenure_Months < 48 THEN '2: 2-4 years'
        WHEN c.Tenure_Months < 72 THEN '3: 4-6 years'
        ELSE '4: 6+ years'
    END AS tenure_band,
    COUNT(DISTINCT c.Customer_ID) AS num_customers,
    COUNT(t.Transaction_ID) AS total_transactions,
    ROUND(COUNT(t.Transaction_ID) * 1.0 / COUNT(DISTINCT c.Customer_ID), 2) AS avg_transactions_per_customer
FROM customers c
LEFT JOIN transactions t ON c.Customer_ID = t.Customer_ID
GROUP BY tenure_band
ORDER BY tenure_band;

/*
Validation note: Tenure, like engagement score (Week 2), shows no
relationship with transaction frequency (7.90-8.15 across all bands). Two
independent customer attributes both fail to predict activity, suggesting
transaction frequency in this dataset is not driven by customer
characteristics captured here. This strengthens rather than weakens the
original Week 2 conclusion.
*/


-- Advanced Query 3: Does digital engagement score predict channel choice
-- (rather than transaction frequency)?
-- Gap #2: a second angle on the same "flat" variable from Week 2.

SELECT
    engagement_band,
    Channel,
    transaction_count,
    ROUND(transaction_count * 100.0 / SUM(transaction_count) OVER (PARTITION BY engagement_band), 1) AS pct_within_band
FROM (
    SELECT
        CASE
            WHEN c.Digital_Engagement_Score < 30 THEN '1: Below 30'
            WHEN c.Digital_Engagement_Score < 50 THEN '2: 30-49'
            WHEN c.Digital_Engagement_Score < 70 THEN '3: 50-69'
            ELSE '4: 70+'
        END AS engagement_band,
        t.Channel,
        COUNT(*) AS transaction_count
    FROM customers c
    JOIN transactions t ON c.Customer_ID = t.Customer_ID
    GROUP BY engagement_band, t.Channel
) AS banded
ORDER BY engagement_band, pct_within_band DESC;

/*
Validation note: Channel mix is also flat across engagement bands (Mobile
App 39.5-42.8%, USSD 7.2-7.9% everywhere). Combined with Query 2 (tenure) and
Week 2 (engagement vs frequency), this is the third independent test to find
no relationship. Digital_Engagement_Score appears unrelated to both how often
and how customers transact, strengthening the Week 2 conclusion that this
field likely measures something other than banking behaviour (e.g., app
session activity).
*/


-- Advanced Query 4: Does the (flat) day-of-week pattern hold within each
-- customer segment, or does segment-level behaviour differ?
-- Gap #3: testing a second dimension on top of the Week 2 time analysis.

SELECT
    Customer_Segment, day_of_week, transaction_count,
    ROUND(transaction_count * 100.0 / SUM(transaction_count) OVER (PARTITION BY Customer_Segment), 1) AS pct_within_segment
FROM (
    SELECT c.Customer_Segment, DAYNAME(t.Transaction_Date_Clean) AS day_of_week, COUNT(*) AS transaction_count
    FROM transactions t JOIN customers c ON t.Customer_ID = c.Customer_ID
    GROUP BY c.Customer_Segment, day_of_week
) AS daily
ORDER BY Customer_Segment,
    CASE day_of_week WHEN 'Monday' THEN 1 WHEN 'Tuesday' THEN 2 WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 WHEN 'Saturday' THEN 6 ELSE 7 END;

/*
Validation note: No segment shows a genuine weekday/weekend split; all four
stay within a roughly 3-4 percentage-point band across all seven days. SME
and Student show the widest spreads, but they also have the smallest sample
sizes, consistent with ordinary sampling variation rather than a real
behavioural difference. This confirms, at a finer level of detail, that the
Week 2 "no meaningful time pattern" finding holds even when segment is
introduced as a second dimension.
*/


-- Advanced Query 5: High-value transaction patterns
-- Uses a subquery to compare each value tier against grand totals.

SELECT
    CASE WHEN Amount_NGN >= 100000 THEN 'High (>=100k)' ELSE 'Normal (<100k)' END AS value_tier,
    COUNT(*) AS transaction_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM transactions), 1) AS pct_of_all,
    ROUND(SUM(Amount_NGN) * 100.0 / (SELECT SUM(Amount_NGN) FROM transactions), 1) AS pct_of_total_value,
    ROUND(SUM(Risk_Review_Flag = 'Yes') * 100.0 / COUNT(*), 1) AS flag_rate_pct
FROM transactions
GROUP BY value_tier;

/*
Validation note: High-value transactions (>=NGN 100,000) are only 14.4% of
volume but 67.4% of total value, a strong concentration. They are also
flagged for risk review nearly twice as often (30.0% vs 17.9%). This is a
sharper, more decision-relevant signal than channel or transaction status,
comparable in strength to the international-transaction finding from Week 2,
and a strong candidate for a priority monitoring rule.
*/

-- Advanced Query 6: Do international status and high value compound as risk
-- signals when combined? Addresses Gap #4 (dashboard's one-factor-at-a-time
-- risk view).

SELECT
    International_Transaction,
    CASE WHEN Amount_NGN >= 100000 THEN 'High (>=100k)' ELSE 'Normal (<100k)' END AS value_tier,
    COUNT(*) AS transaction_count,
    ROUND(SUM(Risk_Review_Flag = 'Yes') * 100.0 / COUNT(*), 1) AS flag_rate_pct
FROM transactions
GROUP BY International_Transaction, value_tier
ORDER BY flag_rate_pct DESC;

/*
Validation note: International status and high transaction value compound.
Transactions that are both international and high-value are flagged 50.8% of
the time, more than double the baseline (17.1%) and higher than either factor
alone (international-only ~36.9%, high-value-only 30.0%). This combination,
though rare (63 of 12,000 transactions, 0.5%), represents FinTrust's highest-
concentration risk segment and should be a priority monitoring category,
directly addressing the Week 3 gap that Week 2's dashboard only showed single
risk factors in isolation.
*/


-- Advanced Query 7: Customer-level transaction frequency distribution
-- (Week 2 only reported the average of 8.0; this shows the actual spread)

WITH customer_counts AS (
    SELECT c.Customer_ID, COUNT(t.Transaction_ID) AS transaction_count
    FROM customers c LEFT JOIN transactions t ON c.Customer_ID = t.Customer_ID
    GROUP BY c.Customer_ID
)
SELECT
    CASE
        WHEN transaction_count <= 4 THEN '1: Low (1-4)'
        WHEN transaction_count <= 8 THEN '2: Medium (5-8)'
        WHEN transaction_count <= 12 THEN '3: High (9-12)'
        ELSE '4: Very High (13+)'
    END AS frequency_band,
    COUNT(*) AS num_customers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers), 1) AS pct_of_customers,
    SUM(transaction_count) AS total_transactions,
    ROUND(SUM(transaction_count) * 100.0 / (SELECT COUNT(*) FROM transactions), 1) AS pct_of_transactions
FROM customer_counts
GROUP BY frequency_band
ORDER BY frequency_band;

/*
Validation note: Unlike transaction value (Query 5), customer activity is
fairly evenly spread: each frequency band's share of transactions is close
to its share of customers (e.g., 35.5% of customers generate 44.9% of
transactions, not a sharp concentration). This means FinTrust's transaction
volume is not dominated by a small group of hyperactive customers, in
contrast to how transaction value is dominated by a small group of
high-value transactions.
*/

-- Advanced Query 8: Does transaction status relate to transaction value?
-- (Week 2 looked at failure rates by channel/type; this checks value)

SELECT
    Transaction_Status, COUNT(*) AS transaction_count,
    ROUND(AVG(Amount_NGN), 2) AS mean_amount,
    ROUND(MIN(Amount_NGN), 2) AS min_amount,
    ROUND(MAX(Amount_NGN), 2) AS max_amount
FROM transactions
GROUP BY Transaction_Status
ORDER BY mean_amount DESC;

/*
Validation note: Failed transactions have a distinctly lower mean amount
(NGN 39,406) than the other three statuses, which cluster closely together
(NGN 47,000-49,000). This runs counter to a natural assumption that larger
transactions might be more prone to failure; the data shows the opposite,
failures skew toward smaller amounts. This is worth sharing with the ML
Engineering track, since it may reflect a technical limit or check
disproportionately affecting smaller transactions.
*/