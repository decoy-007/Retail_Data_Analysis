--============================================================
--ROLLING YEARLY REVENUE
--============================================================
WITH MonthlySales AS
(
    SELECT
        DATEFROMPARTS(YEAR(order_date),MONTH(order_date), 1) AS sales_month,
        SUM(net_amount) AS revenue
    FROM cleaned_sales
    WHERE order_date IS NOT NULL
    GROUP BY
        DATEFROMPARTS(YEAR(order_date),MONTH(order_date),1)
),

PreviousYear AS
(
    SELECT
        sales_month,
        revenue,
        LAG(revenue,12) OVER(ORDER BY sales_month) AS previous_year_revenue
    FROM MonthlySales
)

SELECT
    sales_month,
    ROUND(revenue,2) AS revenue,
    ROUND(previous_year_revenue,2)AS previous_year_revenue,
    ROUND(100.0 *(revenue - previous_year_revenue)/ NULLIF(previous_year_revenue,0),2) AS yoy_growth_percent
FROM PreviousYear
ORDER BY sales_month;