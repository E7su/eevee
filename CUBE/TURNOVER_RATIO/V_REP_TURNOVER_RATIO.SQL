-- Author:            Polina Azarova
-- Date of creation:  08.07.2016
-- Description:       A report on the turnover ratio for the selected period in the context of administration,
--                    registration ( state / vendor )

--                    V_REP_TURNOVER_RATIO -> V_REP_AVG_TURNOVER -> V_REP_HEADCOUNT

--------------------------------------//14//---------------------------------------
CREATE OR REPLACE VIEW V_REP_TURNOVER_RATIO AS
  SELECT
    NVL(at.D, ds.D)                       D,
    NVL(at.REGISTRATION, ds.REGISTRATION) REG,
    NVL(at.DEPARTMENT, ds.DEPARTMENT)     DEP,
    at.AVG_TURNOVER,
    ds.DISMISS,
    DISMISS / AVG_TURNOVER * 100          TURNOVER_RATIO
  FROM (SELECT
          A.D,
          A.DEPARTMENT,
          A.REGISTRATION,
          A.AVG_TURNOVER
        FROM V_REP_AVG_TURNOVER A) AT
    LEFT JOIN
    (SELECT
       A.D,
       A.DEPARTMENT,
       A.REGISTRATION,
       A.DISMISS
     FROM V_REP_AVG_TURNOVER A) ds
      ON AT.REGISTRATION = ds.REGISTRATION AND AT.DEPARTMENT = ds.DEPARTMENT AND AT.D = ds.D
  WHERE AT.D > TO_DATE('2015-12-01', 'YYYY-MM-DD')
