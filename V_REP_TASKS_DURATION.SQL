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
  SELECT *
  FROM
    (SELECT
       n.AGILE,
       n.TEAM,
       n.TYPE,
       n.TASK_SIZE,
       n.SUMMARY,
       n.ISSUENUM,
       -- обработка случая, когда задача несколько раз переходила в статус завершения
       -- берём дату последнего перехода
       MAX(n.END_DATE) END_DATE,
       MAX(n.DURATION) DURATION,
       n.QUANTITY -- количество внедрённых задач
     FROM (SELECT
             rt.AGILE,
             rt.TEAM,
             rt.TYPE,
             rt.TASK_SIZE,
             rt.SUMMARY,
             rt.ISSUENUM,
             rt.END_DATE,
             rt.END_DATE - rt.START_DATE DURATION,
             1                           QUANTITY
           FROM JIRA_READER.V_REP_TASKS rt
          ) n
     WHERE n.DURATION > 0
     GROUP BY n.AGILE, n.TEAM, n.TYPE, n.TASK_SIZE, n.SUMMARY, n.ISSUENUM, n.QUANTITY) nn
    JOIN (SELECT
            vs.SCORE,
            vs.VALUE
          FROM JIRA_READER.V_SIZES vs) s ON s.VALUE = nn.TASK_SIZE
  ORDER BY 1, 2
