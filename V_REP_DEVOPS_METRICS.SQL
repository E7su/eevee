-- Author:            Polina Azarova
-- Date of creation:  28.08.2016
-- Description:       V_REP_DEVOPS_METRICS -> REP_DEVOPS_TASKS_METRICS_D -> REP_DEVOPS_TASKS_METRICS ->
--                    -> REP_DEVOPS_TASKS_DURATION -> REP_DEVOPS_TASKS

CREATE OR REPLACE VIEW V_REP_DEVOPS_METRICS AS
  -- Lead Time
  SELECT
    'Lead Time'        METRICS,
    t.DAT,
    t.PKEY,
    t.TYPE,
    t.SUMMARY,
    t.ISSUEID,
    t.START_DATE,
    t.END_DATE,
    t.DURATION,
    t.STAT,
    TO_NUMBER(t.VALUE) VALUE, -- в днях
    t.COUNTER
  FROM
    TABLE (REP_DEVOPS_TASKS_METRICS_D('User Story', '3', '10015')) t -- 'In Progress' -> 'Done'
  UNION ALL
  -- Pure Deployment Time
  SELECT
    'Pure Deployment Time' METRICS,
    d.DAT,
    d.PKEY,
    d.TYPE,
    d.SUMMARY,
    d.ISSUEID,
    d.START_DATE,
    d.END_DATE,
    d.DURATION,
    d.STAT,
    d.VALUE * 8            VALUE, -- в часах
    d.COUNTER
  -- считать с 9:00-18:00 пока нельзя, т.к. даты начала выполнения задач зачастую > 18:00
  FROM
    TABLE (REP_DEVOPS_TASKS_METRICS_D('DevOps Task', '11812', '11819')) d -- 'Build' -> 'Waiting Feedback(Live)'
  ORDER BY 1, 3
