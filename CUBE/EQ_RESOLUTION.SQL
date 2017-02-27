CREATE OR REPLACE VIEW JIRA_READER.V_EQ_RESOLUTION AS
  SELECT
    FIO,
    ASSIGNEE,
    SUMMARY,
    ISSUENUM,
    DUEDATE,
    RESOLUTIONDATE,
    CASE
    WHEN DIFF < 0
      THEN 1
    ELSE NULL
    END BAD_COUNTER,
    ALL_COUNTER,
    COMPONENT
  FROM (
    SELECT
      emp.ФИО                             AS FIO,
      j.ASSIGNEE,
      j.SUMMARY,
      j.ISSUENUM,
      j.DUEDATE,
      j.RESOLUTIONDATE,
      j.DUEDATE - TRUNC(j.RESOLUTIONDATE) AS DIFF,
      1                                      ALL_COUNTER,
      j.PROJECT,
      na.SINK_NODE_ID                        COMPONENT_ID,
      comp.CNAME                             COMPONENT
    FROM JIRA.JIRAISSUE j
      JOIN V_EMPLOYEES_FULL emp ON LOWER(emp."Логин") = j.ASSIGNEE
      JOIN JIRA.NODEASSOCIATION na
        ON na.SOURCE_NODE_ID = j.ID
           AND na.SINK_NODE_ENTITY = 'Component'
           AND na.SOURCE_NODE_ENTITY = 'Issue'
      JOIN (SELECT
              CNAME,
              ID
            FROM JIRA.COMPONENT) comp ON comp.ID = na.SINK_NODE_ID
    WHERE
      j.ASSIGNEE IN ('Magneto', 'Wolverine', 'Mystique', 'Professor X', 'Bishop', 'Storm') AND comp.CNAME = 'EQ'
      AND j.RESOLUTIONDATE IS NOT NULL AND j.DUEDATE IS NOT NULL AND
      j.RESOLUTIONDATE >= TO_DATE('2016-09-01', 'YYYY-MM-DD'))
