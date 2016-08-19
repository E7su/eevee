-- Author:            Polina Azarova
-- Date of creation:  08.07.2016
-- Description:       A report on the turnover ratio for the selected period in the context of administration,
--                    registration ( state / vendor )

--------------------------------------//14//---------------------------------------
-- Kt // Коэффициент текучести - отношение количества уволенных сотрудников в среднесписочной численности
-- Kt = Ky/CHsr * 100
SELECT
  kt."Подразделение",
  kt."Оформление",
  ROUND(kt.KY / kt.CHSR * 100, 2) KT
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
           emp."Дата приёма" <= TO_DATE('2015-12-01', 'yyyy-mm-dd') AND
           emp."Дата увольнения" >= TO_DATE('2015-12-01', 'yyyy-mm-dd') AND
           emp."Дата увольнения" <= TO_DATE('2016-01-01', 'yyyy-mm-dd')
        ) t
      GROUP BY t."Подразделение", t."Оформление"
     ) ky
     JOIN
     -- CHsr // Среднесписочная численность (количество сотрудников в декабре +
     --     //  + количество сотрудников в последующие месяцы, делённые на количество месяцев, прошедщих с декабря)
     -- CHsr = CHn/MONTHS_BETWEEN(DEC, REPORT_MONTH)
     (SELECT
        c.CHN / MONTHS_BETWEEN(TO_DATE('2016-01-01', 'yyyy-mm-dd'), TO_DATE('2015-12-01', 'yyyy-mm-dd')) CHSR,
        c."Подразделение",
        c."Оформление"
      FROM
        -- CHn // Количество сотрудников за период
        (SELECT
           COUNT(t."Дата увольнения") CHN,
           t."Подразделение",
           t."Оформление"
         FROM
           (SELECT
              emp."Дата увольнения",
              emp."Подразделение",
              emp."Оформление"
            FROM V_EMPLOYEES_SHORT emp
            WHERE emp."Дата приёма" <= TO_DATE('2015-12-01', 'yyyy-mm-dd') AND emp."Дата увольнения" IS NULL OR
                  emp."Дата увольнения" >= TO_DATE('2016-01-01', 'yyyy-mm-dd')--TODO add parameter
           ) t
         GROUP BY t."Подразделение", t."Оформление"
        ) c
     ) cn
       ON ky."Подразделение" = cn."Подразделение" AND
          ky."Оформление" = cn."Оформление") kt
WHERE kt."Оформление" IN ('Штат', 'Вентра')
