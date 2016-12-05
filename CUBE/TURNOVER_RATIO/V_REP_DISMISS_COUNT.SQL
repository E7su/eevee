-- Author:            Polina Azarova
-- Date of creation:  08.07.2016
-- Description:       A report on the turnover ratio for the selected period in the context of administration,
--                    registration ( state / vendor )

--                    V_REP_TURNOVER_RATIO -> V_REP_DISMISS_COUNT -> REP_DISMISS_COUNT
--                                         -> V_REP_AVG_TURNOVER_RATIO -> REP_AVG_TURNOVER_RATIO

--------------------------------------//14//---------------------------------------
CREATE OR REPLACE VIEW JIRA_READER.V_REP_DISMISS_COUNT
AS
  SELECT *
  FROM TABLE (REP_DISMISS_COUNT('2016', '12'))
  UNION ALL
  SELECT *
  FROM TABLE (REP_DISMISS_COUNT('2016', '11'))
  UNION ALL
  SELECT *
  FROM TABLE (REP_DISMISS_COUNT('2016', '10'))
  UNION ALL
  SELECT *
  FROM TABLE (REP_DISMISS_COUNT('2016', '09'))
  UNION ALL
  SELECT *
  FROM TABLE (REP_DISMISS_COUNT('2016', '08'))
  UNION ALL
  SELECT *
  FROM TABLE (REP_DISMISS_COUNT('2016', '07'))
  UNION ALL
  SELECT *
  FROM TABLE (REP_DISMISS_COUNT('2016', '06'))
  UNION ALL
  SELECT *
  FROM TABLE (REP_DISMISS_COUNT('2016', '05'))
  UNION ALL
  SELECT *
  FROM TABLE (REP_DISMISS_COUNT('2016', '04'))
  UNION ALL
  SELECT *
  FROM TABLE (REP_DISMISS_COUNT('2016', '03'))
  UNION ALL
  SELECT *
  FROM TABLE (REP_DISMISS_COUNT('2016', '02'))
  UNION ALL
  SELECT *
  FROM TABLE (REP_DISMISS_COUNT('2016', '01'))
