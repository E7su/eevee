-- Author:            Polina Azarova
-- Date of creation:  27.07.2016
-- Description:       View for refactoring V_REP_TASKS_DURATION

CREATE OR REPLACE VIEW JIRA_READER.V_REP_TASKS AS
  SELECT
    'SCRUM'              AGILE,
    scr.TEAM,
    scr.TYPE,
    scr.TASK_SIZE,
    TO_CHAR(scr.SUMMARY) SUMMARY,
    scr.ISSUENUM,
    scr.ISSUEID,
    scr.START_DATE,
    scr.END_DATE
  FROM
    TABLE (JIRA_READER.REP_TASKS(3, 3, 10015)) scr -- 'In Progress', 'In Progress' -> 'Done'
  UNION
  SELECT
    'KANBAN'             AGILE,
    knb.TEAM,
    knb.TYPE,
    knb.TASK_SIZE,
    TO_CHAR(knb.SUMMARY) SUMMARY,
    knb.ISSUENUM,
    knb.ISSUEID,
    knb.START_DATE,
    knb.END_DATE
  FROM
    TABLE (JIRA_READER.REP_TASKS(10311, 10071, 10015)) knb -- 'Validation', 'Validation [IN PROGRESS]' -> 'Hot Support'
