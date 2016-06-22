-- Date of creation:  06.04.2016
-- Description:       A list of all projects (to upgrade confluence)

SELECT DISTINCT pname --A list of all projects Alfa-Bank > 2013
FROM jira.jiraissue
  JOIN jira.project ON jira.jiraissue.project = jira.project.id
WHERE to_date('2013-01-01', 'yyyy-mm-dd') < (jira.jiraissue.created)
ORDER BY 1

SELECT DISTINCT "Проекты" FROM V_EMPLOYEES_FULL --A list of all projects AlfaLab

