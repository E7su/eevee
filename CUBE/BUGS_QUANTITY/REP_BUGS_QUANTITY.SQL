-- Author:            Polina Azarova
-- Date of creation:  27.10.2016
-- Description:       V_REP_BUGS_QUANTITY-> REP_BUGS_QUANTITY

CREATE OR REPLACE TYPE BUGS_QUANTITY_TY IS OBJECT (PNAME       VARCHAR2(255), BUG_NUM VARCHAR2(255),
                                                   BUG_SUMMARY VARCHAR2(255), TEST_PHASE VARCHAR2(255),
                                                   PRIORITY    VARCHAR2(255), CREATED VARCHAR2(255));
CREATE OR REPLACE TYPE BUGS_QUANTITY_TBL_TY IS TABLE OF BUGS_QUANTITY_TY;

CREATE OR REPLACE FUNCTION BUGS_QUANTITY(phase NUMBER, proj_1 VARCHAR2, proj_2 VARCHAR2, proj_3 VARCHAR2)
  RETURN BUGS_QUANTITY_TBL_TY
PIPELINED
IS
  CURSOR cur (phase VARCHAR2, proj_1 VARCHAR2, proj_2 VARCHAR2, proj_3 VARCHAR2)
  IS
    SELECT
      p.PNAME         PNAME,
      j.ISSUENUM      BUG_NUM,
      j.SUMMARY       BUG_SUMMARY,
      cfo.CUSTOMVALUE TEST_PHASE,
      pr.PNAME        PRIORITY,
      j.CREATED CREATED
    FROM JIRA.JIRAISSUE j
      JOIN JIRA.PROJECT p ON j.PROJECT = p.ID
      LEFT JOIN JIRA_READER.V_STATIC_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME OR tp.TEAM = p.PNAME)
      JOIN JIRA.CUSTOMFIELDVALUE cfv ON cfv.ISSUE = j.ID
      JOIN JIRA.CUSTOMFIELD cf ON cf.ID = cfv.CUSTOMFIELD
      JOIN JIRA.CUSTOMFIELDOPTION cfo ON cfv.STRINGVALUE = TO_CHAR(cfo.ID)
      LEFT JOIN JIRA.PRIORITY pr ON j.PRIORITY = pr.ID
    WHERE j.ISSUETYPE IN (1, 41) AND
          -- [1]      Bug
          -- [41]     Дефект мобильного приложения
          cfv.CUSTOMFIELD = '11573' AND cfo.ID = phase
          -- 13745 'hot support'
          -- 11848 'Пром. эксплуатация'
          AND TRUNC(j.CREATED) >= TRUNC(TO_DATE('2016-08-01', 'yyyy-mm-dd')) AND
          p.PNAME IN (proj_1, proj_2, proj_3);
  BEGIN
    FOR rec IN cur (phase, proj_1, proj_2, proj_3)
    LOOP
      PIPE ROW (BUGS_QUANTITY_TY(rec.PNAME, rec.BUG_NUM,
                                 rec.BUG_SUMMARY, rec.TEST_PHASE,
                                 rec.PRIORITY, rec.CREATED));
    END LOOP;
    RETURN;
  END;
