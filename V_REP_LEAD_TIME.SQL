-- Author:            Polina Azarova
-- Date of creation:  28.08.2016
-- Description:       DevOps Metric (Lead Time)


CREATE OR REPLACE VIEW V_REP_LEAD_TIME AS
  SELECT
    n.*,
    t.DURATION - m.NOT_WORK_DAY DURATION -- чистая длительность (без учёта праздников и выходных)
  FROM
    (SELECT DISTINCT
       rt.TYPE,
       rt.SUMMARY,
       rt.ISSUEID,
       rt.START_DATE,
       rt.END_DATE
     FROM JIRA_READER.V_DEVOPS_TASKS rt
     WHERE rt.START_DATE < CURRENT_DATE AND rt.START_DATE > CURRENT_DATE - 30
    ) n
    LEFT JOIN
    (SELECT
       COUNT(dt.NOT_WORK_DAY) NOT_WORK_DAY,
       dt.ISSUEID
     FROM JIRA_READER.V_DEVOPS_TASKS dt
     WHERE dt.NOT_WORK_DAY = '0'
     GROUP BY dt.ISSUEID) m
      ON n.ISSUEID = m.ISSUEID
    LEFT JOIN (SELECT
                 f.ISSUEID,
                 SUM(f.DURATION) DURATION
               FROM (SELECT
                       dt.ISSUEID,
                       (dt.END_DATE -
                        dt.START_DATE) DURATION
                     -- длительность задачи
                     FROM JIRA_READER.V_DEVOPS_TASKS dt
                    ) f
               WHERE f.DURATION > 0
               GROUP BY f.ISSUEID) t ON t.ISSUEID = n.ISSUEID OR t.ISSUEID = m.ISSUEID
  ORDER BY n.START_DATE
