--===================================================
-- REPEAT CUSTOMER ANALYSIS
--=====================================================
WITH RepeatCust AS(
SELECT 
    customer_id,
    COUNT(*) total_orders
FROM cleaned_sales
GROUP BY customer_id
),
customer_group AS(
   SELECT
CASE 
    WHEN total_orders  = 1 THEN 'New Customer'
    WHEN total_orders BETWEEN 2 AND 5 THEN 'Repeat Customer'
    ELSE 'High-frequency Customer '
END Customer_Type,
COUNT(*) customers
FROM RepeatCust
GROUP BY CASE 
    WHEN total_orders  = 1 THEN 'New Customer'
    WHEN total_orders BETWEEN 2 AND 5 THEN 'Repeat Customer'
    ELSE 'High-frequency Customer '
END 
)
SELECT*
FROM customer_group;