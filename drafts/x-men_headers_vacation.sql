-- Author:            Polina Azarova
-- Date of creation:  19.05.2016
-- Description:       X-MEN HEADERS vacation

SELECT
  h.*,
  i.HOLIDAY Итого
FROM
  (SELECT *
   FROM (SELECT
           tt.FIO                       ФИО,
           tt.RN,
           LISTAGG(tt.HOLIDAY, ', ')
           WITHIN GROUP (
             ORDER BY tt.HOLIDAY_ORDER) HOLIDAY
         --        REGEXP_REPLACE(LISTAGG(HOLIDAY, ', ')
         --                       WITHIN GROUP (
         --                         ORDER BY HOLIDAT), '([^,]+)(,\1)?+', '\1') HOLIDAY  -- удаляем повторы в датах
         FROM
           (SELECT
              ROWNUM HOLIDAY_ORDER,
              t.FIO,
              t.RN,
              t.HOLIDAY
            FROM (SELECT
                    vac.FIO,
                    vac.RN,
                    CASE vac.END_DAY
                    WHEN vac.START_DAY
                      THEN TO_CHAR(vac.END_DAY) -- удаление даты начала, если отпуск длиной один день
                    ELSE vac.START_DAY || '-' || vac.END_DAY -- через чёрточку, если дата начала != дате конца
                    END HOLIDAY
                  FROM
                    (SELECT
                       vc.FIO,
                       EXTRACT(DAY FROM vc.DATE_END)     END_DAY,
                       EXTRACT(DAY FROM vc.DATE_START)   START_DAY,
                       EXTRACT(MONTH FROM vc.DATE_START) RN
                     FROM V_EMPLOYEES_SHORT e
                       LEFT JOIN (SELECT DISTINCT
                                    v.FIO,
                                    v.DATE_START,
                                    v.DATE_END
                                  FROM V_VACATIONS_CHANGES v
                                  WHERE v.REASON_ID = '13040'
                                 ) vc ON e.ФИО = vc.FIO
                      WHERE (fio = 'Magneto' OR
                             fio = 'Wolverine' OR
                             fio = 'Mystique' OR
                             fio = 'Professor X' OR
                             fio = 'Bishop' OR
                             fio = 'Storm' OR
                             fio = 'Nightcrawler' OR
                             fio = 'Sprite' OR
                             fio = 'Cyclops' OR
                             fio = 'Iceman' OR
                             fio = 'Thunderbird' OR
                             fio = 'Colossus')
                           AND e."Дата увольнения" IS NULL
                           AND vc.DATE_START > TRUNC(to_date('2016-01-01', 'yyyy-mm-dd'))
                           AND vc.DATE_END < TRUNC(to_date('2016-12-31', 'yyyy-mm-dd')) AND
                           e."Дата увольнения" IS NULL OR (TRUNC(to_date(e."Дата увольнения", 'yyyy-mm-dd')) >=
                                                           TRUNC(to_date('2016-01-01', 'yyyy-mm-dd')))
                     -- TODO
                     --                         AND DATE_START > TRUNC(to_date('$year_st-01-01', 'yyyy-mm-dd'))
                     --                         AND DATE_END < TRUNC(to_date('$year_st-12-31', 'yyyy-mm-dd'))
                     --                         OR (TRUNC(to_date(emp."Дата увольнения", 'yyyy-mm-dd')) >=
                     --                             TRUNC(to_date('$year_st-01-01', 'yyyy-mm-dd')))
                     ORDER BY vc.FIO) vac
                  ORDER BY vac.FIO, vac.RN, vac.START_DAY
                 ) t
           ) tt
         GROUP BY tt.FIO, tt.RN)
         PIVOT (MAX(HOLIDAY)
           FOR RN
           IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12))) h
  JOIN (SELECT
          fvac.FIO,
          SUM(fvac.COUNTER) HOLIDAY
        FROM (SELECT
                emp.SUMMARY                     FIO,
                vc.DATE_END - vc.DATE_START + 1 COUNTER
              FROM V_EMPLOYEES emp
                JOIN (SELECT DISTINCT
                        v.FIO,
                        v.DATE_START,
                        v.DATE_END
                      FROM V_VACATIONS_CHANGES v
                      WHERE v.REASON_ID = '13040') vc
                  ON emp.SUMMARY = vc.FIO
              WHERE vc.DATE_START > TRUNC(to_date('2016-01-01', 'yyyy-mm-dd'))
                    AND vc.DATE_END < TRUNC(to_date('2016-12-31', 'yyyy-mm-dd'))
              -- TODO
              --                 AND DATE_START > TRUNC(to_date('$year_st-01-01', 'yyyy-mm-dd'))
              --                 AND DATE_END < TRUNC(to_date('$year_st-12-31', 'yyyy-mm-dd'))
              ORDER BY FIO) fvac
        GROUP BY fvac.FIO
       ) i ON i.FIO = h.ФИО
ORDER BY 1
