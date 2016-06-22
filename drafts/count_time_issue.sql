-- Date of creation:  24.03.2016
-- Description:       The total time spent on tasks

SELECT sum(timespent) FROM JIRA.JIRAISSUE
  ORDER BY 1