SELECT COALESCE(u1.DISPLAY_NAME, u2.DISPLAY_NAME, j.REPORTER) "ФИО",
       c1.DATEVALUE "Дата начала",
       c2.DATEVALUE "Дата окончания",
       '<a href="http://jira/browse/' || p.PKEY || '-' || j.issuenum || '">' || o.CUSTOMVALUE || '</a>' "Причина"
FROM jira.JIRAISSUE j
INNER JOIN jira.PROJECT p ON (j.PROJECT = p.ID)
LEFT JOIN jira.CUSTOMFIELDVALUE c1 ON (c1.ISSUE = j.ID
                                       AND c1.CUSTOMFIELD = 12672)--дата начала отсутствия
LEFT JOIN jira.CUSTOMFIELDVALUE c2 ON (c2.ISSUE = j.ID
                                       AND c2.CUSTOMFIELD = 12673)--дата окончания отсутствия
LEFT JOIN jira.CUSTOMFIELDVALUE c3 ON (c3.ISSUE = j.ID
                                       AND c3.CUSTOMFIELD = 12871)--идентификатор причина отсутствия
LEFT JOIN jira.CUSTOMFIELDOPTION o ON (c3.STRINGVALUE = to_char(o.ID))-- непосредственно причина отсутствия в виде строки
LEFT JOIN jira.CWD_USER u1 ON (lower(j.REPORTER) = u1.LOWER_USER_NAME)
LEFT JOIN JIRA.APP_USER uj ON (uj.USER_KEY = j.REPORTER AND uj.USER_KEY != uj.LOWER_USER_NAME)
LEFT JOIN JIRA.CWD_USER u2 ON (u2.LOWER_USER_NAME = uj.LOWER_USER_NAME)
WHERE p.PKEY = 'VAC'
  AND c2.DATEVALUE >= CURRENT_DATE --вытаскиваем все отсутствия которые заканчиваются сегодня и начинаются в ближайший месяц
AND c1.DATEVALUE < (CURRENT_DATE + interval '14' DAY)
ORDER BY 2,3

