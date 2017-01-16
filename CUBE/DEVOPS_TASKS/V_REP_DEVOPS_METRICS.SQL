-- Author:            Polina Azarova
-- Date of creation:  28.08.2016
-- Description:       V_REP_DEVOPS_METRICS -> REP_DEVOPS_TASKS_METRICS ->
--                    -> REP_DEVOPS_TASKS_DURATION -> REP_DEVOPS_TASKS

CREATE OR REPLACE VIEW V_REP_DEVOPS_METRICS AS
  SELECT
    CASE
    WHEN t.TYPE = 'User Story'
      THEN
        'Lead Time'
    WHEN t.TYPE = 'DevOps Task'
      THEN
        'Pure Deployment Time'
    ELSE
      ''
    END METRICS,

    '' DAT,

    t.PKEY,
    t.TYPE,
    t.SUMMARY,
    t.ISSUEID,
    t.START_DATE,
    t.END_DATE,
    t.DURATION,
    t.STAT,

    CASE
    WHEN t.TYPE = 'User Story'
      THEN
        TO_NUMBER(t.VALUE) -- в днях
    WHEN t.TYPE = 'DevOps Task'
      THEN
        TO_NUMBER(t.VALUE) * 24 -- в минутах
    ELSE
      0
    END VALUE,

    t.COUNTER
  FROM
    (
      SELECT * FROM TABLE (REP_DEVOPS_TASKS_METRICS('30', '0', NULL))
      UNION ALL
      SELECT * FROM TABLE (REP_DEVOPS_TASKS_METRICS('30', '0', '_OVERALL'))
    ) t;
