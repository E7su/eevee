-- Author:            Polina Azarova
-- Date of creation:  27.05.2016
-- Description:       Issues of a certain Project and Epic completed in a date

CREATE OR REPLACE VIEW JIRA_READER.V_REP_TEAMS_ISSUES AS
  SELECT *
  FROM (
    WITH dates (D) AS (
      SELECT to_date('2016-03-01', 'yyyy-mm-dd')
      FROM dual --start
      UNION ALL
      SELECT D + 1 AS d
      FROM dates
      WHERE D < CURRENT_DATE --end
    )
    SELECT
      D              AS DAY,
      i.PROJECT      AS PROJECT,
      c1.STRINGVALUE AS EPIC,
      1              AS COUNT,
      s.SCORE        AS SCORE,
      i.SUMMARY      AS SUMMARY,
      s.VALUE        AS ISSUESIZE,
      t.PNAME        AS ISSUETYPE
    FROM JIRA_READER.V_ISSUES i
      LEFT JOIN JIRA_READER.V_SIZES s ON (s.ID = i."Issue Size ID")
      JOIN JIRA.changegroup cg ON (cg.ISSUEID = i.ID)
      JOIN JIRA.changeitem ci ON (ci.groupid = cg.id)
      JOIN JIRA.ISSUETYPE t ON (t.ID = i."Issue Type ID")
      JOIN dates ON (dates.D = TRUNC(cg.created))

      LEFT JOIN JIRA.ISSUELINK ln1 ON (i.ID = ln1.DESTINATION AND ln1.LINKTYPE = 10070)
      --ищем эпик
      LEFT JOIN JIRA.JIRAISSUE j2 ON (j2.ID = ln1.SOURCE AND j2.ISSUETYPE = 34)
      --epic
      LEFT JOIN JIRA.CUSTOMFIELDVALUE c1 ON (c1.ISSUE = j2.ID AND c1.CUSTOMFIELD = 10377)

    WHERE
      ci.field = 'status'
      AND to_char(ci.newstring) = 'Done'
      -- не смотреть проекты, не участвующие в подсчёте статистики
      AND i.PROJECT IN (SELECT DISTINCT tp.PROJECT
                        FROM JIRA_READER.V_STATIC_TEAMS_PROJECTS tp)
  )
