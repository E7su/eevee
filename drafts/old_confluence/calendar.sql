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
  (SELECT dat.fio "Ф.И.О.",
          '<span style="background-color:' || CASE dat.reason
                                                  WHEN '13040' THEN 'GreenYellow' -- Отпуск
                                                  WHEN '13041' THEN 'blue'        -- Отгул
                                                  WHEN '13042' THEN 'red'         -- Болезнь
                                                  WHEN '13043' THEN 'grey'        -- Работа из дома
                                                  WHEN '13044' THEN 'cyan'        -- Командировка
                                                  WHEN '13045' THEN 'cyan'        -- Обучение
                                                  WHEN '13046' THEN 'cyan'        -- Конференция
                                                  ELSE 'Medium'
                                              END || '"/>' || '<a href="http://jira/browse/VAC-' || dat.issuenum || '">' || '__' || '</a>' reason,
                                                                                                    extract(DAY
                                                                                                            FROM dat.startdate) rn


  FROM
     (SELECT v.FIO,
             dd.d AS startdate,
                     v.REASON,
                     v.ISSUENUM,
                     emp."ФИО",
                     emp."Подразделение",
                     emp."Оформление",
                     emp."Проекты"
     FROM V_VACATIONS v
     LEFT JOIN
        (SELECT TRUNC(to_date('$year_st-$month_st-01', 'yyyy-mm-dd') + rownum - 1) d
         FROM dual CONNECT BY rownum <= CAST(to_char(LAST_DAY(to_date('$year_st-$month_st-01', 'yyyy-mm-dd')),'dd') AS INT)) dd ON (dd.d >= TRUNC(v.DATE_START)
                                                                                                                                    AND dd.d <= TRUNC(v.DATE_END))
     JOIN V_EMPLOYEES_FULL emp ON (emp."ФИО" = v.fio
                                    AND ('$fio' IS NULL
                                         OR REGEXP_LIKE (lower(emp."ФИО"), lower('$fio')))
                                    AND ('$proj'  IS NULL
                                         OR (REGEXP_LIKE (emp."Проекты", '$proj' )))-- REGEXP_LIKE ищет вхождение подстроки в строку
                                    AND ('$reg' IS NULL
                                         OR emp."Оформление" = '$reg')
                                    AND ('$dep' IS NULL
                                         OR emp."Подразделение" = '$dep'))

     JOIN jira.jiraISSUE
          ON jira.jiraISSUE.issuenum = v.issuenum
          WHERE  jira.jiraISSUE.issuestatus in (10015, 11507, 11705) and jira.jiraISSUE.PROJECT = 12883) dat     -- Done, Confirmation, Planning

  WHERE fio IS NOT NULL
     AND startdate IS NOT NULL) pivot(max(reason)
                                      FOR rn IN (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31)) t
ORDER BY 1







