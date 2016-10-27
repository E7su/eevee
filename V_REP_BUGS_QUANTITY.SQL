-- Author:            Polina Azarova
-- Date of creation:  20.05.2016
-- Description:       Report (Graph):
--                    KPI
--                    the average quantity of defects found in production
-- 
--                    V_REP_BUGS_QUANTITY-> REP_BUGS_QUANTITY

--------------------------------------//12//---------------------------------------
----------------------------------//числитель//------------------------------------
CREATE OR REPLACE VIEW JIRA_READER.V_REP_BUGS_QUANTITY AS
  SELECT DISTINCT
    -- on eazyBI ROUND(ch.QUANTITY / zn.REGRESS, 2) KPI
    ch.PNAME PROJECT,
    ch.BUG_NUM,
    ch.BUG_SUMMARY,
    ch.TEST_PHASE,
    ch.QUANTITY,
    zn.REGRESS_NUM,
    zn.REGRESS_SUMMARY,
    zn.REGRESS
  FROM
    (SELECT
       b.PNAME,
       b.BUG_NUM,
       b.BUG_SUMMARY,
       b.TEST_PHASE,
       ROWNUM BUG_ROW,
       -- количество багов, найденных в фазу тестирования Пром. эксплуатация
       1      QUANTITY
     FROM
       (SELECT *
        FROM
          -- first parameter - testing phase
          TABLE (JIRA_READER.BUGS_QUANTITY(13745, 'X-MEN', 'X-MEN', 'X-MEN')) bh
        UNION ALL
        SELECT *
        FROM
          -- second parameter - project
          TABLE (JIRA_READER.BUGS_QUANTITY(11848, 'The Guardians of the Galaxy', 'The Avengers', 'Fantastic Four')) bp
        WHERE bp.priority = '2' -- critical
       ) b
    ) ch
    LEFT JOIN
    -------------------------------//знаменатель//-----------------------------------
    (SELECT
       p.PNAME    PNAME,
       j.ISSUENUM REGRESS_NUM,
       j.SUMMARY  REGRESS_SUMMARY,
       ROWNUM     REGRESS_ROW,
       1          REGRESS
     FROM JIRA.JIRAISSUE j
       JOIN JIRA.PROJECT p ON j.PROJECT = p.ID
       LEFT JOIN JIRA_READER.V_STATIC_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
       JOIN JIRA.LABEL Lb ON Lb.ISSUE = j.id
     WHERE j.ISSUETYPE = 3 AND
           -- [3]      Task
           TRUNC(j.CREATED) >= TRUNC(TO_DATE('2016-08-01', 'yyyy-mm-dd')) AND LABEL = 'Регресс') zn
      ON ch.PNAME = zn.PNAME AND BUG_ROW = REGRESS_ROW
