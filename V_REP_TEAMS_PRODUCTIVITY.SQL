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
    (
      SELECT
        ts.DAY,
        ts.PROJECT,
        ts.EPIC,
        tp.TEAM,
        ts.ISSUES_COUNT,
        ts.ISSUES_SCORE
      FROM
        (
          SELECT
            ti.DAY,
            ti.PROJECT,
            ti.EPIC,
            SUM(ti.COUNT) AS ISSUES_COUNT,
            -- сколько задач закрыто в эту дату по этому же проекту
            SUM(ti.SCORE) AS ISSUES_SCORE -- сколько задач закрыто в эту дату по этому же проекту * вес задачи
          FROM
            V_REP_TEAMS_ISSUES ti
          GROUP BY
            ti.DAY,
            ti.PROJECT,
            ti.EPIC
        ) ts
        JOIN V_REP_TEAMS_PROJECTS tp ON -- соответствие между командами и проектами/epic-ами
                                       (
                                         tp.PROJECT = ts.PROJECT
                                         AND (tp.EPIC IS NULL OR tp.EPIC = ts.EPIC)
                                         )
    ) tis
    RIGHT JOIN V_REP_TEAMS_COUNT tc ON (tc.DAY = tis.DAY AND tc.TEAM = tis.TEAM)
  -- сколько сотрудников закрывало задачи
  GROUP BY
    tc.DAY,
    tc.IS_WORKING_DAY,
    tis.PROJECT,
    tis.EPIC,
    tc.TEAM,
    tis.ISSUES_COUNT,
    tis.ISSUES_SCORE;

