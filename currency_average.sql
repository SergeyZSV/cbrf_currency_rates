DECLARE start_date DATE;
DECLARE end_date DATE DEFAULT CURRENT_DATE();

IF EXTRACT(DAY FROM CURRENT_DATE()) = 1 THEN
  SET start_date = DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 1 MONTH);
ELSE
  SET start_date = DATE_TRUNC(CURRENT_DATE(), MONTH);
END IF;

DELETE FROM `schema.currency_average`
WHERE 
  year in (
    SELECT 
      EXTRACT(YEAR FROM business_dt) as year
    FROM `schema.currency_daily`
    WHERE business_dt between start_date and end_date
  )
  and month in (
    SELECT 
      EXTRACT(MONTH FROM business_dt) as month
    FROM `schema.currency_daily`
    WHERE business_dt between start_date and end_date
  );

INSERT INTO `schema.currency_average` 
SELECT
  EXTRACT(YEAR FROM business_dt) as year,
  EXTRACT(MONTH FROM business_dt) as month,
  currency as currency,
  AVG(COALESCE(rate, 0)) as rate,
  current_datetime() as processed_dttm
FROM `schema.currency_daily`
WHERE (business_dt between start_date and end_date)
    and (
        rate_changed is True
        or
        (select count(distinct business_dt) from `schema.currency_daily` 
            where 
                EXTRACT(YEAR FROM business_dt) = EXTRACT(YEAR FROM CURRENT_DATE())
                and EXTRACT(MONTH FROM business_dt) = EXTRACT(MONTH FROM CURRENT_DATE())
            ) = 1
    )
GROUP BY 1,2,3
ORDER BY 1,2,3