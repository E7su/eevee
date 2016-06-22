-- Date of creation:  24.03.2016
-- Description:       Calculation issues by priority

SELECT priority, COUNT(priority)  FROM JIRA.JIRAISSUE
GROUP BY priority
  ORDER BY 1