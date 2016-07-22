-- Author:            Polina Azarova
-- Date of creation:  20.05.2016
-- Description:       Report (Graph):
--                    KPI
--                    the average quantity of defects found in production

--------------------------------------//12//---------------------------------------
----------------------------------//числитель//------------------------------------
SELECT
  ch.TEAM,
  ch.PNAME                           PROJECT,
  ROUND(ch.QUANTITY / zn.REGRESS, 2) KPI
FROM
  (SELECT
     tp.TEAM,
     p.PNAME,
     -- количество багов, найденных в фазу тестирования Пром. эксплуатация
     count(cf.CFNAME) QUANTITY
   FROM jira.JIRAISSUE j
     JOIN jira.PROJECT p ON j.PROJECT = p.ID
     LEFT JOIN V_REP_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
     JOIN jira.CUSTOMFIELDVALUE cfv ON cfv.ISSUE = j.ID
     JOIN jira.CUSTOMFIELD cf ON cf.ID = cfv.CUSTOMFIELD
     JOIN jira.CUSTOMFIELDOPTION cfo ON cfo.CUSTOMFIELD = cf.ID
   WHERE j.ISSUETYPE IN (1, 41) AND
         -- [1]      Bug
         -- [41]     Дефект мобильного приложения
         cfv.CUSTOMFIELD = '11573' AND cfo.ID = '11848' AND -- 'Фаза тестирования' 'Пром. эксплуатация'
         TRUNC(j.CREATED) >= TRUNC(TO_DATE('2016-01-01', 'yyyy-mm-dd'))
   GROUP BY tp.TEAM, p.PNAME) ch
  JOIN
  ---------------------------------//знаменатель//-----------------------------------
  (SELECT
     tp.TEAM,
     p.PNAME,
     count(j.id) REGRESS
   FROM jira.JIRAISSUE j
     JOIN jira.PROJECT p ON j.PROJECT = p.ID
     LEFT JOIN V_REP_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
     JOIN jira.LABEL Lb ON Lb.ISSUE = j.id
   WHERE j.ISSUETYPE IN (1, 41) AND
         -- [1]      Bug
         -- [41]     Дефект мобильного приложения
         TRUNC(j.CREATED) >= TRUNC(TO_DATE('2016-01-01', 'yyyy-mm-dd')) AND LABEL = 'Регресс'
   GROUP BY tp.TEAM, p.PNAME) zn ON ch.PNAME = zn.PNAME
