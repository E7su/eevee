-- Author:            Polina Azarova
-- Date of creation:  05.05.2016
-- Description:       Report (Graph):
--                    the number of implemented tasks
--                    for the selected period in the sections:
--                    -commands and all;
--                    -size and problems in all sizes.

--------------------------------------------//11//---------------------------------------------
SELECT
  tp.TEAM,
  vs.VALUE          TASK_SIZE,
  COUNT(j.ISSUENUM) QUANTITY
FROM jira.JIRAISSUE j
  JOIN jira.PROJECT p ON j.PROJECT = p.ID
  JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
  JOIN jira.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
  JOIN jira.CUSTOMFIELDVALUE cfv ON j.ID = cfv.ISSUE
  JOIN V_SIZES vs ON cfv.STRINGVALUE = TO_CHAR(vs.ID)
  JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
  JOIN V_REP_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
WHERE ci.FIELD = 'status' AND TO_CHAR(ci.NEWSTRING) = 'Done'
      AND TRUNC(j.CREATED) >= TRUNC(TO_DATE('$year_st-$month_st-01', 'yyyy-mm-dd'))
      AND TRUNC(cg.CREATED) <= TRUNC(ADD_MONTHS(TO_DATE('$year_st-$month_st-01', 'yyyy-mm-dd'), 1))
      AND ('$team' IS NULL OR tp.TEAM = '$team')
      AND ('$size' IS NULL OR vs.VALUE = '$size')
GROUP BY tp.TEAM, vs.VALUE
ORDER BY 1, 2 DESC
