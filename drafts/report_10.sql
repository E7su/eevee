-- Author:            Polina Azarova
-- Date of creation:  05.05.2016
-- Description:       Report (Graph ), the average duration of the task in the context 
--                    of the size of the issue and the team for the period

--------------------------------------//10//---------------------------------------
SELECT
  tp.TEAM                               "Команда",
  vs.VALUE                              "Размер задачи",
  TRUNC(AVG(cg.CREATED - j.CREATED), 2) "Длит-ть задачи"
FROM JIRA.JIRAISSUE j
  JOIN jira.PROJECT p ON j.PROJECT = p.ID
  JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
  JOIN jira.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
  JOIN jira.CUSTOMFIELDVALUE cfv ON j.ID = cfv.ISSUE
  JOIN V_SIZES vs ON cfv.STRINGVALUE = TO_CHAR(vs.ID)
  JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
  JOIN JIRA_READER.V_STATIC_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
WHERE ci.FIELD = 'status' AND TO_CHAR(ci.NEWSTRING) = 'Done'
      AND TRUNC(j.CREATED) >= TRUNC(TO_DATE('2016-01-01', 'yyyy-mm-dd'))
      AND TRUNC(j.CREATED) >= TRUNC(TO_DATE('$year_st-$month_st-$day_st', 'yyyy-mm-dd'))
      AND TRUNC(cg.CREATED) <= TRUNC(TO_DATE('$year_end-$month_end-$day_end', 'yyyy-mm-dd'))
      AND ('$team' IS NULL OR tp.TEAM = '$team')
      AND ('$size' IS NULL OR vs.VALUE = '$size')
GROUP BY tp.TEAM, vs.VALUE
ORDER BY 1, 2 DESC
