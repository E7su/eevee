create or replace view v_epic_task as
select
j2.SUMMARY "Epic",
p2.PKEY || '-' || j2.ISSUENUM "Номер epic",
j2.id "Ид epic",
c1.STRINGVALUE "Название epic",
p1.PNAME "Проект задачи",
j1.id "Ид задачи",
j1.SUMMARY "Название задачи",
p1.PKEY || '-' || j1.ISSUENUM "Номер задачи",
j1.CREATED "Дата создан здч",
t.PNAME "Тип задачи",
o1.CUSTOMVALUE "Размер",
j1.DUEDATE "Срок исполнения",
j1.TIMEORIGINALESTIMATE,
j1.TIMEESTIMATE,
j1.TIMESPENT
from
jira.JIRAISSUE j1 --user story/task/bug
left join jira.PROJECT p1 on (j1.PROJECT = p1.ID)
left join jira.ISSUELINK ln1 on (j1.ID = ln1.DESTINATION and ln1.LINKTYPE = 10070) --ищем эпик
left join jira.JIRAISSUE j2 on (j2.ID = ln1.SOURCE and j2.ISSUETYPE = 34) --epic
left join jira.CUSTOMFIELDVALUE c1 on (c1.ISSUE = j2.ID and c1.CUSTOMFIELD = 10377) --получаем название эпика из кастомполя
left join jira.PROJECT p2 on (j2.PROJECT = p2.ID)
left join jira.CUSTOMFIELDVALUE c2 on (c2.ISSUE = j1.ID and c2.CUSTOMFIELD = 12484) --ид issue size в майках
left join jira.CUSTOMFIELDOPTION o1 on (c2.STRINGVALUE = to_char(o1.ID)) -- непосредственно issue size в майках: L/M/S и тд
left join jira.ISSUETYPE t on (t.id = j1.ISSUETYPE)
