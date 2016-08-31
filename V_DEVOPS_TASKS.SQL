-- Author:            Polina Azarova
-- Date of creation:  28.08.2016
-- Description:       For DevOps Metrics

CREATE OR REPLACE VIEW JIRA_READER.V_DEVOPS_TASKS AS
  WITH dates (D) AS (
    SELECT TO_DATE(CURRENT_DATE - 30, 'YYYY-MM-DD')
    FROM dual -- start
    UNION ALL
    SELECT D + 1 AS DAY_OF_MONTH
    FROM dates
    WHERE D < CURRENT_DATE -- end
  )
  SELECT
    n.*,
    IS_WORKING_DAY(dates.D) NOT_WORK_DAY
  FROM (SELECT
          t.PKEY,
          t.TYPE,
          t.SUMMARY,
          t.ISSUENUM,
          t.ISSUEID,
          t.START_DATE,
          d.END_DATE
        FROM
          (SELECT DISTINCT
             p.PKEY,
             cg.ISSUEID,
             j.CREATED,
             j.SUMMARY,
             j.ISSUENUM,
             it.PNAME   TYPE,
             cg.CREATED START_DATE -- дата перехода задачи в статус начала выполнения
           FROM jira.JIRAISSUE j
             JOIN jira.PROJECT p ON j.PROJECT = p.ID
             JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
             JOIN jira.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
             JOIN jira.CUSTOMFIELDVALUE cfv ON j.ID = cfv.ISSUE
             JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
           WHERE
             ci.FIELD = 'status'
             AND TO_CHAR(ci.NEWVALUE) = '3' -- In Progress
             AND it.PNAME = 'User Story' AND (p.PKEY = 'PFM' OR p.PKEY = 'RECSYS')
             AND cg.CREATED > CURRENT_DATE - 30
          ) t
          JOIN
          (SELECT
             cg.ISSUEID,
             cg.CREATED END_DATE
           FROM jira.CHANGEGROUP cg
             JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
           WHERE ci.FIELD = 'status' AND TO_CHAR(ci.NEWVALUE) = '10015'-- Done
          ) d
            ON d.ISSUEID = t.ISSUEID) n
    JOIN dates ON (IS_WORKING_DAY(dates.D) = '0' AND TRUNC(n.START_DATE) <= dates.D AND TRUNC(n.END_DATE) >= dates.D)
