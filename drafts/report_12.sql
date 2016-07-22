-- Author:            Polina Azarova
-- Date of creation:  20.05.2016
-- Description:       Report (Graph):
--                    KPI 
--                    the average quantity of defects found in production

--------------------------------------//12//---------------------------------------
SELECT
  tp.TEAM,
  -- количество багов, найденных в фазу тестирования Пром. эксплуатация
  count(cf.CFNAME) QUANTITY
FROM jira.JIRAISSUE j
  JOIN jira.PROJECT p ON j.PROJECT = p.ID
  JOIN V_REP_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
  JOIN jira.CUSTOMFIELDVALUE cfv ON cfv.ISSUE = j.ID
  JOIN jira.CUSTOMFIELD cf ON cf.ID = cfv.CUSTOMFIELD
  JOIN jira.CUSTOMFIELDOPTION cfo ON cfo.CUSTOMFIELD = cf.ID
WHERE j.ISSUETYPE IN (1, 41) AND
      -- [1]      Bug
      -- [41]     Дефект мобильного приложения
      cfv.CUSTOMFIELD = '11573' AND cfo.ID = '11848' AND -- 'Фаза тестирования' 'Пром. эксплуатация'
      TRUNC(j.CREATED) >= TRUNC(TO_DATE('2016-01-01', 'yyyy-mm-dd'))
GROUP BY tp.TEAM
