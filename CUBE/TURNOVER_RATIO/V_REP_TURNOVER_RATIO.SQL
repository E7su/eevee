-- Author:            Polina Azarova
-- Date of creation:  08.07.2016
-- Description:       A report on the turnover ratio for the selected period in the context of administration,
--                    registration ( state / vendor )

--------------------------------------//14//---------------------------------------
CREATE OR REPLACE VIEW V_REP_TURNOVER_RATIO AS
SELECT
  at.D,
  at.REGISTRATION,
  at.DEPARTMENT,
  AVG_TURNOVER,
  DISMISS,
  DISMISS / AVG_TURNOVER * 100 TURNOVER_RATIO
FROM (SELECT
        a.D,
        a.DEPARTMENT,
        a.REGISTRATION,
        a.AVG_TURNOVER
      FROM V_REP_AVG_TURNOVER a) at
  LEFT JOIN
  (SELECT
     a.D,
     a.DEPARTMENT,
     a.REGISTRATION,
     SUM(a.DISMISS) DISMISS
   FROM V_REP_AVG_TURNOVER a
   GROUP BY a.D, A.DEPARTMENT, A.REGISTRATION) ds
    ON at.REGISTRATION = ds.REGISTRATION AND at.DEPARTMENT = ds.DEPARTMENT AND at.D = ds.D
