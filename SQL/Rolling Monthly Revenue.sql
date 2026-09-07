--=========================================================
-- ROLLING MONTHLY REVENUE
--=========================================================

WITH MonthlySales AS(
SELECT
    DATEFROMPARTS(YEAR(order_date),MONTH(order_date),1) sales_month,
    COUNT(*) AS total_orders,
    SUM(quantity) AS units_sold,
    ROUND(SUM(net_amount),2) AS net_revenue,
    ROUND(AVG(net_amount),2) AS average_order_value
FROM cleaned_sales
WHERE order_date IS NOT NULL
GROUP BY DATEFROMPARTS(YEAR(order_date),MONTH(order_date),1)
),
PreviousMonth AS(
SELECT*,
    ROUND(LAG(net_revenue)OVER(ORDER BY sales_month),2) Previous_Month_Revenue
FROM MonthlySales
),
Rev_change AS(
SELECT *,
    ROUND(net_revenue - Previous_Month_Revenue,2) AS Revenue_MoM
FROM PreviousMonth
)
SELECT*,
CASE 
	WHEN net_revenue > Previous_Month_Revenue THEN 'Increase'
	WHEN net_revenue < Previous_Month_Revenue THEN 'Decrease'
	ELSE 'No Change'
END Growth_indicator
FROM Rev_change;