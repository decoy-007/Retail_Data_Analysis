
DROP TABLE IF EXISTS cleaned_sales;

WITH Cleaned AS(
	SELECT
		TRIM(REPLACE(order_id, 'ORD ', 'ORD-')) AS order_id,

        TRIM(customer_id) AS customer_id,
		COALESCE(
        TRY_CONVERT(date, TRIM(order_date), 23),
        TRY_CONVERT(date, TRIM(order_date), 111),
        TRY_CONVERT(date, TRIM(order_date), 103),
        TRY_CONVERT(date, TRIM(order_date), 110),
        TRY_CONVERT(date, TRIM(order_date), 106)
        ) AS order_date,
        CONCAT_WS(
            ' ',
        NULLIF(TRIM(customer_first_name), ''),
        NULLIF(TRIM(customer_last_name), '')
        ) AS CustomerName,

        CASE
    WHEN UPPER(TRIM(city)) IN ('JHB','JOBURG','JOHANNESBERG','JOHANNESBURG')
        THEN 'Johannesburg'

    WHEN UPPER(TRIM(city)) IN ('PTA','PRETORIA')
        THEN 'Pretoria'

    WHEN UPPER(TRIM(city)) IN ('PE','PORT ELIZABETH','GQEBERHA')
        THEN 'Gqeberha'

    WHEN UPPER(TRIM(city)) IN ('CAPE TOWN','CAPETOWN')
        THEN 'Cape Town'

    ELSE TRIM(city)
        END AS city,

    CASE
    WHEN UPPER(TRIM(customer_segment)) = 'CONSUMER'
        THEN 'Consumer'

    WHEN UPPER(TRIM(customer_segment)) = 'CORPORATE'
        THEN 'Corporate'

    WHEN UPPER(TRIM(customer_segment)) IN ('SMALL BUSINESS','SMB')
        THEN 'Small Business'
    ELSE NULL
    END AS customer_segment,

CASE 
    WHEN UPPER(TRIM(sales_channel)) = 'ONLINE' THEN 'Online'
    WHEN UPPER(TRIM(sales_channel)) = 'STORE' THEN  'Store'
    WHEN UPPER(TRIM(sales_channel)) = 'MARKETPLACE' THEN 'Marketplace'
    WHEN UPPER(TRIM(sales_channel)) = 'PHONE' THEN 'Phone'
    ELSE NULL
END sales_channel,

CASE 
    WHEN UPPER(TRIM(product)) IN ('DOCKING STATION','DOCK STATION','DOCKINGSTATION')
            THEN 'Docking Station'
    WHEN UPPER(TRIM(product)) IN ('HEADSET', 'HEAD SET')
            THEN 'Headset'
    ELSE TRIM(product)
END product,

CASE
    WHEN TRY_CONVERT(float, quantity) BETWEEN 1 AND 100
        THEN TRY_CONVERT(float, quantity)
    ELSE NULL
END AS quantity,

    TRY_CONVERT(decimal(12,2),REPLACE(REPLACE(TRIM(unit_price),'R',''),',','')) unit_price,

    CASE
    WHEN CHARINDEX('%', TRIM(discount)) > 0
        THEN TRY_CONVERT(
            decimal(10,2),
            REPLACE(TRIM(discount), '%', '')
        ) / 100

    ELSE TRY_CONVERT(decimal(10,2), TRIM(discount))
END AS discount,

        CASE
            WHEN TRY_CONVERT(decimal(12,2),TRIM(shipping_fee)) >= 0
            THEN TRY_CONVERT(decimal(12,2),TRIM(shipping_fee))
            ELSE NULL
        END AS shipping_fee,

        CASE
            WHEN CHARINDEX('%', TRIM(tax_rate)) > 0
            THEN TRY_CONVERT(
            decimal(10,2),
            REPLACE(TRIM(tax_rate), '%', '')) / 100
            ELSE TRY_CONVERT(decimal(10,2), TRIM(tax_rate))
        END AS tax_rate,

          CASE
            WHEN TRY_CONVERT(decimal(12,2),TRIM(cost_per_unit)) > 0
            THEN TRY_CONVERT(decimal(12,2),TRIM(cost_per_unit))
            ELSE NULL
        END AS cost_per_unit,

         CASE
            WHEN UPPER(TRIM(campaign)) = 'NONE'
            THEN 'None'

            WHEN UPPER(TRIM(campaign))= 'SUMMER SALE'
            THEN 'Summer Sale'

            WHEN UPPER(TRIM(campaign))= 'BACK TO SCHOOL'
            THEN 'Back to School'

            WHEN UPPER(TRIM(campaign))= 'BLACK FRIDAY'
            THEN 'Black Friday'

            WHEN UPPER(TRIM(campaign))= 'PAYDAY PROMO'
            THEN 'Payday Promo'

            WHEN UPPER(TRIM(campaign)) = 'NEW CUSTOMER'
            THEN 'New Customer'

            WHEN UPPER(TRIM(campaign))= 'CLEARANCE'
            THEN 'Clearance'
            ELSE NULL
        END AS campaign,

        CASE
    WHEN UPPER(TRIM(payment_method)) IN ('CARD')
        THEN 'Card'

    WHEN UPPER(TRIM(payment_method)) IN ('CASH')
        THEN 'Cash'

    WHEN UPPER(TRIM(payment_method)) IN ('EFT','EFT TRANSFER')
        THEN 'EFT'

    WHEN UPPER(TRIM(payment_method)) IN ('MOBILE WALLET','MOBILEWALLET')
        THEN 'Mobile Wallet'

    WHEN UPPER(TRIM(payment_method)) IN ('BANK TRANSFER')
        THEN 'Bank Transfer'
    ELSE NULL
END AS payment_method,

CASE
    WHEN UPPER(TRIM(order_status)) IN ('COMPLETE','COMPLETED')
        THEN 'Completed'

    WHEN UPPER(TRIM(order_status)) = 'CANCELLED'
        THEN 'Cancelled'

    WHEN UPPER(TRIM(order_status)) = 'PENDING'
        THEN 'Pending'

    WHEN UPPER(TRIM(order_status)) = 'RETURNED'
        THEN 'Returned'

    ELSE NULL
END AS order_status_clean,

   NULLIF(TRIM(sales_rep),'') AS sales_rep,

   
        CASE
            WHEN TRY_CONVERT(decimal(14,2),total_amount) >= 0
            THEN TRY_CONVERT(decimal(14,2),total_amount)
            ELSE NULL
        END AS recorded_total

FROM real_world_messy_sales_assessment
),
Validated AS(
    SELECT*
    FROM Cleaned
    WHERE (discount IS NULL OR discount BETWEEN 0 AND 1)
            AND (tax_rate IS NULL OR tax_rate BETWEEN 0 AND 1)
),
Calculated AS(
 SELECT *,
        quantity * unit_price
            AS calculated_gross_amount,

        quantity * unit_price
            * COALESCE(discount,0)
            AS discount_amount,
     
        (quantity * unit_price)- (quantity * unit_price * COALESCE(discount,0)) AS net_amount,

      
        ((quantity * unit_price)-(quantity * unit_price * COALESCE(discount,0)))* COALESCE(tax_rate,0)
        AS tax_amount

 FROM Validated
),
FinalData AS
(
    SELECT
        *,
        ROUND(net_amount+ tax_amount + COALESCE(shipping_fee,0),2) AS calculated_total_amount

    FROM Calculated
)
SELECT
    *
INTO cleaned_sales
FROM
(
    SELECT
        *,
        ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY
                 CASE
                    WHEN recorded_total IS NOT NULL
                        THEN 0
                    ELSE 1
                 END, order_date) AS duplicate_rank
    FROM FinalData
) x
WHERE duplicate_rank = 1;

SELECT*
FROM cleaned_sales
