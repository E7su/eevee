-- Date of creation:  24.03.2016
-- Description:       The number of issue, that people started on itself

SELECT DISTINCT  count(j.issuenum) ISSUE FROM JIRA.JIRAISSUE J
WHERE j.assignee = j.reporter