-- Author:            Polina Azarova
-- Date of creation:  05.05.2016
-- Description:       Report (Graph):
--                    the average duration of the task
--                    in the context of the type (User story / Bug / Task)
--                    and the team for the period

--------------------------------------//09//---------------------------------------
SELECT
  tp.TEAM,
  it.PNAME                              TYPE,
  TRUNC(AVG(cg.CREATED - j.CREATED), 2) DURATION
FROM JIRA.JIRAISSUE j
  JOIN jira.PROJECT p ON j.PROJECT = p.ID
  JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
  JOIN jira.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
  JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
  JOIN V_REP_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
WHERE it.PNAME IN ('User Story', 'Bug', 'Task')
      AND TRUNC(j.CREATED) >= TRUNC(TO_DATE('$year_st-$month_st-01', 'yyyy-mm-dd'))
      AND TRUNC(cg.CREATED) <= TRUNC(ADD_MONTHS(TO_DATE('$year_st-$month_st-01', 'yyyy-mm-dd'), 1))
      AND ('$team' IS NULL OR tp.TEAM = '$team')
      AND ('$type' IS NULL OR it.PNAME = '$type')
      AND ci.FIELD = 'status' AND TO_CHAR(ci.NEWSTRING) = 'Done'
GROUP BY tp.TEAM, it.PNAME
ORDER BY 1
