-- Date of creation:  24.03.2016
-- Description:       Displays the number of issues on a particular project, the project is given by id 

SELECT DISTINCT avg(j.project) Project, count(j.issuenum) ISSUE FROM JIRA.JIRAISSUE J 
WHERE j.project = 10251 -- пример