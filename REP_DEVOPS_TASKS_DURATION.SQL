-- Author:            Polina Azarova
-- Date of creation:  28.08.2016
-- Description:       V_REP_DEVOPS_METRICS -> REP_DEVOPS_TASKS_METRICS_D -> REP_DEVOPS_TASKS_METRICS ->
--                    -> REP_DEVOPS_TASKS_DURATION -> REP_DEVOPS_TASKS

CREATE OR REPLACE TYPE DEVOPS_TASKS_DURATION_TY IS OBJECT (TYPE       VARCHAR2(255),
                                                           SUMMARY    VARCHAR2(255), ISSUEID VARCHAR2(255),
                                                           START_DATE DATE, END_DATE DATE, DURATION NUMBER);
CREATE OR REPLACE TYPE DEVOPS_TASKS_DURATION_TBL_TY IS TABLE OF DEVOPS_TASKS_DURATION_TY;

CREATE OR REPLACE FUNCTION REP_DEVOPS_TASKS_DURATION(p_day NUMBER, p_end_day NUMBER, p_type VARCHAR2, p_st VARCHAR2,
                                                     p_end VARCHAR2)
  RETURN DEVOPS_TASKS_DURATION_TBL_TY
PIPELINED
IS
  CURSOR cur (c_day NUMBER, c_end_day NUMBER, c_type VARCHAR2, c_st VARCHAR2, c_end VARCHAR2)
  IS
    SELECT
      n.*,
      t.DURATION - COALESCE(m.NOT_WORK_DAY, 0) DURATION
    FROM
      (SELECT DISTINCT
         dt.TYPE,
         dt.SUMMARY,
         dt.ISSUEID,
         dt.START_DATE,
         dt.END_DATE
       FROM
         (SELECT *
          FROM
            TABLE (REP_DEVOPS_TASKS(c_day, c_end_day, c_type, c_st, c_end))) dt
      ) n
      LEFT JOIN
      (SELECT
         COUNT(dt.NOT_WORK_DAY) NOT_WORK_DAY,
         dt.ISSUEID
       FROM (SELECT *
             FROM
               TABLE (REP_DEVOPS_TASKS(c_day, c_end_day, c_type, c_st, c_end))) dt
       WHERE dt.NOT_WORK_DAY = '0'
       GROUP BY dt.ISSUEID) m
        ON n.ISSUEID = m.ISSUEID
      JOIN (SELECT
              f.ISSUEID,
              SUM(f.DURATION) DURATION
            FROM (SELECT
                    dt.ISSUEID,
                    (dt.END_DATE -
                     dt.START_DATE) DURATION
                  -- длительность задачи
                  FROM (SELECT *
                        FROM
                          TABLE (REP_DEVOPS_TASKS(c_day, c_end_day, c_type, c_st, c_end))) dt
                 ) f
            WHERE f.DURATION > 0
            GROUP BY f.ISSUEID) t ON t.ISSUEID = n.ISSUEID OR t.ISSUEID = m.ISSUEID;
  BEGIN
    FOR rec IN cur (p_day, p_end_day, p_type, p_st, p_end)
    LOOP
      PIPE ROW (DEVOPS_TASKS_DURATION_TY(rec.TYPE, rec.SUMMARY, rec.ISSUEID, rec.START_DATE, rec.END_DATE,
                                         rec.DURATION));
    END LOOP;
    RETURN;
  END;
