-- Author:            Polina Azarova
-- Date of creation:  27.07.2016
-- Description:       Function for refactoring V_REP_TASKS_DURATION

CREATE OR REPLACE TYPE TASKS_TY IS OBJECT (TEAM       VARCHAR2(255), TYPE VARCHAR2(255), TASK_SIZE VARCHAR2(255),
                                           SUMMARY    VARCHAR2(255), ISSUENUM VARCHAR2(255),
                                           START_DATE DATE, END_DATE DATE);
CREATE OR REPLACE TYPE TASKS_TBL_TY IS TABLE OF TASKS_TY;

CREATE OR REPLACE FUNCTION REP_TASKS(p_st VARCHAR2, p_st_2 VARCHAR2, p_end VARCHAR2)
  RETURN TASKS_TBL_TY
PIPELINED
IS
  CURSOR cur (c_st VARCHAR2, c_st_2 VARCHAR2, c_end VARCHAR2)
  IS
    SELECT DISTINCT
      t.TEAM,
      t.TYPE,
      t.TASK_SIZE,
      t.SUMMARY,
      t.ISSUENUM,
      t.ISSUEID,
      t.START_DATE,
      d.END_DATE
    FROM
      (SELECT
         cg.ISSUEID,
         j.SUMMARY,
         j.ISSUENUM,
         tp.TEAM,
         it.PNAME   TYPE,
         vs.VALUE   TASK_SIZE,
         cg.CREATED START_DATE -- дата перехода задачи в статус начала выполнения
       FROM jira.JIRAISSUE j
         JOIN jira.PROJECT p ON j.PROJECT = p.ID
         JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
         JOIN jira.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
         JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)

         -- for sizes
         JOIN jira.CUSTOMFIELDVALUE cfv ON (j.ID = cfv.ISSUE AND cfv.CUSTOMFIELD = 12484)
         JOIN V_SIZES vs ON cfv.STRINGVALUE = TO_CHAR(vs.ID)

         -- for epic
         LEFT JOIN jira.ISSUELINK ln1 ON (j.ID = ln1.DESTINATION AND ln1.LINKTYPE = 10070)
         LEFT JOIN jira.JIRAISSUE j2 ON (j2.ID = ln1.SOURCE AND j2.ISSUETYPE = 34)
         LEFT JOIN jira.CUSTOMFIELDVALUE cfv3 ON (cfv3.ISSUE = j2.ID AND cfv3.CUSTOMFIELD = 10377)

         -- for sprint
         LEFT JOIN jira.CUSTOMFIELDVALUE cfv2
           ON (cfv2.CUSTOMFIELD = 10375 AND j.ID = cfv2.ISSUE)
         LEFT JOIN JIRA.AO_60DB71_SPRINT sp ON (sp.ID = cfv2.STRINGVALUE)
         JOIN JIRA_READER.V_STATIC_TEAMS_PROJECTS tp
           ON (tp.PROJECT = p.PNAME AND
               (tp.EPIC IS NULL OR tp.EPIC = j2.SUMMARY OR tp.EPIC = TO_CHAR(cfv3.STRINGVALUE)) AND
               (tp.SPRINT IS NULL OR sp.NAME LIKE tp.SPRINT))
       WHERE
         ci.FIELD = 'status' AND
         (TO_CHAR(ci.NEWVALUE) = c_st OR TO_CHAR(ci.NEWVALUE) = c_st_2) -- '10106', '10014'
         AND cg.CREATED > TO_DATE('2016-01-01', 'yyyy-mm-dd')
      ) t
      JOIN
      (SELECT
         cg.ISSUEID,
         cg.CREATED END_DATE
       FROM jira.CHANGEGROUP cg
         JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
       WHERE ci.FIELD = 'status' AND TO_CHAR(ci.NEWVALUE) = c_end
             AND cg.CREATED > TO_DATE('2016-01-01', 'yyyy-mm-dd')
      ) d
        ON d.ISSUEID = t.ISSUEID;
  BEGIN
    FOR rec IN cur (p_st, p_st_2, p_end)
    LOOP
      PIPE ROW (TASKS_TY(rec.TEAM, rec.TYPE, rec.TASK_SIZE, rec.SUMMARY, rec.ISSUENUM, rec.START_DATE, rec.END_DATE));
    END LOOP;
    RETURN;
  END;
