-- Ближайшие годовщины работы
SELECT
  s."ФИО",
  to_char(s."Дата приёма", 'dd.mm.yyyy')                   "Дата приёма",
  CEIL(MONTHS_BETWEEN(CURRENT_DATE, s."Дата приёма") / 12) "Работает, лет"
FROM (
       SELECT
         j.SUMMARY      "ФИО",
         c2.DATEVALUE   "Дата приёма",
         c6.DATEVALUE   "Дата увольнения",
         o.CUSTOMVALUE  "Подразделение",
         o2.CUSTOMVALUE "Оформление",
         c5.DATEVALUE   "День рождения",
         CURRENT_DATE - c5.DATEVALUE,
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
WHERE
  s."Статус" = 'Open'
  AND s."Подразделение" = 'X-MEN'
  AND MOD(MONTHS_BETWEEN(CURRENT_DATE, s."Дата приёма"), 12) > 10
ORDER BY MOD(MONTHS_BETWEEN(CURRENT_DATE, s."Дата приёма"), 12) DESC