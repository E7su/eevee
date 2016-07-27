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
  SELECT DISTINCT
    n.*,
    m.DURATION,
    m.QUANTITY -- количество внедрённых задач
  FROM (SELECT
          rt.TEAM,
          rt.TYPE,
          rt.TASK_SIZE,
          rt.SUMMARY,
          rt.ISSUENUM,
          rt.END_DATE
        FROM V_REP_TASKS rt
       ) n
    JOIN
    (SELECT
       f.TEAM,
       f.TYPE,
       f.TASK_SIZE,
       COUNT(f.TEAM)   QUANTITY,
       SUM(f.DURATION) DURATION
     FROM (SELECT
             rt.TEAM,
             rt.TYPE,
             rt.TASK_SIZE,
             (rt.END_DATE -
              rt.START_DATE) DURATION -- длительность задачи
           FROM V_REP_TASKS rt
          ) f
     WHERE f.DURATION > 0
     GROUP BY f.TEAM, f.TYPE, f.TASK_SIZE) m
      ON m.TEAM = n.TEAM AND m.TYPE = n.TYPE AND m.TASK_SIZE = n.TASK_SIZE
