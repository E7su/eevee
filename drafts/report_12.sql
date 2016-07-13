-- Author:            Polina Azarova
-- Date of creation:  20.05.2016
-- Description:       A report on the number of bugs per release,
--                    found in the component, integration testing,
--                    and production environments for the selected period
--                    for selected command

--------------------------------------//12//---------------------------------------
SELECT
  tp.TEAM     "Команда",
  COUNT(j.ID) "Баги",
  CASE j.ISSUESTATUS
  WHEN '11405'
    THEN 'Component Test'
  WHEN '11410'
    THEN 'Integration Test'
  WHEN '10015'
    THEN 'Production'
  WHEN '10088'
    THEN 'Component Test'
  ELSE ''
  END         "Этап"
FROM jira.JIRAISSUE j
  JOIN jira.PROJECT p ON j.PROJECT = p.ID
  JOIN V_REP_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
WHERE j.ISSUESTATUS IN (11405, 11410, 10015, 10088) AND
      -- [11405]  Component Test [Done]
      -- [11410]  Integration Test [Done]
      -- [10015]  Done
      -- [10088]  Компонентное тестирование [Done]
      j.ISSUETYPE IN
      (57, 49, 10603, 10702, 1, 41, 55, 10601, 42)
      -- [1]      Bug
GROUP BY tp.TEAM, j.ISSUESTATUS
