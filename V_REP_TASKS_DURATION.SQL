-- Author:            Polina Azarova
-- Date of creation:  13.07.2016
-- Description:       View for eazyBI cube for reports (graph):
--                    9.  the average duration of the task
--                        in the context of the type (User story / Bug / Task)
--                        and the team for the period
--                    10. the average duration of the task in the context
--                        of the size of the issue and the team for the period
--                    11. the number of implemented tasks
--                        for the selected period in the sections :
--                        -commands and all;
--                        -size and problems in all sizes
--                    12. the number of bugs per release,
--                        found in the component, integration testing,
--                        and production environments for the selected period
--                        for selected command

-----------------------//09//--//10//--//11//--//12//-------------------------------
CREATE OR REPLACE VIEW JIRA_READER.V_REP_TASKS_DURATION AS
  SELECT
    tp.TEAM                               "Команда",
    it.PNAME                              "Тип",
    vs.VALUE                              "Размер задачи",
    COUNT(j.ISSUENUM)                     "Количество issue",
    TRUNC(AVG(cg.CREATED - j.CREATED), 2) "Длит-ть задачи",
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
    END                                   "Этап"
  FROM jira.JIRAISSUE j
    JOIN jira.PROJECT p ON j.PROJECT = p.ID
    JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
    JOIN jira.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
    JOIN jira.CUSTOMFIELDVALUE cfv ON j.ID = cfv.ISSUE
    JOIN V_SIZES vs ON cfv.STRINGVALUE = TO_CHAR(vs.ID)
    JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
    JOIN V_REP_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
--   WHERE ci.FIELD = 'status' AND TO_CHAR(ci.NEWSTRING) = 'Done'
  GROUP BY tp.TEAM, it.PNAME, vs.VALUE, j.ISSUESTATUS
  ORDER BY 1, 2, 3;
