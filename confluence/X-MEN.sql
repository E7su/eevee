-- Изменение численности X-MEN по месяцам
WITH dates (d) AS (
  SELECT to_date('2010-01-01', 'yyyy-mm-dd') AS d
  FROM dual --start
  UNION ALL
  SELECT add_months(d, 1) AS d
  FROM dates
  WHERE d < current_date --end
)
SELECT
  d,
  count(s."ФИО") "Всего, чел"
FROM dates
  -- to_char(d, 'dd-mm-yyyy')
  LEFT JOIN
  (SELECT
     j.SUMMARY      "ФИО",
     c2.DATEVALUE   "Дата приёма",
     c6.DATEVALUE   "Дата увольнения",
     o.CUSTOMVALUE  "Подразделение",
     o2.CUSTOMVALUE "Оформление",
     c5.DATEVALUE   "День рождения",
     CASE j.issuestatus
     WHEN '10809'
       THEN 'Open'
     ELSE 'Close'
     END            "Статус"
   FROM jira.JIRAISSUE j
     INNER JOIN jira.PROJECT p ON (j.PROJECT = p.ID)
     LEFT JOIN jira.CUSTOMFIELDVALUE c2 ON (c2.ISSUE = j.ID AND c2.CUSTOMFIELD = 12376)
     --дата приема на работу
     LEFT JOIN jira.CUSTOMFIELDVALUE c3 ON (c3.ISSUE = j.ID AND c3.CUSTOMFIELD = 12373)
     -- список подразделений
     LEFT JOIN jira.CUSTOMFIELDOPTION o ON (c3.STRINGVALUE = to_char(o.ID))
     -- непосредственно подразделение
     LEFT JOIN jira.CUSTOMFIELDVALUE c4 ON (c4.ISSUE = j.ID AND c4.CUSTOMFIELD = 12375)
     -- список возможных оформленеий
     LEFT JOIN jira.CUSTOMFIELDOPTION o2 ON (c4.STRINGVALUE = to_char(o2.ID))
     -- непосредственно оформление: штат/вентра и тд
     LEFT JOIN jira.CUSTOMFIELDVALUE c5 ON (c5.ISSUE = j.ID AND c5.CUSTOMFIELD = 12372)
     --ДР
     LEFT JOIN jira.CUSTOMFIELDVALUE c6 ON (c6.ISSUE = j.ID AND c6.CUSTOMFIELD = 12570) --Дата увольнения
   WHERE
     p.PKEY = 'EMP'
  ) s
    ON (dates.d >= s."Дата приёма" AND dates.d <= nvl(s."Дата увольнения", to_date('3000.01.01', 'yyyy-mm-dd')))
WHERE
  s."Подразделение" = 'X-MEN'
GROUP BY dates.d
ORDER BY 1


WITH dates (d) AS (
  SELECT to_date('2010-01-01', 'yyyy-mm-dd') AS d
  FROM dual --start
  UNION ALL
  SELECT add_months(d, 1) AS d
  FROM dates
  WHERE d < current_date --end
)
SELECT
  d,
  count(s."ФИО") "X-MEN, чел"
FROM dates
  -- to_char(d, 'dd-mm-yyyy')
  LEFT JOIN
  (SELECT
     j.SUMMARY      "ФИО",
     c2.DATEVALUE   "Дата приёма",
     c6.DATEVALUE   "Дата увольнения",
     o.CUSTOMVALUE  "Подразделение",
     o2.CUSTOMVALUE "Оформление",
     c5.DATEVALUE   "День рождения",
     CASE j.issuestatus
     WHEN '10809'
       THEN 'Open'
     ELSE 'Close'
     END            "Статус"
   FROM jira.JIRAISSUE j
     INNER JOIN jira.PROJECT p ON (j.PROJECT = p.ID)
     LEFT JOIN jira.CUSTOMFIELDVALUE c2 ON (c2.ISSUE = j.ID AND c2.CUSTOMFIELD = 12376)
     --дата приема на работу
     LEFT JOIN jira.CUSTOMFIELDVALUE c3 ON (c3.ISSUE = j.ID AND c3.CUSTOMFIELD = 12373)
     -- список подразделений
     LEFT JOIN jira.CUSTOMFIELDOPTION o ON (c3.STRINGVALUE = to_char(o.ID))
     -- непосредственно подразделение
     LEFT JOIN jira.CUSTOMFIELDVALUE c4 ON (c4.ISSUE = j.ID AND c4.CUSTOMFIELD = 12375)
     -- список возможных оформленеий
     LEFT JOIN jira.CUSTOMFIELDOPTION o2 ON (c4.STRINGVALUE = to_char(o2.ID))
     -- непосредственно оформление
     LEFT JOIN jira.CUSTOMFIELDVALUE c5 ON (c5.ISSUE = j.ID AND c5.CUSTOMFIELD = 12372)
     --ДР
     LEFT JOIN jira.CUSTOMFIELDVALUE c6 ON (c6.ISSUE = j.ID AND c6.CUSTOMFIELD = 12570) --Дата увольнения
   WHERE
     p.PKEY = 'EMP'
  ) s
    ON (dates.d >= s."Дата приёма" AND dates.d <= nvl(s."Дата увольнения", to_date('3000.01.01', 'yyyy-mm-dd')))
WHERE
  s."Подразделение" = 'X-MEN'
  AND s."Оформление" <> 'Штат'
GROUP BY dates.d
ORDER BY 1
