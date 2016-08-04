-- Author:            Polina Azarova
-- Date of creation:  19.05.2016
-- Description:       X-MEN HEADERS vacation

CREATE OR REPLACE VIEW JIRA_READER.V_REP_CITEB_HEADERS_HOLIDAY AS
  SELECT
    s.ФИО,
    -- обработка ситуации, когда отпуск попал на границу месяцев
    -- конкат нужен для того, чтобы не потерять вторую часть отпуска (которая попала на соседний месяц)
    s."1" || e."1"   Январь,
    s."2" || e."2"   Февраль,
    s."3" || e."3"   Март,
    s."4" || e."4"   Апрель,
    s."5" || e."5"   Май,
    s."6" || e."6"   Июнь,
    s."7" || e."7"   Июль,
    s."8" || e."8"   Август,
    s."9" || e."9"   Сентябрь,
    s."10" || e."10" Октябрь,
    s."11" || e."11" Ноябрь,
    s."12" || e."12" Декабрь,
    s.Итого
  FROM
    (SELECT
       h.*,
       i.HOLIDAY Итого
     FROM
       (SELECT *
        FROM
          (SELECT
             tt.FIO                       ФИО,
             tt.RN,
             -- через запятую в таблице
             LISTAGG(tt.HOLIDAY, ', ')
             WITHIN GROUP (
               ORDER BY tt.HOLIDAY_ORDER) HOLIDAY
           FROM
             (SELECT
                ROWNUM HOLIDAY_ORDER,
                t.FIO,
                t.RN,
                t.HOLIDAY
              FROM (SELECT
                      vac.FIO,
                      -- в ячейку месяца начала отпуска
                      vac.RN_S RN,
                      CASE vac.END_DAY
                      WHEN vac.START_DAY
                        THEN vac.END_DAY -- удаление даты начала, если отпуск длиной один день
                      ELSE
                        -- а если отпуск не один день, то
                        (CASE vac.END_MONTH
                         -- если отпуск не попал на границу месяцов,
                         -- то есть дата начала отпуска совпадает с датой конца,
                         -- выводим через чёрточку время отпуска
                         WHEN vac.START_MONTH
                           THEN
                             vac.START_DAY || '-' || vac.END_DAY
                         -- если попал на границу, то пишем, что он был до последнего дня месяца
                         -- а конец отпуска, который попал на другой месяц, подтягивается из нижней части джойна
                         ELSE vac.START_DAY || '-' ||
                              TO_CHAR(LAST_DAY(TO_DATE(vac.DATE_START, 'YYYY-MM-DD')), 'DD')
                         END)
                      END      HOLIDAY
                    FROM JIRA_READER.V_REP_CITEB_HEADERS_DATES vac
                    ORDER BY vac.FIO, vac.RN_E, vac.START_DAY
                   ) t
             ) tt
           GROUP BY tt.FIO, tt.RN)
           PIVOT (MAX(HOLIDAY)
             FOR RN
             IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12))) h
       JOIN (SELECT
               -- джойн чтобы посчитать Итого
               fvac.FIO,
               SUM(fvac.COUNTER) HOLIDAY -- Итого
             FROM (SELECT
                     emp.SUMMARY                     FIO,
                     vc.DATE_END - vc.DATE_START + 1 COUNTER
                   FROM JIRA_READER.V_EMPLOYEES emp
                     JOIN (SELECT DISTINCT
                             v.FIO,
                             v.DATE_START,
                             v.DATE_END
                           FROM JIRA_READER.V_VACATIONS_CHANGES v
                           WHERE v.REASON_ID = '13040') vc
                       ON emp.SUMMARY = vc.FIO
                   WHERE vc.DATE_START > TRUNC(TO_DATE('2016-01-01', 'YYYY-MM-DD'))
                         AND vc.DATE_END < TRUNC(TO_DATE('2016-12-31', 'YYYY-MM-DD'))
                   ORDER BY FIO) fvac
             GROUP BY fvac.FIO
            ) i ON i.FIO = h.ФИО) s

    JOIN -- обработка ситуации, когда отпуск попал на границу двух месяцев

    (SELECT *
     FROM
       (SELECT
          tt.FIO ФИО,
          tt.RN,
          tt.HOLIDAY
        FROM
          (SELECT
             ROWNUM HOLIDAY_ORDER,
             t.FIO,
             t.RN,
             t.HOLIDAY
           FROM (SELECT
                   vac.FIO,
                   -- в ячейку с месяцем окончания отпуска
                   vac.RN_E RN,
                   CASE vac.END_MONTH
                   WHEN vac.START_MONTH
                     -- дата удаляется, если отпуск длиной один день
                     THEN NULL
                   -- если попал на границу, то вторая часть отпуска была с первого дня месяца
                   ELSE '01' || '-' || vac.END_DAY
                   END      HOLIDAY
                 FROM
                   JIRA_READER.V_REP_CITEB_HEADERS_DATES vac
                ) t
          ) tt
       )
        PIVOT (MAX(HOLIDAY)
          FOR RN
          IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12))) e
      ON s.ФИО = e.ФИО
  ORDER BY 1
