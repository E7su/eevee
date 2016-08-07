Отпуск
<span style="background-color:GreenYellow"/>__

Отгул
<span style="background-color:blue"/>__

Болезнь
<span style="background-color:red"/>__

Работа из дома
<span style="background-color:grey"/>__

Командировка
<span style="background-color:cyan"/>__

Обучение
<span style="background-color:cyan"/>__

Конференция
<span style="background-color:cyan"/>__

SELECT t.*
FROM
  (
    SELECT *
    FROM TABLE (REP_VACATIONS('$year_st', '$month_st', '$fio', '$proj', '$reg', '$dep'))
  )
    PIVOT (
      max(reason)
      FOR rn
      IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31)
    ) t
ORDER BY 1
