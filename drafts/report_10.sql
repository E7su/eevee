-- Date of creation:  05.05.2016
-- Description:       Report (Graph ), the average duration of the task in the context 
--                    of the size of the issue and the team for the period

--------------------------------------//10//---------------------------------------
SELECT
  p.pname                               "Команда",
  vs.value                              "Размер задачи",
  TRUNC(AVG(cg.created - j.created), 2) "Длит-ть задачи"
FROM JIRA.JIRAISSUE j
  JOIN jira.project p ON j.project = p.id
  JOIN jira.issuetype it ON j.issuetype = it.id
  JOIN jira.changegroup cg ON (cg.issueid = j.id)
  JOIN jira.customfieldvalue cfv ON j.id = cfv.issue
  JOIN V_SIZES vs ON cfv.stringvalue = to_char(vs.id)
  JOIN jira.changeitem ci ON (ci.groupid = cg.id)
WHERE ci.field = 'status' AND to_char(newstring) = 'Done'
      AND TRUNC(j.created) >= TRUNC(to_date('2016-01-01', 'yyyy-mm-dd'))
--   AND TRUNC(j.created) >= TRUNC(to_date('$year_st-$month_st-$day_st', 'yyyy-mm-dd'))
--   AND TRUNC(cg.created) <= TRUNC(to_date('$year_end-$month_end-$day_end', 'yyyy-mm-dd'))
--   AND p.pname = '$team' AND it.pname = '$size'
GROUP BY p.pname, value
ORDER BY 1, 2 desc