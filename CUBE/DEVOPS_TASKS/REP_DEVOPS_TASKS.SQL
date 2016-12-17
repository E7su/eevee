-- Author:            Polina Azarova
-- Date of creation:  28.08.2016
-- Description:       V_REP_DEVOPS_METRICS -> REP_DEVOPS_TASKS_METRICS ->
--                    -> REP_DEVOPS_TASKS_DURATION -> REP_DEVOPS_TASKS

-- самая внутренняя функция, находит даты перехода между статусами и генерирует даты между ними
-- проверяет даты на рабочий/выходной день
CREATE OR REPLACE TYPE DEVOPS_TASKS_TY IS OBJECT (PKEY       VARCHAR2(255), TYPE VARCHAR2(255),
                                                  SUMMARY    VARCHAR2(255), ISSUEID VARCHAR2(255),
                                                  START_DATE DATE, END_DATE DATE, DAY_IS_WORKING VARCHAR2(2),
                                                  WORK_DATE  DATE);
CREATE OR REPLACE TYPE DEVOPS_TASKS_TBL_TY IS TABLE OF DEVOPS_TASKS_TY;

CREATE OR REPLACE FUNCTION REP_DEVOPS_TASKS(p_day NUMBER, p_end_day NUMBER)
  RETURN DEVOPS_TASKS_TBL_TY
PIPELINED
IS
  CURSOR cur (c_day     NUMBER, -- с какого дня считать
              c_end_day NUMBER) -- по какой день
  IS
    -- генератор дат (чтобы далее не учитывать выходные и праздники при расчёте длительности выполнения задачи)
    WITH dates (D) AS (
      -- для подсчёта скользящим окном за предыдущие 30 дней
      SELECT TRUNC(CURRENT_DATE - c_day)
      FROM dual -- start
      UNION ALL
      SELECT D + 1 AS DAY_OF_MONTH
      FROM dates
      WHERE D <= CURRENT_DATE - c_end_day -- end
    )
    SELECT
      t.*,
      IS_WORKING_DAY(dates.D) DAY_IS_WORKING,
      -- проверяет, рабочий ли это день
      -- в выходные 0, ELSE 1
      dates.D                 WORK_DATE
    FROM ((SELECT
            sd.PKEY,
            sd.TYPE,
            sd.SUMMARY,
            sd.ISSUEID,
            sd.START_DATE,
            ed.END_DATE
          FROM
            (SELECT
               p.PKEY,
               cg.ISSUEID,
               j.CREATED,
               j.SUMMARY,
               it.PNAME   TYPE,
               cg.CREATED START_DATE -- дата перехода задачи в статус начала выполнения
             FROM jira.JIRAISSUE j
               JOIN jira.PROJECT p ON j.PROJECT = p.ID
               JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
               JOIN jira.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
               JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
             WHERE
               ci.FIELD = 'status'
               AND TO_CHAR(ci.NEWVALUE) = '3' -- start (status ID)
               AND it.PNAME = 'User Story' AND (p.PKEY IN ('PFM', 'RECSYS', 'TAX', 'DPT', 'KB3', 'ABM'))
               -- даты начала выполнения задачи должны помешаться в рассматриваемый период
               AND cg.CREATED >= CURRENT_DATE - c_day
               AND cg.CREATED <= CURRENT_DATE - c_end_day
            ) sd
            JOIN
            (SELECT
               cg.ISSUEID,
               cg.CREATED END_DATE
             FROM jira.CHANGEGROUP cg
               JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
             WHERE ci.FIELD = 'status' AND TO_CHAR(ci.NEWVALUE) = '10015' -- end (status ID)
                   -- даты окончания выполнения задачи должны помешаться в рассматриваемый период
                   AND cg.CREATED >= CURRENT_DATE - c_day
                   AND cg.CREATED <= CURRENT_DATE - c_end_day
            ) ed
              ON ed.ISSUEID = sd.ISSUEID)

          UNION ALL

          SELECT
            p.PKEY     PKEY,
            it.PNAME   TYPE,
            j.SUMMARY  SUMMARY,
            j.ID       ISSUEID,

            -- если время раньше 11:00, то округлять до 10:00
            -- если время позже 17:00, то округлять до 18:00
            CASE
            WHEN TO_NUMBER(TO_CHAR(a1.CREATED, 'HH24')) < 11
              THEN TRUNC(a1.CREATED, 'DD') + 10 / 24
            WHEN TO_NUMBER(TO_CHAR(a1.CREATED, 'HH24')) > 17
              THEN TRUNC(a1.CREATED, 'DD') + 18 / 24
            ELSE
              a1.CREATED
            END START_DATE,

            CASE
            WHEN TO_NUMBER(TO_CHAR(a2.CREATED, 'HH24')) < 11
              THEN TRUNC(a2.CREATED, 'DD') + 10 / 24
            WHEN TO_NUMBER(TO_CHAR(a2.CREATED, 'HH24')) > 17
              THEN TRUNC(a2.CREATED, 'DD') + 18 / 24
            ELSE
              a2.CREATED
            END END_DATE

          FROM JIRA.JIRAISSUE j
            INNER JOIN JIRA.PROJECT p ON (j.PROJECT = p.ID)
            JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
            JOIN JIRA.JIRAACTION a1 ON (a1.ID = (SELECT MAX(a.ID)
                                                 FROM JIRA.JIRAACTION a
                                                 WHERE
                                                   a.ISSUEID = j.ID AND
--                                                    a.ACTIONTYPE = 'comment' AND
--                                                    a.AUTHOR = 'ci_server' AND
                                                   a.ACTIONBODY LIKE 'Build for%' AND a.ACTIONBODY LIKE '%is started'))
            JOIN JIRA.JIRAACTION a2 ON (a2.ID = (SELECT MAX(a.ID)
                                                 FROM JIRA.JIRAACTION a
                                                 WHERE
                                                   a.ISSUEID = j.ID AND
--                                                    a.ACTIONTYPE = 'comment' AND
--                                                    a.AUTHOR = 'ci_server' AND
                                                   a.ACTIONBODY LIKE '%we are waiting for production system feedback%'))
          WHERE
            it.PNAME = 'DevOps Task' AND p.PKEY IN ('PFM', 'RECSYS', 'TAX', 'DPT', 'KB3', 'ABM')
            AND j.ISSUESTATUS = 10015 -- Done
            AND j.UPDATED >= CURRENT_DATE - c_day AND j.UPDATED <= CURRENT_DATE - c_end_day
         ) t
      -- создаём список из дат, лежащих между датами начала и конца выполнения issue
      JOIN dates ON (TRUNC(t.START_DATE) <= dates.D AND TRUNC(t.END_DATE) >= dates.D);
  BEGIN
    FOR rec IN cur (p_day, p_end_day)
    LOOP
      PIPE ROW (DEVOPS_TASKS_TY(rec.PKEY, rec.TYPE, rec.SUMMARY, rec.ISSUEID, rec.START_DATE, rec.END_DATE,
                                rec.DAY_IS_WORKING,
                                rec.WORK_DATE));
    END LOOP;
    RETURN;
  END;
