CREATE OR REPLACE FORCE VIEW "JIRA_READER"."V_REP_EMPLOYEES_COUNT_CITEB" ("D", "X-MEN, чел")
AS
  WITH dates (d) AS (
    SELECT to_date('2010-01-01', 'yyyy-mm-dd') AS d FROM dual --start
    UNION ALL
    SELECT add_months(d, 1) AS d FROM dates WHERE d < CURRENT_DATE /*--end*/
  )
  SELECT
    d,
    COUNT(s."ФИО") "X-MEN, чел"
  FROM dates -- to_char(d, 'dd-mm-yyyy')
    LEFT JOIN (
      SELECT * FROM jira_reader.v_employees_short
    ) s
    ON (dates.d            >= s."Дата приёма"
    AND dates.d            <= NVL(s."Дата увольнения", to_date('3000.01.01', 'yyyy-mm-dd')))
  WHERE s."Подразделение" = 'X-MEN'
  GROUP BY dates.d
  ORDER BY 1;
