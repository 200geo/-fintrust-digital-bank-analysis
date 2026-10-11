USE fintrust;
SELECT * FROM customers;
SELECT * FROM transactions;

-- Channel volume and risk-flag rate
SELECT
    Channel,
    COUNT(*) AS total_transactions,
    SUM(Risk_Review_Flag = 'Yes') AS flagged,
    ROUND(SUM(Risk_Review_Flag = 'Yes') * 100.0 / COUNT(*), 1) AS flag_rate_pct
FROM transactions
GROUP BY Channel
ORDER BY total_transactions DESC;
/*
Mobile App handles 43% of all transaction volume (5,102 of 12,000), 
far more than any other channel, but its risk-flag rate (19.4%) sits close to the overall average. 
Flag rates across channels are narrow (17.3%-21.3%), 
so channel alone is a weak risk signal, volume, not risk, is what sets Mobile App apart. 
*/


-- Exact median transaction value by customer segment
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
SME customers have the highest median transaction value (₦11,626.76), 
followed by Student (₦10,531.04); “Premium” ranks third (₦10,218.87), 
barely above Everyday. The Premium label does not correspond to FinTrust’s highest-value transactors. 
This is the exact version of a figure that was only approximated earlier in the project
*/

-- High-value transaction concentration
SELECT
    CASE WHEN Amount_NGN >= 100000 THEN 'High (>=100k)' ELSE 'Normal (<100k)' END AS value_tier,
    COUNT(*) AS transaction_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM transactions), 1) AS pct_of_all,
    ROUND(SUM(Amount_NGN) * 100.0 / (SELECT SUM(Amount_NGN) FROM transactions), 1) AS pct_of_total_value,
    ROUND(SUM(Risk_Review_Flag = 'Yes') * 100.0 / COUNT(*), 1) AS flag_rate_pct
FROM transactions
GROUP BY value_tier;

/*
14.4% of transactions account for 67.4% of total transaction value,
 and this tier is flagged for risk review at nearly double the rate of normal transactions (30.0% vs 17.9%). 
 A small share of activity carries most of the bank’s financial exposure.
 */
 
 
 -- International status × value tier, combined
 SELECT
    International_Transaction,
    CASE WHEN Amount_NGN >= 100000 THEN 'High (>=100k)' ELSE 'Normal (<100k)' END AS value_tier,
    COUNT(*) AS transaction_count,
    ROUND(SUM(Risk_Review_Flag = 'Yes') * 100.0 / COUNT(*), 1) AS flag_rate_pct
FROM transactions
GROUP BY International_Transaction, value_tier
ORDER BY flag_rate_pct DESC;

/*
Transactions that are both international and high-value are flagged 50.8% of the time, 
nearly triple the baseline (17.1%) and higher than either factor alone (international-only ~36.9%, 
high-value-only 30.0%). Risk factors compound, this combination is FinTrust’s sharpest, highest-concentration risk category,
 even though it’s only 0.5% of all transactions.
 */
 
 -- Transaction status vs. value
 SELECT
    Transaction_Status,
    COUNT(*) AS transaction_count,
    ROUND(AVG(Amount_NGN), 2) AS mean_amount,
    ROUND(MIN(Amount_NGN), 2) AS min_amount,
    ROUND(MAX(Amount_NGN), 2) AS max_amount
FROM transactions
GROUP BY Transaction_Status
ORDER BY mean_amount DESC;
/*
Failed transactions have a distinctly lower mean amount (₦39,406) than Successful,
Pending, or Reversed, which cluster closely together (₦47,000-49,000). 
This runs against the natural assumption that larger transactions are more prone to failure, 
the data shows the opposite.
*/

-- Preferred-channel match rate by segment
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
Across every customer segment, customers use their stated preferred channel only 46.8%-49.2% of the time,
 remarkably consistent regardless of segment. “Preferred channel” likely reflects a signup-time choice rather than ongoing behaviour,
 and should not be relied on for channel investment decisions. 
*/

SELECT
    CASE
        WHEN c.Tenure_Months < 24 THEN '1: Under 2 years'
        WHEN c.Tenure_Months < 48 THEN '2: 2-4 years'
        WHEN c.Tenure_Months < 72 THEN '3: 4-6 years'
        ELSE '4: 6+ years'
    END AS tenure_band,
    COUNT(*) AS total_transactions,
    SUM(t.Channel = c.Preferred_Channel) AS matched_preferred,
    ROUND(SUM(t.Channel = c.Preferred_Channel) * 100.0 / COUNT(*), 1) AS match_rate_pct
FROM transactions t
JOIN customers c ON t.Customer_ID = c.Customer_ID
WHERE t.Channel IN ('Mobile App', 'Web', 'USSD')
GROUP BY tenure_band
ORDER BY tenure_band;