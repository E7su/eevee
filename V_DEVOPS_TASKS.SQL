-- Author:            Polina Azarova
-- Date of creation:  28.08.2016
-- Description:       V_REP_DEVOPS_METRICS -> REP_DEVOPS_TASKS_METRICS_D -> REP_DEVOPS_TASKS_METRICS ->
--                    -> REP_DEVOPS_TASKS_DURATION -> REP_DEVOPS_TASKS

CREATE OR REPLACE TYPE DEVOPS_TASKS_TY IS OBJECT (TYPE       VARCHAR2(255),
                                                  SUMMARY    VARCHAR2(255), ISSUEID VARCHAR2(255),
                                                  START_DATE DATE, END_DATE DATE, NOT_WORK_DAY VARCHAR2(2));
CREATE OR REPLACE TYPE DEVOPS_TASKS_TBL_TY IS TABLE OF DEVOPS_TASKS_TY;

CREATE OR REPLACE FUNCTION REP_DEVOPS_TASKS(p_day NUMBER, p_end_day NUMBER, p_type VARCHAR2, p_st VARCHAR2,
                                            p_end VARCHAR2)
  RETURN DEVOPS_TASKS_TBL_TY
PIPELINED
IS
  CURSOR cur (c_day NUMBER, c_end_day NUMBER, c_type VARCHAR2, c_st VARCHAR2, c_end VARCHAR2)
  IS
    WITH dates (D) AS (
      SELECT TRUNC(CURRENT_DATE - c_day)
      FROM dual -- start
      UNION ALL
      SELECT D + 1 AS DAY_OF_MONTH
      FROM dates
      WHERE D <= CURRENT_DATE - c_end_day -- end
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
               AND TO_CHAR(ci.NEWVALUE) = c_st -- start (status ID)
               AND it.PNAME = c_type AND (p.PKEY = 'PFM' OR p.PKEY = 'RECSYS')
               AND cg.CREATED >= CURRENT_DATE - c_day
               AND cg.CREATED <= CURRENT_DATE - c_end_day
            ) t
            JOIN
            (SELECT
               cg.ISSUEID,
               cg.CREATED END_DATE
             FROM jira.CHANGEGROUP cg
               JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
             WHERE ci.FIELD = 'status' AND TO_CHAR(ci.NEWVALUE) = c_end -- end (status ID)
                   AND cg.CREATED <= CURRENT_DATE - c_end_day
                   AND cg.CREATED >= CURRENT_DATE - c_day
            ) d
              ON d.ISSUEID = t.ISSUEID) n
      JOIN dates ON (TRUNC(n.START_DATE) <= dates.D AND TRUNC(n.END_DATE) >= dates.D);
  BEGIN
    FOR rec IN cur (p_day, p_end_day, p_type, p_st, p_end)
    LOOP
      PIPE ROW (DEVOPS_TASKS_TY(rec.TYPE, rec.SUMMARY, rec.ISSUEID, rec.START_DATE, rec.END_DATE, rec.NOT_WORK_DAY));
    END LOOP;
    RETURN;
  END;
