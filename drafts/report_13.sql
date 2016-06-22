-- Date of creation:  23.05.2016
-- Description:       A report on the average length of the work
--                    for the selected period in the context of administration,
--                    registration ( state / vendor )

--------------------------------------//13//---------------------------------------
SELECT
  --c2.DATEVALUE                                                                 "Дата приёма",
  --c6.DATEVALUE                                                                 "Дата увольнения",
  o.CUSTOMVALUE  "Подразделение",
  o2.CUSTOMVALUE "Оформление",
  avg(ROUND(MONTHS_BETWEEN(NVL(c6.DATEVALUE, CURRENT_DATE), c2.DATEVALUE) / 12, 1)) "Время работы"
--стаж в годах, для уволенных - на дату увольнения, для работающих - на текущую дату
FROM jira.JIRAISSUE j
  INNER JOIN jira.PROJECT p ON (j.PROJECT = p.ID)
  LEFT JOIN jira.CUSTOMFIELDVALUE c2 ON (c2.ISSUE = j.ID AND c2.CUSTOMFIELD = 12376)
  --дата приема на работу
  LEFT JOIN jira.CUSTOMFIELDVALUE c3 ON (c3.ISSUE = j.ID AND c3.CUSTOMFIELD = 12373)
  -- список подразделений
  LEFT JOIN jira.CUSTOMFIELDOPTION o ON (c3.STRINGVALUE = TO_CHAR(o.ID))
  -- непосредственно подразделение
  LEFT JOIN jira.CUSTOMFIELDVALUE c4 ON (c4.ISSUE = j.ID AND c4.CUSTOMFIELD = 12375)
  -- список возможных оформленеий
  LEFT JOIN jira.CUSTOMFIELDOPTION o2 ON (c4.STRINGVALUE = TO_CHAR(o2.ID))
  -- непосредственно оформление
  LEFT JOIN jira.CUSTOMFIELDVALUE c6 ON (c6.ISSUE = j.ID AND c6.CUSTOMFIELD = 12570)
  --Дата увольнения
  LEFT JOIN
  (SELECT
     u2.ID,
     u2.USER_NAME,
     u2.EMAIL_ADDRESS,
     u2.LOWER_DISPLAY_NAME
   FROM --нужно для удаления дубликатов записей, см например по Саевскому
     (SELECT
        MAX(u.id) id,
        u.LOWER_DISPLAY_NAME
      FROM jira.CWD_USER u
      WHERE u.ACTIVE = 1
      GROUP BY u.LOWER_DISPLAY_NAME
     ) u1 INNER JOIN jira.CWD_USER u2
       ON (u1.ID = u2.ID) --where u2.LOWER_DISPLAY_NAME = lower('Magneto')
  ) usr ON (usr.LOWER_DISPLAY_NAME = lower(j.SUMMARY)) --для получения логина/email пользователя
WHERE p.PKEY = 'EMP' -- AND o2.CUSTOMVALUE = 'Штат'
GROUP BY
  o.CUSTOMVALUE,
  o2.CUSTOMVALUE
ORDER BY 1, 2, 3