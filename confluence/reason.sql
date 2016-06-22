SELECT t.*
FROM
  ( SELECT DISTINCT dat.fio "Ф.И.О.",
                   dat.reason_id AS reason,
                   extract(DAY
                           FROM dat.startdate) rn
  FROM
     ( SELECT
            v.FIO,
            dd.d AS startdate,
            v.REASON_ID,
       --     v.ISSUENUM,
            emp."ФИО",
            emp."Подразделение",
            emp."Оформление"

          FROM V_VACATION_REASONS v
             JOIN jira.jiraISSUE iss ON (
                   iss.issuenum = v.issuenum
                   AND  iss.issuestatus in (10015, 11507, 11705))  -- Done, Confirmation, Planning

            LEFT JOIN  (
                        SELECT TRUNC(to_date('$year_st-$month_st-$day_st', 'yyyy-mm-dd') + rownum - 1) d    -- дата начала
                        FROM dual
                        CONNECT BY rownum <= TRUNC(to_date('$year_end-$month_end-$day_end', 'yyyy-mm-dd')) - TRUNC(to_date('$year_st-$month_st-$day_st', 'yyyy-mm-dd')) + 1
                      ) dd ON (dd.d >= TRUNC(v.DATE_START) AND dd.d <= TRUNC(v.DATE_END))

            JOIN  V_EMPLOYEES_SHORT emp ON (
              emp."ФИО" = v.fio )

--         JOIN jira.jiraISSUE iss ON (
--                    iss.issuenum = v.issuenum
--                    AND  (iss.issuestatus in (10015, 11507, 11705)))

     ) dat
 WHERE fio IS NOT NULL
  AND startdate IS NOT NULL
  AND ('$fio' IS NULL
       OR (lower(dat."ФИО") LIKE '%'||lower('$fio')||'%'))
  AND ('$reg' IS NULL
       OR dat."Оформление" = '$reg')
  AND ('$dep' IS NULL
       OR dat."Подразделение" = '$dep')
 ) pivot(COUNT(rn)
         FOR reason IN ('Отпуск', 'Отгул', 'Болезнь', 'Работа из дома', 'Командировка', 'Обучение', 'Конференция')) t
ORDER BY 1







