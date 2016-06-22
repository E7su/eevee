-- Date of creation:  20.05.2016
-- Description:       A report on the number of bugs per release,
--                    found in the component, integration testing,
--                    and production environments for the selected period
--                    ​for selected command

--------------------------------------//12//---------------------------------------
SELECT
  p.pname "Команда",
  count(j.id)
FROM JIRA.JIRAISSUE j
  JOIN jira.project p ON j.project = p.id
WHERE j.issuestatus IN (10090, 11405, 11410, 10015) AND
      -- [11405]  Component Test [Done]
      -- [11410]  Integration Test [Done]
      j.issuetype IN
      (57, 49, 10603, 10702, 1, 41, 55, 10601, 42)
      -- [57]     Дефект
      -- [49]     Bug Sub-task
      -- [1]      Bug
      -- [41]     Дефект мобильного приложения
      -- [10601]  Дефект сервера
      -- [42]     Дефект бэка
GROUP BY p.pname