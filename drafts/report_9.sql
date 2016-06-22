-- Date of creation:  05.05.2016
-- Description:       Report (Graph ), the average duration of the task
--                    in the context of the type ( User story / Bug / Task)
--                    and the team for the period

--------------------------------------//09//---------------------------------------

SELECT
  p.pname                     "Команда",
  it.pname                    "Тип",
  AVG(cg.created - j.created) "Длит-ть задачи"
FROM JIRA.JIRAISSUE j
  JOIN jira.project p ON j.project = p.id
  JOIN jira.issuetype it ON j.issuetype = it.id
  JOIN jira.changegroup cg ON (cg.issueid = j.id)
  JOIN jira.changeitem ci ON (ci.groupid = cg.id)
WHERE it.pname IN ('User Story', 'Bug', 'Task')
    --   AND TRUNC(j.created) >= TRUNC(to_date('$year_st-$month_st-$day_st', 'yyyy-mm-dd'))
    --   AND TRUNC(cg.created) <= TRUNC(to_date('$year_end-$month_end-$day_end', 'yyyy-mm-dd'))
    --   AND p.pname = '$team' AND it.pname = '$type'
      AND ci.field = 'status' AND to_char(newstring) = 'Done'
GROUP BY p.pname, it.pname
ORDER BY 1
