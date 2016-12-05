CREATE OR REPLACE TYPE DISMISS_COUNT_TY IS OBJECT (MONTH VARCHAR2(255), KY VARCHAR2(255), "Подразделение" VARCHAR2(255), "Оформление" VARCHAR2(255));
CREATE OR REPLACE TYPE DISMISS_COUNT_TBL_TY IS TABLE OF DISMISS_COUNT_TY;

CREATE OR REPLACE FUNCTION REP_DISMISS_COUNT(p_year VARCHAR2, p_month VARCHAR2)
  RETURN DISMISS_COUNT_TBL_TY
PIPELINED
IS
  CURSOR cur (c_year VARCHAR2, c_month VARCHAR2)
  IS
    SELECT
      -- Ky // Количество уволенных сотрудников за данный период времени
      c_month                    MONTH,
      COUNT(t."Дата увольнения") KY,
      t."Подразделение",
      t."Оформление"
    FROM
      (SELECT
         emp."Дата увольнения",
         emp."Подразделение",
         emp."Оформление"
       FROM V_EMPLOYEES_SHORT emp
       WHERE -- TODO add parameter
         emp."Дата приёма" <= TO_DATE(c_year || '-' || c_month || '-01', 'YYYY-MM-DD') +
                              TO_CHAR(LAST_DAY(TO_DATE(c_year || '-' || c_month || '-01', 'YYYY-MM-DD')), 'DD') AND
         emp."Дата увольнения" >= TO_DATE(c_year || '-' || c_month || '-01', 'YYYY-MM-DD') AND
         emp."Дата увольнения" <= TO_DATE(c_year || '-' || c_month || '-01', 'YYYY-MM-DD')
                                  + TO_CHAR(LAST_DAY(TO_DATE(c_year || '-' || c_month || '-01', 'YYYY-MM-DD')), 'DD')
      ) t
    GROUP BY t."Подразделение", t."Оформление";
  BEGIN
    FOR rec IN cur (p_year, p_month)
    LOOP
      PIPE ROW (DISMISS_COUNT_TY(rec.MONTH, rec.KY, rec."Подразделение", rec."Оформление"));
    END LOOP;
    RETURN;
  END;
