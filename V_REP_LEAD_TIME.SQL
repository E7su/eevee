-- Author:            Polina Azarova
-- Date of creation:  28.08.2016
-- Description:       DevOps Metric (Lead Time)


CREATE OR REPLACE VIEW V_REP_LEAD_TIME AS
  SELECT
    n.*,
    t.DURATION - m.NOT_WORK_DAY DURATION
  FROM
    (SELECT DISTINCT
       rt.TYPE,
       rt.SUMMARY,
       rt.ISSUENUM,
       rt.START_DATE,
       rt.END_DATE
     FROM JIRA_READER.V_DEVOPS_TASKS rt
     WHERE rt.START_DATE < CURRENT_DATE AND rt.START_DATE > CURRENT_DATE - 30
    ) n
    LEFT JOIN
    (SELECT
       COUNT(dt.NOT_WORK_DAY) NOT_WORK_DAY,
       dt.ISSUENUM
     FROM JIRA_READER.V_DEVOPS_TASKS dt
     GROUP BY dt.ISSUENUM) m
      ON n.ISSUENUM = m.ISSUENUM
    JOIN (SELECT
            f.ISSUENUM,
            SUM(f.DURATION) DURATION
          FROM (SELECT
                  dt.ISSUENUM,
                  (dt.END_DATE -
                   dt.START_DATE) DURATION
                -- длительность задачи
                FROM JIRA_READER.V_DEVOPS_TASKS dt
               ) f
          WHERE f.DURATION > 0
          GROUP BY f.ISSUENUM) t ON t.ISSUENUM = m.ISSUENUM
  ORDER BY n.START_DATE
