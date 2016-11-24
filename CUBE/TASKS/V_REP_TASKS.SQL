-- Author:            Polina Azarova
-- Date of creation:  27.07.2016
-- Description:       View for refactoring V_REP_TASKS_DURATION

CREATE OR REPLACE VIEW JIRA_READER.V_REP_TASKS AS
  SELECT
    'SCRUM' AGILE,
    scr.TEAM,
    scr.TYPE,
    scr.TASK_SIZE,
    scr.SUMMARY,
    scr.ISSUENUM,
    scr.START_DATE,
    scr.END_DATE
  FROM
    TABLE (JIRA_READER.REP_TASKS(3, 3, 10015)) scr -- 'In Progress', 'In Progress' -> 'Done'
  UNION
  SELECT
    'KANBAN' AGILE,
    knb.TEAM,
    knb.TYPE,
    knb.TASK_SIZE,
    knb.SUMMARY,
    knb.ISSUENUM,
    knb.START_DATE,
    knb.END_DATE
  FROM
    TABLE (JIRA_READER.REP_TASKS(10311, 10071, 10015)) knb -- 'Validation', 'Validation [IN PROGRESS]' -> 'Hot Support'
  UNION
  SELECT *
  FROM
    (SELECT
       'SUPER' AGILE,
       amb.TEAM,
       amb.TYPE,
       amb.TASK_SIZE,
       amb.SUMMARY,
       amb.ISSUENUM,
       amb.START_DATE,
       amb.END_DATE
     FROM
       TABLE (JIRA_READER.REP_TASKS(3, 3, 5)) amb
     WHERE TEAM IN ('X-MEN', 'The Guardians of the Galaxy', 'The Avengers')) am -- 'In Progress', 'In Progress' -> 'Resolved'
