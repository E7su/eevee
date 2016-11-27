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
    m.AGILE,
    n.TEAM,
    n.TYPE,
    n.TASK_SIZE,
    n.SUMMARY,
    n.ISSUENUM,
    n.SCORE,
    n.END_DATE,
    m.DURATION,
    1 QUANTITY -- количество внедрённых задач
  FROM (SELECT
          rt.TEAM,
          rt.TYPE,
          rt.TASK_SIZE,
          rt.SUMMARY,
          rt.ISSUENUM,
          rt.ISSUEID,
          rt.END_DATE,
          rt.SCORE
        FROM JIRA_READER.V_REP_TASKS rt
       ) n
    JOIN
    (SELECT
       f.AGILE,
       f.TEAM,
       f.TYPE,
       f.TASK_SIZE,
       f.ISSUEID,
       f.DURATION DURATION
     FROM (SELECT
             rt.AGILE,
             rt.TEAM,
             rt.TYPE,
             rt.TASK_SIZE,
             rt.ISSUEID,
             (rt.END_DATE -
              rt.START_DATE) DURATION -- длительность задачи
           FROM JIRA_READER.V_REP_TASKS rt
          ) f
     WHERE f.DURATION > 0) m
      ON m.ISSUEID = n.ISSUEID
  ORDER BY 1, 2
