-- Date of creation:  19.05.2016
-- Description:       X-MEN HEADERS vacation

SELECT
  fio     ФИО,
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "10",
  "11",
  "12",
  HOLIDAY Итого
FROM
  (SELECT *
   FROM (
     SELECT
       fio,
       RN,
       LISTAGG(HOLIDAY, ', ')
       WITHIN GROUP (
         ORDER BY holiday_order) HOLIDAY
     --        regexp_replace(LISTAGG(HOLIDAY, ', ')
     --                       WITHIN GROUP (
     --                         ORDER BY holiday), '([^,]+)(,\1)?+', '\1') HOLIDAY  -- удаляем повторы в датах
     FROM
       (SELECT
          ROWNUM holiday_order,
          fio,
          RN,
          HOLIDAY
        FROM (SELECT
                fio,
                RN,
                CASE END_DAY
                WHEN START_DAY
                  THEN to_char(END_DAY) -- удаление даты начала, если отпуск длиной один день
                ELSE START_DAY || '-' || END_DAY -- через чёрточку, если дата начала != дате конца
                END HOLIDAY
              FROM
                (
                  SELECT
                    fio,
                    extract(DAY FROM vac.DATE_END)     END_DAY,
                    extract(DAY FROM vac.DATE_START)   START_DAY,
                    extract(MONTH FROM vac.DATE_START) RN
                  FROM V_EMPLOYEES_SHORT emp
                    LEFT JOIN (
                                SELECT DISTINCT
                                  fio,
                                  v.DATE_START,
                                  v.DATE_END
                                FROM V_VACATION_REASONS v
                                  JOIN jira.jiraISSUE iss ON (
                                    iss.issuenum = v.issuenum
                                    AND iss.issuestatus IN (10015, 11507, 11705)) -- Done, Confirmation, Planning
                                WHERE v.reason_id = 'Отпуск') vac
                      ON emp.ФИО = vac.fio

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
                        AND emp."Дата увольнения" IS NULL
                        AND DATE_START > TRUNC(to_date('2016-01-01', 'yyyy-mm-dd'))  --TODO '$year_st-$month_st-$day_st'
                        AND DATE_END < TRUNC(to_date('2017-01-01', 'yyyy-mm-dd'))
                        --TODO '$year_end-$month_end-$day_end'
                        OR (TRUNC(to_date(emp."Дата увольнения", 'yyyy-mm-dd')) >=
                            TRUNC(to_date('2016-01-01', 'yyyy-mm-dd')))   --TODO '$year_st-$month_st-$day_st'
                  ORDER BY fio)

              ORDER BY fio, rn, START_DAY)
       )
     GROUP BY fio, RN
   )
     PIVOT (MAX(HOLIDAY)
       FOR RN
       IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)))
  JOIN (SELECT
          sum(counter) HOLIDAY,
          fio          "ФИО"
        FROM (
          SELECT
            fio,
            DATE_END - DATE_START + 1 COUNTER
          FROM V_EMPLOYEES_SHORT emp
            JOIN (
                   SELECT DISTINCT
                     v.fio,
                     v.DATE_START,
                     v.DATE_END
                   FROM V_VACATION_REASONS v
                     JOIN jira.jiraISSUE iss ON (
                       iss.issuenum = v.issuenum
                       AND iss.issuestatus IN (10015, 11507, 11705)) -- Done, Confirmation, Planning
                   WHERE v.reason_id = 'Отпуск') vac
              ON emp.ФИО = vac.fio

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
                AND emp."Дата увольнения" IS NULL
                AND DATE_START > TRUNC(to_date('2016-01-01', 'yyyy-mm-dd'))   --TODO '$year_st-$month_st-$day_st'
                AND DATE_END < TRUNC(to_date('2017-01-01', 'yyyy-mm-dd'))   --TODO '$year_end-$month_end-$day_end'
                OR (TRUNC(to_date(emp."Дата увольнения", 'yyyy-mm-dd')) >=
                    TRUNC(to_date('2016-01-01', 'yyyy-mm-dd')))   --TODO '$year_st-$month_st-$day_st'
          ORDER BY fio)
        GROUP BY fio
  ) ON ФИО = fio
ORDER BY 1