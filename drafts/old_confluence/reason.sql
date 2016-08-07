SELECT t.*
FROM
  (
    SELECT DISTINCT
      dat.fio                     "Ф.И.О.",
      dat.REASON AS               reason,
      extract(DAY
              FROM dat.startdate) rn
    FROM
      (SELECT
         vc.FIO,
         dd.d AS  startdate,
         vr.VALUE REASON,
         emp."ФИО",
         emp."Подразделение",
         emp."Оформление"

       FROM V_VACATIONS_CHANGES vc
         LEFT JOIN (
                     SELECT TRUNC(to_date('$year_st-$month_st-$day_st', 'yyyy-mm-dd') + rownum -
                                  1) d -- дата начала
                     FROM dual
                     CONNECT BY rownum <=
                                TRUNC(to_date('$year_end-$month_end-$day_end', 'yyyy-mm-dd')) -
                                TRUNC(to_date('$year_st-$month_st-$day_st', 'yyyy-mm-dd')) + 1
                   ) dd ON (dd.d >= TRUNC(vc.DATE_START) AND dd.d <= TRUNC(vc.DATE_END))

         JOIN V_EMPLOYEES_SHORT emp ON (
           emp."ФИО" = vc.fio)
         JOIN V_VACATIONS_REASONS vr ON (vr.ID = vc.REASON_ID)
      ) dat
    WHERE fio IS NOT NULL
          AND startdate IS NOT NULL
          AND ('$fio' IS NULL
               OR (lower(dat."ФИО") LIKE '%' || lower('$fio') || '%'))
          AND ('$reg' IS NULL
               OR dat."Оформление" = '$reg')
          AND ('$dep' IS NULL
               OR dat."Подразделение" = '$dep')
  )
    PIVOT (
      count(rn)
      FOR reason
      IN ('Отпуск', 'Отгул', 'Болезнь', 'Работа из дома', 'Командировка', 'Обучение', 'Конференция')) t
ORDER BY 1
