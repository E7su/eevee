-- Author:            Polina Azarova
-- Date of creation:  13.07.2016
-- Description:       View for eazyBI cube for reports (Graph):
--                     9. the average duration of the task
--                        in the context of the type (User story / Bug / Task)
--                        and the team for the period
--                    10. the average duration of the task in the context
--                        of the size of the issue and the team for the period
--                    11. the number of implemented tasks
--                        for the selected period in the sections:
--                        - commands and all;
--                        - size and problems in all sizes.

--------------------------//09//--//10//--//11//------------------------------------
CREATE OR REPLACE VIEW V_REP_TASKS_DURATION AS
  SELECT
    'SCRUM' AGILE,
    scr.*
  FROM TABLE (REP_TASKS('10106', '10014', '10015')) scr -- 'To Do', 'TОDO' -> 'Done'
  UNION
  SELECT
    'KANBAN' AGILE,
    knb.*
  FROM TABLE (REP_TASKS('11413', '10708', '11408')) knb -- 'Валидация [In Progress]', 'Validation [IN PROGRESS]' -> 'Hot Support'
