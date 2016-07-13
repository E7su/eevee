-- Author:            Polina Azarova
-- Date of creation:  20.05.2016
-- Description:       A report on the number of bugs per release,
--                    found in the component, integration testing,
--                    and production environments for the selected period
--                    ​for selected command

--------------------------------------//12//---------------------------------------
SELECT
  tp.TEAM "Команда",
  COUNT(j.ID)
FROM jira.JIRAISSUE j
  JOIN jira.PROJECT p ON j.PROJECT = p.ID
  JOIN V_REP_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
WHERE j.ISSUESTATUS IN (10090, 11405, 11410, 10015) AND
      -- [10090]  Интеграционное тестирование [Done]
      -- [11405]  Component Test [Done]
      -- [11410]  Integration Test [Done]
      -- [10015]  Done
      j.issuetype IN
      (57, 49, 10603, 10702, 1, 41, 55, 10601, 42)
      -- [57]     Дефект
      -- [49]     Bug Sub-task
      -- [10603]  Дефект УС
      -- [10702]  Bugtask
      -- [1]      Bug
      -- [41]     Дефект мобильного приложения
      -- [55]     Дефект для доски
      -- [10601]  Дефект сервера
      -- [42]     Дефект бэка
GROUP BY tp.TEAM
