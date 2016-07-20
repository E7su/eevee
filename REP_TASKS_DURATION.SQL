CREATE OR REPLACE TYPE TASKS_DURATION_TY IS OBJECT (TEAM     VARCHAR2(255), TYPE VARCHAR2(255), TASK_SIZE VARCHAR2(255), SUMMARY VARCHAR2(255), ISSUENUM VARCHAR2(255), END_DATE DATE,
                                                    DURATION NUMBER, QUANTITY NUMBER);
CREATE OR REPLACE TYPE TASKS_DURATION_TBL_TY IS TABLE OF TASKS_DURATION_TY;

CREATE OR REPLACE FUNCTION REP_TASKS_DURATION(p_st VARCHAR2, p_st_2 VARCHAR2, p_end VARCHAR2)
  RETURN TASKS_DURATION_TBL_TY
PIPELINED
IS
  CURSOR cur (c_st VARCHAR2, c_st_2 VARCHAR2, c_end VARCHAR2)
  IS
    SELECT DISTINCT
      n.*,
      m.DURATION,
      m.QUANTITY -- количество внедрённых задач
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
               TO_CHAR(ci.NEWVALUE) = c_st OR TO_CHAR(ci.NEWVALUE) = c_st_2
             --AND j.CREATED > TO_DATE('2016-01-01', 'yyyy-mm-dd')
             GROUP BY cg.ISSUEID, j.SUMMARY, j.ISSUENUM, tp.TEAM, it.PNAME, vs.VALUE
            ) t
            JOIN
            (SELECT
               cg.ISSUEID,
               cg.CREATED END_DATE
             FROM jira.CHANGEGROUP cg
               JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
             WHERE ci.FIELD = 'status' AND TO_CHAR(ci.NEWVALUE) = c_end
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
                t.START_DATE) DURATION -- длительность задачи
             FROM
               (SELECT
                  cg.ISSUEID,
                  tp.TEAM,
                  it.PNAME   TYPE,
                  vs.VALUE   TASK_SIZE,
                  cg.CREATED START_DATE -- дата перехода задачи в статус начала выполнения
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
                  TO_CHAR(ci.NEWVALUE) = c_st OR TO_CHAR(ci.NEWVALUE) = c_st_2 -- статусы начала выполнения задачи
                 --AND j.CREATED > TO_DATE('2016-01-01', 'yyyy-mm-dd')
               ) t
               JOIN
               (SELECT
                  cg.ISSUEID,
                  cg.CREATED END_DATE -- дата перехода задачи в статус окончания
                FROM jira.CHANGEGROUP cg
                  JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
                WHERE ci.FIELD = 'status' AND
                      TO_CHAR(ci.NEWVALUE) = c_end -- AND j.CREATED > TO_DATE('2016-01-01', 'yyyy-mm-dd')
               ) d
                 ON d.ISSUEID = t.ISSUEID
            ) f
       WHERE f.DURATION > 0
       GROUP BY f.TEAM, f.TYPE, f.TASK_SIZE) m
        ON m.TEAM = n.TEAM AND m.TYPE = n.TYPE AND m.TASK_SIZE = n.TASK_SIZE;
  BEGIN
    FOR rec IN cur (p_st, p_st_2, p_end)
    LOOP
      PIPE ROW (TASKS_DURATION_TY(rec.TEAM, rec.TYPE, rec.TASK_SIZE, rec.SUMMARY, rec.ISSUENUM, rec.END_DATE,
                                  rec.DURATION, rec.QUANTITY));
    END LOOP;
    RETURN;
  END;
