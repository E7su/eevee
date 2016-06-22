-- Date of creation:  24.03.2016
-- Description:       The creation date of the project

SELECT * FROM
  (SELECT
     pname,
     extract(MONTH FROM created) month,
     extract(YEAR FROM created) year
  FROM (
     SELECT DISTINCT
       pname,
       MIN(TRUNC(jira.jiraissue.created)) created
     FROM jira.jiraissue
       JOIN jira.project ON jira.jiraissue.project = jira.project.id
     GROUP BY pname
     HAVING to_date('2013-01-01', 'yyyy-mm-dd') < MIN(jira.jiraissue.created)
            AND MIN(jira.jiraissue.created) < to_date('2020-12-31', 'yyyy-mm-dd'))
  )pivot(COUNT(pname)
  FOR month IN (01,02,03,04,05,06,07,08,09,10,11,12))

order by 1