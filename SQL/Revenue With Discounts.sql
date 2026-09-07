
--===========================================================
-- discount analysis 
--===========================================================
SELECT
    CASE
        WHEN discount = 0
            THEN 'No Discount'

        WHEN discount <= 0.10
            THEN '1-10%'

        WHEN discount <= 0.20
            THEN '11-20%'

        ELSE '20%+'
    END AS discount_band,

    COUNT(*) AS orders,

    ROUND(SUM(net_amount),2) AS revenue,

    ROUND(AVG(net_amount),2) AS average_order_value,

    ROUND(AVG(discount) * 100,2) AS average_discount

FROM cleaned_sales

GROUP BY
    CASE
        WHEN discount = 0
            THEN 'No Discount'

        WHEN discount <= 0.10
            THEN '1-10%'

        WHEN discount <= 0.20
            THEN '11-20%'

        ELSE '20%+'
    END
ORDER BY revenue DESC;