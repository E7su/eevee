-- Author:            Polina Azarova
-- Date of creation:  08.07.2016
-- Description:       A report on the turnover ratio for the selected period in the context of administration,
--                    registration ( state / vendor )

--                    V_REP_TURNOVER_RATIO -> V_REP_AVG_TURNOVER -> V_REP_HEADCOUNT

--------------------------------------//14//---------------------------------------
CREATE OR REPLACE VIEW V_REP_TURNOVER_RATIO AS
  SELECT
    NVL(at.D, ds.D)     D,
    NVL(at.REG, ds.REG) REG,
    NVL(at.DEP, ds.DEP) DEP,
    at.AVG_TURNOVER,
    ds.DISMISS --,
  --     DISMISS / AVG_TURNOVER * 100 TURNOVER_RATIO в eazyBI
  FROM (SELECT
          a.D,
          a.DEP,
          a.REG,
          a.AVG_TURNOVER
        FROM V_REP_AVG_TURNOVER a) at
    LEFT JOIN
    (SELECT
       a.D,
       a.DEP,
       a.REG,
       a.DISMISS
     FROM V_REP_AVG_TURNOVER a) ds
      ON at.REG = ds.REG AND at.DEP = ds.DEP AND at.D = ds.D
  WHERE at.D > TO_DATE('2015-12-01', 'YYYY-MM-DD')
