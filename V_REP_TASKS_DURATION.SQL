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
-- CREATE OR REPLACE VIEW V_REP_TASKS_DURATION AS
--------------------------------//SCRUM//-------------------------------------------
(SELECT DISTINCT
  'SCRUM' AGILE,
  n.*,
  m.DURATION,
  m.QUANTITY
FROM (SELECT
        t.TEAM,
        t.TYPE,
        t.TASK_SIZE,
        t.SUMMARY,
        t.ISSUENUM,
        d.END_DATE
      FROM
        (SELECT
           cg.ISSUEID,
           j.SUMMARY,
           j.ISSUENUM,
           tp.TEAM,
           it.PNAME TYPE,
           vs.VALUE TASK_SIZE
         FROM jira.JIRAISSUE j
           JOIN jira.PROJECT p ON j.PROJECT = p.ID
           JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
           JOIN jira.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
           JOIN jira.CUSTOMFIELDVALUE cfv ON j.ID = cfv.ISSUE
           JOIN V_SIZES vs ON cfv.STRINGVALUE = TO_CHAR(vs.ID)
           JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
           JOIN V_REP_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
         WHERE
           ci.FIELD = 'status' AND
           TO_CHAR(ci.NEWVALUE) = '10106' OR TO_CHAR(ci.NEWVALUE) = '10014' -- 'To Do' и 'TODO'
         --AND j.CREATED > TO_DATE('2016-01-01', 'yyyy-mm-dd')
         GROUP BY cg.ISSUEID, j.SUMMARY, j.ISSUENUM, tp.TEAM, it.PNAME, vs.VALUE
        ) t
        JOIN
        (SELECT
           cg.ISSUEID,
           cg.CREATED END_DATE
         FROM jira.CHANGEGROUP cg
           JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
         WHERE ci.FIELD = 'status' AND TO_CHAR(ci.NEWVALUE) = '10015' -- 'Done'
          -- AND j.CREATED > TO_DATE('2016-01-01', 'yyyy-mm-dd')
        ) d
          ON d.ISSUEID = t.ISSUEID) n
  JOIN
  (SELECT
     f.TEAM,
     f.TYPE,
     f.TASK_SIZE,
     COUNT(f.ISSUEID)          QUANTITY,
     ROUND(AVG(f.DURATION), 2) DURATION
   FROM (SELECT
           t.TEAM,
           t.TYPE,
           t.TASK_SIZE,
           t.ISSUEID,
           (d.END_DATE - t.START_DATE) DURATION -- длительность задачи для скрам команд (по переходу с To Do в Done)
         FROM
           (SELECT
              cg.ISSUEID,
              tp.TEAM,
              it.PNAME   TYPE,
              vs.VALUE   TASK_SIZE,
              cg.CREATED START_DATE -- дата перехода в статус To Do
            FROM jira.JIRAISSUE j
              JOIN jira.PROJECT p ON j.PROJECT = p.ID
              JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
              JOIN jira.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
              JOIN jira.CUSTOMFIELDVALUE cfv ON j.ID = cfv.ISSUE
              JOIN V_SIZES vs ON cfv.STRINGVALUE = TO_CHAR(vs.ID)
              JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
              JOIN V_REP_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
            WHERE
              ci.FIELD = 'status' AND
              TO_CHAR(ci.NEWVALUE) = '10106' OR TO_CHAR(ci.NEWVALUE) = '10014' -- 'To Do' и 'TODO'
             --AND j.CREATED > TO_DATE('2016-01-01', 'yyyy-mm-dd')
           ) t
           JOIN
           (SELECT
              cg.ISSUEID,
              cg.CREATED END_DATE -- дата перехода в статус Done
            FROM jira.CHANGEGROUP cg
              JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
            WHERE ci.FIELD = 'status' AND
                  TO_CHAR(ci.NEWVALUE) = '10015' -- AND j.CREATED > TO_DATE('2016-01-01', 'yyyy-mm-dd')
           ) d
             ON d.ISSUEID = t.ISSUEID
        ) f
   WHERE f.DURATION > 0
   GROUP BY f.TEAM, f.TYPE, f.TASK_SIZE) m
    ON m.TEAM = n.TEAM AND m.TYPE = n.TYPE AND m.TASK_SIZE = n.TASK_SIZE
UNION ALL
--------------------------------//KANBAN//-------------------------------------------
SELECT DISTINCT
  'KANBAN' AGILE,
  n.*,
  m.DURATION,
  m.QUANTITY
FROM (SELECT
        t.TEAM,
        t.TYPE,
        t.TASK_SIZE,
        t.SUMMARY,
        t.ISSUENUM,
        d.END_DATE
      FROM
        (SELECT
           cg.ISSUEID,
           j.SUMMARY,
           j.ISSUENUM,
           tp.TEAM,
           it.PNAME TYPE,
           vs.VALUE TASK_SIZE
         FROM jira.JIRAISSUE j
           JOIN jira.PROJECT p ON j.PROJECT = p.ID
           JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
           JOIN jira.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
           JOIN jira.CUSTOMFIELDVALUE cfv ON j.ID = cfv.ISSUE
           JOIN V_SIZES vs ON cfv.STRINGVALUE = TO_CHAR(vs.ID)
           JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
           JOIN V_REP_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
         WHERE
           ci.FIELD = 'status' AND
           TO_CHAR(ci.NEWVALUE) = '10081' OR -- 'Валидация [In progress]'
           TO_CHAR(ci.NEWVALUE) = '10708' -- 'Validation [IN PROGRESS]'
         --AND j.CREATED > TO_DATE('2016-01-01', 'yyyy-mm-dd')
         GROUP BY cg.ISSUEID, j.SUMMARY, j.ISSUENUM, tp.TEAM, it.PNAME, vs.VALUE
        ) t
        JOIN
        (SELECT
           cg.ISSUEID,
           cg.CREATED END_DATE
         FROM jira.CHANGEGROUP cg
           JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
         WHERE ci.FIELD = 'status' AND
               TO_CHAR(ci.NEWVALUE) = '11408' -- 'Hot Support'
          -- AND j.CREATED > TO_DATE('2016-01-01', 'yyyy-mm-dd')
        ) d
          ON d.ISSUEID = t.ISSUEID) n
  JOIN
  (SELECT
     f.TEAM,
     f.TYPE,
     f.TASK_SIZE,
     COUNT(f.ISSUEID)          QUANTITY,
     ROUND(AVG(f.DURATION), 2) DURATION
   FROM (SELECT
           t.TEAM,
           t.TYPE,
           t.TASK_SIZE,
           t.ISSUEID,
           (d.END_DATE -
            t.START_DATE) DURATION -- длительность задачи для скрам команд (по переходу с validation в support)
         FROM
           (SELECT
              cg.ISSUEID,
              tp.TEAM,
              it.PNAME   TYPE,
              vs.VALUE   TASK_SIZE,
              cg.CREATED START_DATE -- дата перехода в статус 'Валидация [In progress]' или 'Validation [IN PROGRESS]'
            FROM jira.JIRAISSUE j
              JOIN jira.PROJECT p ON j.PROJECT = p.ID
              JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
              JOIN jira.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
              JOIN jira.CUSTOMFIELDVALUE cfv ON j.ID = cfv.ISSUE
              JOIN V_SIZES vs ON cfv.STRINGVALUE = TO_CHAR(vs.ID)
              JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
              JOIN V_REP_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
            WHERE
              ci.FIELD = 'status' AND
              TO_CHAR(ci.NEWVALUE) = '10081' OR -- 'Валидация [In progress]'
              TO_CHAR(ci.NEWVALUE) = '10708'    -- 'Validation [IN PROGRESS]'
             --AND j.CREATED > TO_DATE('2016-01-01', 'yyyy-mm-dd')
           ) t
           JOIN
           (SELECT
              cg.ISSUEID,
              cg.CREATED END_DATE -- дата перехода в статус 'Hot Support'
            FROM jira.CHANGEGROUP cg
              JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
            WHERE ci.FIELD = 'status' AND
                  TO_CHAR(ci.NEWVALUE) = '11408' -- 'Hot Support'
             -- AND j.CREATED > TO_DATE('2016-01-01', 'yyyy-mm-dd')
           ) d
             ON d.ISSUEID = t.ISSUEID
        ) f
   WHERE f.DURATION > 0
   GROUP BY f.TEAM, f.TYPE, f.TASK_SIZE) m
    ON m.TEAM = n.TEAM AND m.TYPE = n.TYPE AND m.TASK_SIZE = n.TASK_SIZE
ORDER BY 1
