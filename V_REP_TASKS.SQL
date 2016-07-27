-- Author:            Polina Azarova
-- Date of creation:  27.07.2016
-- Description:       View for refactoring V_REP_TASKS_DURATION

CREATE OR REPLACE VIEW JIRA_READER.V_REP_TASKS AS
  SELECT
    'SCRUM' AGILE,
    scr.*
  FROM
    TABLE (REP_TASKS('10106', '10014', '10015')) scr -- 'To Do', 'TОDO' -> 'Done'
  UNION
  SELECT
    'KANBAN' AGILE,
    knb.*
  FROM
    TABLE (REP_TASKS('11413', '10708', '11408')) knb -- 'Validation', 'Validation [IN PROGRESS]' -> 'Hot Support'
