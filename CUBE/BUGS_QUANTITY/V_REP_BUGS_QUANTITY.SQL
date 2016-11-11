-- Author:            Polina Azarova
-- Date of creation:  20.05.2016
-- Description:       Data for KPI calculation
--                    (the average quantity of defects found in production)
--
--                    V_REP_BUGS_QUANTITY -> REP_BUGS_QUANTITY

--------------------------------------//12//---------------------------------------
-------------------------------------//BUG//---------------------------------------
CREATE OR REPLACE VIEW JIRA_READER.V_REP_BUGS_QUANTITY AS
  SELECT DISTINCT
    ch.PROJECT,
    ch.NUM,
    ch.SUMMARY,
    ch.TEST_PHASE,
    ch.TYPE,
    ch.PRIORITY,
    ch.CREATED,
    ch.BUG,
    ch.REGRESS
  FROM
    (SELECT
       b.PNAME       PROJECT,
       b.BUG_NUM     NUM,
       b.BUG_SUMMARY SUMMARY,
       b.TEST_PHASE  TEST_PHASE,
       'Bug'         TYPE,
       b.PRIORITY    PRIORITY,
       b.CREATED     CREATED,
       1             BUG,
       NULL          REGRESS
     FROM
       (SELECT *
        FROM
          -- first parameter - testing phase:
          -- 13745 'hot support'
          -- 11848 'Пром. эксплуатация'
          TABLE (JIRA_READER.BUGS_QUANTITY(13745, 'The Guardians of the Galaxy', 'The Avengers', 'Fantastic Four'))) bh
        UNION ALL
        SELECT *
        FROM
          -- second parameter - project
          TABLE (JIRA_READER.BUGS_QUANTITY(11848, 'X-MEN', 'X-MEN', 'X-MEN')) bp
        WHERE bp.PRIORITY = 'Critical' OR bp.PRIORITY = 'Major'
       ) b
     UNION ALL
     --------------------------------//REGRESS//-----------------------------------
     SELECT
       p.PNAME             PNAME,
       TO_CHAR(j.ISSUENUM) NUM,
       j.SUMMARY           SUMMARY,
       NULL                TEST_PHASE,
       'Regress'           TYPE,
       NULL                PRIORITY,
       TO_CHAR(j.CREATED)  CREATED,
       NULL                BUG,
       1                   REGRESS
     FROM JIRA.JIRAISSUE j
       JOIN JIRA.PROJECT p ON j.PROJECT = p.ID
       LEFT JOIN JIRA_READER.V_STATIC_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
       JOIN JIRA.LABEL Lb ON Lb.ISSUE = j.ID
     WHERE j.ISSUETYPE = 3 AND
           -- [3]      Task
           TRUNC(j.CREATED) >= TRUNC(TO_DATE('2016-08-01', 'yyyy-mm-dd')) AND LABEL = 'Регресс') ch
  ORDER BY 1, 5, 7
