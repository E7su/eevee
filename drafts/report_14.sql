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
     kyky.*,
     cnnn.CHSR
   FROM
     (SELECT
        COUNT(ky."Дата увольнения") KY,
        ky."Подразделение",
        ky."Оформление"
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
        ) ky
      GROUP BY ky."Подразделение", ky."Оформление"
     ) kyky
     JOIN
     -- CHsr // Среднесписочная численность (количество сотрудников в декабре +
     --     //  + количество сотрудников в последующие месяцы, делённые на количество месяцев, прошедщих с декабря)
     -- CHsr = CHn/MONTHS_BETWEEN(DEC, REPORT_MONTH)
     (SELECT
        cnn.CHN / MONTHS_BETWEEN(TO_DATE('2016-01-01', 'yyyy-mm-dd'), TO_DATE('2015-12-01', 'yyyy-mm-dd')) CHSR,
        cnn."Подразделение",
        cnn."Оформление"
      FROM
        -- CHn // Количество сотрудников за период
        (SELECT
           COUNT(cn."Дата увольнения") CHN,
           cn."Подразделение",
           cn."Оформление"
         FROM
           (SELECT
              emp."Дата увольнения",
              emp."Подразделение",
              emp."Оформление"
            FROM V_EMPLOYEES_SHORT emp
            WHERE emp."Дата приёма" <= TO_DATE('2015-12-01', 'yyyy-mm-dd') AND emp."Дата увольнения" IS NULL OR
                  emp."Дата увольнения" >= TO_DATE('2016-01-01', 'yyyy-mm-dd')--TODO add parameter
           ) cn
         GROUP BY cn."Подразделение", cn."Оформление"
        ) cnn
     ) cnnn
       ON kyky."Подразделение" = cnnn."Подразделение" AND
          kyky."Оформление" = cnnn."Оформление") kt
WHERE kt."Оформление" IN ('Штат', 'Вентра')
