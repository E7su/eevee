-- Author:            Polina Azarova
-- Date of creation:  08.07.2016
-- Description:       A report on the turnover ratio for the selected period in the context of administration,
--                    registration ( state / vendor )

--                    V_RTR_TURNOVER_RATIO -> V_RTR_TURNOVER_AVG -> V_RTR_DISMISS

--------------------------------------//14//---------------------------------------
CREATE OR REPLACE VIEW V_RTR_TURNOVER_AVG AS
  WITH dates (D) AS (
    SELECT TO_DATE('2015-12-01', 'YYYY-MM-DD') AS D
    FROM dual -- //start
    UNION ALL
    SELECT ADD_MONTHS(D, 1) AS D
    FROM dates
    WHERE D < TO_DATE('2016-12-01', 'YYYY-MM-DD') -- end//
  )
  SELECT
    h.D,
    NVL(h.DEP, d.DEP) DEP,
    NVL(h.REG, d.REG) REG,
    h.AVG_TURNOVER    AVG_TURNOVER,
    d.DISMISS
  FROM
    (SELECT
       dates.D,
       h.DEP,
       h.REG,
       SUM(h.HEADCOUNT) / ROUND(MONTHS_BETWEEN(dates.D, TO_DATE('2015-12-01', 'YYYY-MM-DD')) + 1) AVG_TURNOVER
     FROM dates
       LEFT JOIN V_RTR_DISMISS h ON h.DAT <= dates.D
     GROUP BY DEP, REG, D) h
    LEFT JOIN
    (SELECT
       dates.D,
       h.DEP,
       h.REG,
       SUM(h.DISMISS) DISMISS
     FROM dates
       LEFT JOIN V_RTR_DISMISS h ON h.DAT <= dates.D
     GROUP BY DEP, REG, D) d
      ON h.D = d.D AND h.REG = d.REG AND h.DEP = d.DEP
