-- Author:            Polina Azarova
-- Date of creation:  01.04.2016
-- Description:       Productivity of a certain Team completed some Issues in a date

CREATE OR REPLACE VIEW JIRA_READER.V_REP_TEAMS_PRODUCTIVITY AS
  SELECT
    tc.DAY                     DAY,
    tc.IS_WORKING_DAY          IS_WORKING_DAY,
    tis.PROJECT                PROJECT,
    tis.EPIC                   EPIC,
    tc.TEAM                    TEAM,
    tis.ISSUES_COUNT           ISSUES_COUNT,
    tis.ISSUES_SCORE           ISSUES_SCORE,
    SUM(tc.WORKED_DAY_PERCENT) WORKED_DAY
  FROM
    (SELECT
       ts.DAY,
       ts.PROJECT,
       ts.EPIC,
       tp.TEAM,
       ts.ISSUES_COUNT,
       ts.ISSUES_SCORE
     FROM
       (SELECT
          ti.ID,
          ti.DAY,
          ti.PROJECT,
          ti.EPIC,
          SUM(ti.COUNT) AS ISSUES_COUNT,
          -- сколько задач закрыто в эту дату по этому же проекту
          SUM(ti.SCORE) AS ISSUES_SCORE -- сколько задач закрыто в эту дату по этому же проекту * вес задачи
        FROM
          JIRA_READER.V_REP_TEAMS_ISSUES ti
        GROUP BY
          ti.ID,
          ti.DAY,
          ti.PROJECT,
          ti.EPIC
       ) ts
       -- соответствие между командами и проектами/epic-ами
       -- for sprint
       LEFT JOIN jira.CUSTOMFIELDVALUE cfv2
         ON (cfv2.CUSTOMFIELD = 10375 AND ts.ID = cfv2.ISSUE)
       LEFT JOIN JIRA.AO_60DB71_SPRINT sp ON (sp.ID = cfv2.STRINGVALUE)
       JOIN JIRA_READER.V_STATIC_TEAMS_PROJECTS tp
         ON (tp.PROJECT = ts.PROJECT AND
             (tp.EPIC IS NULL OR tp.EPIC = ts.EPIC) AND
             (tp.SPRINT IS NULL OR sp.NAME LIKE tp.SPRINT))
    ) tis
    RIGHT JOIN JIRA_READER.V_REP_TEAMS_COUNT tc ON (tc.DAY = tis.DAY AND tc.TEAM = tis.TEAM)
  -- сколько сотрудников закрывало задачи
  GROUP BY
    tc.DAY,
    tc.IS_WORKING_DAY,
    tis.PROJECT,
    tis.EPIC,
    tc.TEAM,
    tis.ISSUES_COUNT,
    tis.ISSUES_SCORE;
