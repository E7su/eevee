-- Author:            Polina Azarova
-- Date of creation:  08.07.2016
-- Description:       A report on the turnover ratio for the selected period in the context of administration,
--                    registration ( state / vendor )

--------------------------------------//14//---------------------------------------
-- Kt // Коэффициент текучести - отношение количества уволенных сотрудников в среднесписочной численности
-- Kt = Ky/CHsr * 100
CREATE OR REPLACE TYPE TURNOVER_RATIO_TY IS OBJECT ("Подразделение" VARCHAR2(255), "Оформление" VARCHAR2(255),
                                                    KT              NUMBER, DATE_ST DATE, DATE_END DATE);
CREATE OR REPLACE TYPE TURNOVER_RATIO_TBL_TY IS TABLE OF TURNOVER_RATIO_TY;

CREATE OR REPLACE FUNCTION REP_TURNOVER_RATIO(p_date_st VARCHAR2, p_date_end VARCHAR2)
  RETURN TURNOVER_RATIO_TBL_TY
PIPELINED
IS
  CURSOR cur (c_date_st VARCHAR2, c_date_end VARCHAR2)
  IS
    SELECT
      kt."Подразделение",
      kt."Оформление",
      ROUND(kt.KY / kt.CHSR * 100, 2)   KT,
      TO_DATE(c_date_st, 'yyyy-mm-dd')  DATE_ST,
      TO_DATE(c_date_end, 'yyyy-mm-dd') DATE_END
    FROM
      -- Ky // Количество уволенных сотрудников за данный период времени
      (SELECT
         ky.*,
         cn.CHSR
       FROM
         (SELECT
            COUNT(t."Дата увольнения") KY,
            t."Подразделение",
            t."Оформление"
          FROM
            (SELECT
               emp."Дата увольнения",
               emp."Подразделение",
               emp."Оформление"
             FROM V_EMPLOYEES_SHORT emp
             WHERE --TODO add parameter
               emp."Дата приёма" <= TO_DATE(c_date_end, 'yyyy-mm-dd') AND
               emp."Дата увольнения" >= TO_DATE(c_date_st, 'yyyy-mm-dd') AND
               emp."Дата увольнения" <= TO_DATE(c_date_end, 'yyyy-mm-dd')
            ) t
          GROUP BY t."Подразделение", t."Оформление"
         ) ky
         JOIN
         -- CHsr // Среднесписочная численность (количество сотрудников в декабре +
         --     //  + количество сотрудников в последующие месяцы, делённые на количество месяцев, прошедщих с декабря)
         -- CHsr = CHn/MONTHS_BETWEEN(DEC, REPORT_MONTH)
         (SELECT
            c.CHN / MONTHS_BETWEEN(TO_DATE(c_date_end, 'yyyy-mm-dd'), TO_DATE(c_date_st, 'yyyy-mm-dd')) CHSR,
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
                  emp."Дата приёма",
                  emp."Подразделение",
                  emp."Оформление"
                FROM V_EMPLOYEES_SHORT emp
                WHERE emp."Дата приёма" <= TO_DATE(c_date_st, 'yyyy-mm-dd') AND emp."Дата увольнения" IS NULL OR
                      emp."Дата увольнения" >= TO_DATE(c_date_end, 'yyyy-mm-dd')--TODO add parameter
               ) t
             GROUP BY t."Подразделение", t."Оформление"
            ) c
         ) cn
           ON ky."Подразделение" = cn."Подразделение" AND
              ky."Оформление" = cn."Оформление") kt
    WHERE kt."Оформление" IN ('Штат', 'Вентра');

  BEGIN
    FOR rec IN cur (p_date_st, p_date_end)
    LOOP
      PIPE ROW (TURNOVER_RATIO_TY(rec."Подразделение", rec."Оформление", rec.KT, rec.DATE_ST, rec.DATE_END));
    END LOOP;
    RETURN;
  END;
