-- Author:            Polina Azarova
-- Date of creation:  08.07.2016
-- Description:       A report on the turnover ratio for the selected period in the context of administration,
--                    registration ( state / vendor )

--                    V_REP_TURNOVER_RATIO -> V_REP_DISMISS_COUNT -> REP_DISMISS_COUNT
--                                         -> V_REP_AVG_TURNOVER_RATIO -> REP_AVG_TURNOVER_RATIO

--------------------------------------//14//---------------------------------------
CREATE OR REPLACE TYPE AVG_TURNOVER_RATIO_TY IS OBJECT (MONTH           VARCHAR2(255), CHSR REAL,
                                                        "Подразделение" VARCHAR2(255), "Оформление" VARCHAR2(255));
CREATE OR REPLACE TYPE AVG_TURNOVER_RATIO_TBL_TY IS TABLE OF AVG_TURNOVER_RATIO_TY;

CREATE OR REPLACE FUNCTION REP_AVG_TURNOVER_RATIO(p_year VARCHAR2, p_month VARCHAR2)
  RETURN AVG_TURNOVER_RATIO_TBL_TY
PIPELINED
IS
  CURSOR cur (c_year VARCHAR2, c_month VARCHAR2)
  IS
    SELECT
      c_month                                                             MONTH,
      c.CHN /
      (MONTHS_BETWEEN(TO_DATE(c_year || '-12-01', 'yyyy-mm-dd'),
                      TO_DATE(c_year - 1 || '-12-01', 'yyyy-mm-dd')) + 1) CHSR,
      c."Подразделение",
      c."Оформление"
    FROM
      -- CHn // Количество сотрудников за период
      (SELECT
         COUNT(t."Дата приёма") CHN,
         t."Подразделение",
         t."Оформление"
       FROM
         (SELECT
            emp."ФИО",
            emp."Дата приёма",
            emp."Подразделение",
            emp."Оформление"
          FROM V_EMPLOYEES_SHORT emp
          WHERE
            emp."Дата приёма" <= TO_DATE(c_year - 1 || '-12-01', 'yyyy-mm-dd') AND emp."Дата увольнения" IS NULL OR
            emp."Дата увольнения" >= TO_DATE(c_year || '-12-01', 'yyyy-mm-dd') --TODO add parameter
            AND emp."Оформление" IN ('Штат', 'Вентра')
         ) t
       GROUP BY t."Подразделение", t."Оформление") c;
  BEGIN
    FOR rec IN cur (p_year, p_month)
    LOOP
      PIPE ROW (AVG_TURNOVER_RATIO_TY(rec.MONTH, rec.CHSR, rec."Подразделение", rec."Оформление"));
    END LOOP;
    RETURN;
  END;
