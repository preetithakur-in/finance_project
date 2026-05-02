 -------- table1 - stocks -------- 
SELECT
    COUNT(*) AS total_rows, 
	COUNT(*) FILTER (WHERE price IS NULL) AS null_price,
	COUNT(*) FILTER (WHERE pe_ratio IS NULL) AS null_ratio,
	COUNT(*) FILTER (WHERE dividend_yield is NULL) null_dividend
FROM stocks;

SELECT ticker, company_name, sector, price
FROM stocks
WHERE price IS NULL;

UPDATE stocks s 
SET price = (
      SELECT ROUND(AVG(s2.price), 2)
	  FROM stocks s2 
	  WHERE s2.sector = s.sector
	  AND s2.price IS NOT NULL
)
WHERE price IS NULL;

UPDATE stocks s
SET pe_ratio = (
   SELECT ROUND(AVG(s2.pe_ratio), 2)
   FROM stocks s2
   WHERE s2.sector = s.sector
   AND s2.pe_ratio IS NOT NULL
)
WHERE pe_ratio IS NULL;


SELECT * FROM stocks WHERE price IS NULL OR pe_ratio IS NULL;
--- should return 0 rows!


 -------- table2 - clients -------- 
SELECT
    COUNT(*) AS total_rows, 
	COUNT(*) FILTER (WHERE client_name IS NULL) AS null_name,
	COUNT(*) FILTER (WHERE email IS NULL) AS null_email,
	COUNT(*) FILTER (WHERE phone is NULL) null_phone
FROM clients;


SELECT client_id, client_name, email
FROM clients
WHERE client_name IS NULL;

UPDATE clients
SET client_name = INITCAP(SPLIT_PART(email, '@', 1))
WHERE client_name IS NULL;

UPDATE clients
SET email = LOWER(REPLACE(client_name, ' ', '.'))
       || '@unknown.com'
WHERE email IS NULL;

UPDATE clients
SET phone = 'N/A'
WHERE phone IS NULL;

SELECT * FROM clients
WHERE client_name IS NULL
OR email IS NULL
OR phone IS NULL;


 -------- table3 - transaction -------- 
SELECT
   COUNT(*) AS total_rows,
   COUNT(*) FILTER (WHERE shares IS NULL) AS null_shares,
   COUNT(*) FILTER (WHERE price IS NULL) AS null_price
FROM transaction;


SELECT t.transaction_id, t.ticker, t.price
FROM transaction t
WHERE t.price IS NULL;

UPDATE transaction t
SET price = (
       SELECT s.price
	   FROM stocks s
	   WHERE s.ticker = t.ticker
)
WHERE price IS NULL;

UPDATE transaction t
SET price = (
       SELECT s.price
	   FROM stocks s
	   WHERE s.ticker = t.ticker
)
WHERE price IS NULL;

UPDATE transaction t
SET shares = (
       SELECT ROUND(AVG(t2.shares))
	   FROM transaction t2
	   WHERE t2.ticker = t.ticker
	   AND t2.shares IS NOT NULL
)
WHERE shares IS NULL;

SELECT * FROM transaction
WHERE shares IS NULL OR price IS NULL;

---- ticker = 'BMY', AVG() can't work because there are no other BMY transactions to average from! ------

UPDATE transaction
SET shares = (
      SELECT ROUND(AVG(shares))
	  FROM transaction
	  WHERE shares IS NOT NULL
)
WHERE ticker = 'BMY';


------ Complete data quality report ------
SELECT 'stocks'   AS table_name, 
          COUNT(*) AS total_rows,
		  COUNT(*) FILTER (WHERE price IS NULL) AS nulls
FROM stocks

UNION ALL

SELECT 'clients'   AS table_name, 
          COUNT(*),
		  COUNT(*) FILTER (WHERE email IS NULL) 
FROM clients

UNION ALL

SELECT 'transaction'   AS table_name, 
          COUNT(*) AS total_rows,
		  COUNT(*) FILTER (WHERE price IS NULL)
FROM transaction;

--- 1. Total portfolio value per client
SELECT 
    c.client_name,
	COUNT(t.transaction_id) AS total_trades,
	SUM(t.shares * t.price) AS total_invested
FROM clients c
JOIN transaction t ON c.client_id = t.client_id
GROUP BY c.client_name
ORDER BY total_invested DESC;

--- 2. most traded stocks
SELECT 
    ticker,
	COUNT(*) AS total_trades,
	SUM(shares) AS total_shares
FROM transaction
GROUP BY ticker
ORDER BY total_trades DESC
LIMIT 10;

---- 3. sector breakdown
SELECT
    s.sector,
	COUNT(t.transaction_id) as trades,
	sum(t.shares * t.price) AS total_value
from transaction t
join stocks s on t.ticker = s.ticker
group by s.sector
order by total_value desc;
	







