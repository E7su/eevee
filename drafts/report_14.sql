-- Author:            Polina Azarova
-- Date of creation:  08.07.2016
-- Description:       A report on the turnover ratio for the selected period in the context of administration,
--                    registration ( state / vendor )

--------------------------------------//14//---------------------------------------
-- Kt // Коэффициент текучести - отношение количества уволенных сотрудников в среднесписочной численности
-- Kt = Ky/CHsr * 100
SELECT round(kt.KY / kt.CHSR * 100, 2) KT
FROM
  -- Ky // Количество уволенных сотрудников за данный период времени
  (SELECT *
   FROM
     (SELECT count(ky."Дата увольнения") KY
      FROM
        (SELECT emp."Дата увольнения"
         FROM V_EMPLOYEES_SHORT emp
         WHERE --TODO add parameter
           emp."Дата увольнения" >= to_date('2016-04-01', 'yyyy-mm-dd') AND
           emp."Дата увольнения" <= to_date('2016-05-01', 'yyyy-mm-dd')
        ) ky
       )
     JOIN
     -- CHsr // Среднесписочная численность (количество сотрудников на начало месяца +
     --                                                      + количество сотрудников за следующий месяц, делённые на 2)
     -- CHsr = CHn + CHk
     (SELECT (cnn.CHN + ckk.CHK) / 2 CHSR
      FROM
        -- CHn // Количество сотрудников на начало месяцв (начало периода)
        (SELECT count(cn."Дата увольнения") CHN
         FROM
           (SELECT emp."Дата увольнения"
            FROM V_EMPLOYEES_SHORT emp
            WHERE emp."Дата увольнения" IS NULL OR emp."Дата увольнения" > to_date('2016-04-01', 'yyyy-mm-dd') OR
                  --TODO add parameter
                  emp."Дата увольнения" < to_date('2016-04-30', 'yyyy-mm-dd') --TODO add parameter
           ) cn
        ) cnn
        JOIN
        -- CHk // Количество сотрудников на начало следующего месяца (конец периода)
        (SELECT count(ck."Дата увольнения") CHk
         FROM
           (SELECT emp."Дата увольнения"
            FROM V_EMPLOYEES_SHORT emp
            WHERE emp."Дата увольнения" IS NULL OR emp."Дата увольнения" >= to_date('2016-04-30', 'yyyy-mm-dd') --TODO add parameter
           ) ck
        ) ckk
          ON 1 = 1)
       ON 1 = 1) kt
