
--====================================================
-- WHICH PRODUCTS ARE SELLING THE MOST IN EACH CITY
--====================================================
WITH RANKING AS(
SELECT
    city,
    product,
    SUM(quantity) units_sold,
    ROUND(SUM(net_amount),2) net_revenue
FROM cleaned_sales
GROUP BY city,
        product
)
SELECT*,
    ROW_NUMBER()OVER(PARTITION BY CITY ORDER BY net_revenue desc) rank
FROM RANKING