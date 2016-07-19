-- Author:            Polina Azarova
-- Date of creation:  13.07.2016
-- Description:       View for eazyBI cube for reports (Graph):
--                     9. the average duration of the task
--                        in the context of the type (User story / Bug / Task)
--                        and the team for the period
--                    10. the average duration of the task in the context
--                        of the size of the issue and the team for the period
--                    11. the number of implemented tasks
--                        for the selected period in the sections:
--                        - commands and all;
--                        - size and problems in all sizes.

--------------------------//09//--//10//--//11//------------------------------------
CREATE OR REPLACE VIEW V_REP_TASKS_DURATION AS
  SELECT
    j.SUMMARY,
    j.ISSUENUM,
    tp.TEAM,
    it.PNAME                              TYPE,
    vs.VALUE                              TASK_SIZE,
    COUNT(j.ID)                           QUANTITY,
    TRUNC(AVG(cg.CREATED - j.CREATED), 2) DURATION,
    cg.CREATED                            DONE_DATE
  FROM jira.JIRAISSUE j
    JOIN jira.PROJECT p ON j.PROJECT = p.ID
    JOIN jira.ISSUETYPE it ON j.ISSUETYPE = it.ID
    JOIN jira.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
    JOIN jira.CUSTOMFIELDVALUE cfv ON j.ID = cfv.ISSUE
    JOIN V_SIZES vs ON cfv.STRINGVALUE = TO_CHAR(vs.ID)
    JOIN jira.CHANGEITEM ci ON (ci.GROUPID = cg.ID)
    JOIN V_REP_TEAMS_PROJECTS tp ON (tp.PROJECT = p.PNAME)
  WHERE ci.FIELD = 'status' AND TO_CHAR(ci.NEWVALUE) = '10015' AND j.CREATED > TO_DATE('2016-01-01', 'yyyy-mm-dd') -- Done
  GROUP BY j.SUMMARY, j.ISSUENUM, tp.TEAM, it.PNAME, vs.VALUE, cg.CREATED
  ORDER BY 1, 2, 3;
