SELECT t.*
FROM
  (SELECT DISTINCT
     dat.FIO                     "Ф.И.О.",
     vr.VALUE AS                 REASON,
     EXTRACT(DAY
             FROM dat.STARTDATE) RN
   FROM
     (SELECT
        v.FIO,
        dd.d AS STARTDATE,
        v.REASON_ID,
        emp."ФИО",
        emp."Подразделение",
        emp."Оформление"

      FROM V_VACATIONS_CHANGES v
        JOIN JIRA.JIRAISSUE iss ON (
          iss.ISSUENUM = v.ISSUENUM
          AND iss.ISSUESTATUS IN (10015, 11507, 11705))
        -- Done, Confirmation, Planning
        LEFT JOIN (
                    SELECT TRUNC(TO_DATE('$year_st-$month_st-$day_st', 'yyyy-mm-dd') + ROWNUM - 1) d -- дата начала
                    FROM dual
                    CONNECT BY ROWNUM <= TRUNC(TO_DATE('$year_end-$month_end-$day_end', 'yyyy-mm-dd')) -
                                         TRUNC(TO_DATE('$year_st-$month_st-$day_st', 'yyyy-mm-dd')) + 1
                  ) dd ON (dd.d >= TRUNC(v.DATE_START) AND dd.d <= TRUNC(v.DATE_END))

        JOIN V_EMPLOYEES_SHORT emp ON (
          emp."ФИО" = v.FIO)
      WHERE fio IS NOT NULL
            AND dd.D IS NOT NULL
            AND ('$fio' IS NULL
                 OR (lower(emp."ФИО") LIKE '%' || LOWER('$fio') || '%'))
            AND ('$reg' IS NULL
                 OR emp."Оформление" = '$reg')
            AND ('$dep' IS NULL
                 OR emp."Подразделение" = '$dep')
     ) dat
     JOIN JIRA_READER.V_VACATIONS_REASONS vr ON dat.REASON_ID = vr.ID
  )
   PIVOT (COUNT(RN)
     FOR REASON
     IN ('Отпуск', 'Отгул', 'Болезнь', 'Работа из дома', 'Командировка', 'Обучение', 'Конференция')) t
ORDER BY 1
