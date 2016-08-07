SELECT t.*
FROM
  (
    SELECT *
    FROM TABLE (REP_VACATIONS_REASONS('$year_st', '$month_st', '$day_st', '$year_end', '$month_end', '$day_end', '$fio', '$reg', '$dep'))
  )
    PIVOT (
      count(rn)
      FOR reason
      IN ('Отпуск', 'Отгул', 'Болезнь', 'Работа из дома', 'Командировка', 'Обучение', 'Конференция')) t
ORDER BY 1
