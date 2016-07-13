-- Author:            Polina Azarova
-- Date of creation:  13.07.2016
-- Description:       Report (Graph), the average duration of the task
--                    in the context of the type (User story / Bug / Task),
--                    size of the issue and the team for the period

-----------------------------------//09//--//10//-----------------------------------
CREATE OR REPLACE VIEW JIRA_READER.V_REP_TASKS_DURATION AS
SELECT
  tp.TEAM                               "Команда",
  it.PNAME                              "Тип",
  vs.VALUE                              "Размер задачи",
  TRUNC(AVG(cg.CREATED - j.CREATED), 2) "Длит-ть задачи"
FROM jira.JIRAISSUE j
  JOIN jira.PROJECT p ON j.PROJECT = p.ID
  JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
  JOIN jira.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
  JOIN jira.CUSTOMFIELDVALUE cfv ON j.ID = cfv.ISSUE
  JOIN V_SIZES vs ON cfv.STRINGVALUE = TO_CHAR(vs.ID)
  JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
  JOIN V_REP_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
WHERE ci.FIELD = 'status' AND TO_CHAR(ci.NEWSTRING) = 'Done'
GROUP BY tp.TEAM, it.PNAME, vs.VALUE
ORDER BY 1, 2, 3
