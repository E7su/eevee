-- Date of creation:  24.03.2016
-- Description:       The number of issue, which met after the deadline

SELECT DISTINCT  count(j.issuenum) ISSUE FROM JIRA.JIRAISSUE J
WHERE j.resolutiondate > j.duedate