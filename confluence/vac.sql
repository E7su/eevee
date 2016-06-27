-- Ближайшие отсутствия
select
COALESCE(u1.DISPLAY_NAME, u2.DISPLAY_NAME, j.REPORTER) "ФИО",
c1.DATEVALUE "Дата начала",
c2.DATEVALUE "Дата окончания",
o.CUSTOMVALUE "Причина",
'{jira:' || p.PKEY || '-' || j.ISSUENUM || '}'  "Ид"
--'{jira:url=http://jira/sr/jira.issueviews:searchrequest-xml/temp/SearchRequest.xml?jqlQuery=key+%3D+' || p.PKEY || '-' || j.ISSUENUM || '|columns=key}'
from jira.JIRAISSUE j
inner join jira.PROJECT p on (j.PROJECT = p.ID)
left join jira.CUSTOMFIELDVALUE c1 on (c1.ISSUE = j.ID and c1.CUSTOMFIELD = 12672) --дата начала отсутствия
left join jira.CUSTOMFIELDVALUE c2 on (c2.ISSUE = j.ID and c2.CUSTOMFIELD = 12673) --дата окончания отсутствия
left join jira.CUSTOMFIELDVALUE c3 on (c3.ISSUE = j.ID and c3.CUSTOMFIELD = 12482) --идентификатор причина отсутствия
left join jira.CUSTOMFIELDOPTION o on (c3.STRINGVALUE = to_char(o.ID)) -- непосредственно причина отсутствия в виде строки
left join jira.CWD_USER u1 on (lower(j.REPORTER) = u1.LOWER_USER_NAME)
left join jira.CWD_USER u2 on (u2.LOWER_EMAIL_ADDRESS like lower(j.REPORTER) || '@%') --не все пользователи ищутся по LOWER_USER_NAME, пробуем найти по email
where
p.PKEY = 'VAC'
and c2.DATEVALUE >= CURRENT_DATE --вытаскиваем все отсутствия которые заканчиваются сегодня и начинаются в ближайший месяц
and c1.DATEVALUE < add_months(CURRENT_DATE, 1)
order by 1,2

-- Истечение доступа в сеть банка
select
j.SUMMARY "ФИО",
to_char(c1.DATEVALUE, 'dd.mm.yyyy') "Дата истечения"
from jira.JIRAISSUE j
left join jira.CUSTOMFIELDVALUE c1 on (c1.ISSUE = j.ID and c1.CUSTOMFIELD = 12572) --дата истечения доступа в сеть банка
where
c1.DATEVALUE >= CURRENT_DATE --вытаскиваем все истечения, которые могут случиться в ближайший месяц
and c1.DATEVALUE < add_months(CURRENT_DATE, 1)
order by c1.DATEVALUE
