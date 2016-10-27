-- Author:            Polina Azarova
-- Date of creation:  27.07.2016
-- Description:       Function for refactoring V_REP_TASKS_DURATION

CREATE OR REPLACE TYPE TASKS_TY IS OBJECT (TEAM       VARCHAR2(255), TYPE VARCHAR2(255), TASK_SIZE VARCHAR2(255),
                                           SUMMARY    VARCHAR2(4000), ISSUENUM VARCHAR2(255),
                                           START_DATE DATE, END_DATE DATE);
CREATE OR REPLACE TYPE TASKS_TBL_TY IS TABLE OF TASKS_TY;

CREATE OR REPLACE FUNCTION REP_TASKS(p_st NUMBER, p_st_2 NUMBER, p_end VARCHAR2)
  RETURN TASKS_TBL_TY
PIPELINED
IS
  CURSOR cur (c_st VARCHAR2, c_st_2 VARCHAR2, c_end VARCHAR2)
  IS
    SELECT
      t.TEAM,
      t.TYPE,
      t.TASK_SIZE,
      t.SUMMARY,
      t.ISSUENUM,
      t.ISSUEID,
      t.START_DATE,
      t.END_DATE END_DATE
    FROM
      (SELECT
         cg.ISSUEID,
         j.SUMMARY,
         j.ISSUENUM,
         tp.TEAM,
         it.PNAME    TYPE,
         vs.VALUE    TASK_SIZE,
         -- дата перехода задачи в статус начала выполнения
         cg.CREATED  START_DATE,
         -- дата перехода задачи в статус завершения выполнения
         cg2.CREATED END_DATE
       FROM jira.JIRAISSUE j
         JOIN jira.PROJECT p ON j.PROJECT = p.ID
         JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
         JOIN jira.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
         JOIN jira.CUSTOMFIELDVALUE cfv ON j.ID = cfv.ISSUE
         JOIN V_SIZES vs ON cfv.STRINGVALUE = TO_CHAR(vs.ID)
         JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
         JOIN jira.CHANGEGROUP cg2 ON (cg2.ISSUEID = j.ID)
         JOIN jira.CHANGEITEM ci2 ON (ci2.GROUPID = cg2.ID)
         -- ищем эпик
         LEFT JOIN jira.ISSUELINK ln1 ON (j.ID = ln1.DESTINATION AND ln1.LINKTYPE = 10070)
         --epic
         LEFT JOIN jira.JIRAISSUE j2 ON (j2.ID = ln1.SOURCE AND j2.ISSUETYPE = 34)
         --получаем название эпика из кастомполя
         LEFT JOIN jira.CUSTOMFIELDVALUE c1 ON (c1.ISSUE = j2.ID AND c1.CUSTOMFIELD = 10377)
         JOIN JIRA_READER.V_STATIC_TEAMS_PROJECTS tp
           ON (tp.PROJECT = p.PNAME AND
               (tp.EPIC IS NULL OR tp.EPIC = j2.SUMMARY OR tp.EPIC = TO_CHAR(c1.STRINGVALUE)))
       WHERE
         ci2.FIELD = 'status' AND ci.FIELD = 'status' AND
         cg.CREATED >= TO_DATE('2016-01-01', 'yyyy-mm-dd') AND
         TO_CHAR(ci2.NEWVALUE) = c_end AND --'10015'
         TO_CHAR(ci.NEWVALUE) = c_st OR TO_CHAR(ci.NEWVALUE) = c_st_2 --'10106', '10014'
      ) t;
  BEGIN
    FOR rec IN cur (p_st, p_st_2, p_end)
    LOOP
      PIPE ROW (TASKS_TY(rec.TEAM, rec.TYPE, rec.TASK_SIZE, rec.SUMMARY, rec.ISSUENUM, rec.START_DATE, rec.END_DATE));
    END LOOP;
    RETURN;
  END;
