-- Ближайшие дни рождения
select
s."ФИО",
to_char(s."День рождения", 'dd.mm.yyyy') "День рождения",
CEIL(MONTHS_BETWEEN(CURRENT_DATE, s."День рождения")/12) "Возраст, лет",
ROUND(MONTHS_BETWEEN(CURRENT_DATE, s."Дата приёма")/12, 1) "Работает, лет"
from (
select
j.SUMMARY "ФИО",
c2.DATEVALUE "Дата приёма",
c6.DATEVALUE "Дата увольнения",
o.CUSTOMVALUE "Подразделение",
o2.CUSTOMVALUE "Оформление",
c5.DATEVALUE "День рождения",
CURRENT_DATE - c5.DATEVALUE,
CASE j.issuestatus
 WHEN '10809'
 THEN 'Open'
 ELSE 'Close'
END "Статус"
from jira.JIRAISSUE j
inner join jira.PROJECT p on (j.PROJECT = p.ID)
left join jira.CUSTOMFIELDVALUE c2 on (c2.ISSUE = j.ID and c2.CUSTOMFIELD = 12376) --дата приема на работу
left join jira.CUSTOMFIELDVALUE c3 on (c3.ISSUE = j.ID and c3.CUSTOMFIELD = 12373) -- список подразделений
left join jira.CUSTOMFIELDOPTION o on (c3.STRINGVALUE = to_char(o.ID)) -- непосредственно подразделение
left join jira.CUSTOMFIELDVALUE c4 on (c4.ISSUE = j.ID and c4.CUSTOMFIELD = 12375) -- список возможных оформленеий
left join jira.CUSTOMFIELDOPTION o2 on (c4.STRINGVALUE = to_char(o2.ID)) -- непосредственно оформление: штат/вентра и тд
left join jira.CUSTOMFIELDVALUE c5 on (c5.ISSUE = j.ID and c5.CUSTOMFIELD = 12372) --ДР
left join jira.CUSTOMFIELDVALUE c6 on (c6.ISSUE = j.ID and c6.CUSTOMFIELD = 12570) --Дата увольнения
where
p.PKEY = 'EMP'
) s
where
s."Статус" = 'Open'
and s."Подразделение" = 'X-MEN'
and MOD(MONTHS_BETWEEN(CURRENT_DATE, s."День рождения"), 12) > 10
order by MOD(MONTHS_BETWEEN(CURRENT_DATE, s."День рождения"), 12) desc
