CREATE OR REPLACE FORCE VIEW "JIRA_READER"."V_REP_EMPLOYEES_COUNT_ALL"
AS
  SELECT *
FROM
  (SELECT *
  FROM
    (SELECT
      CASE
        WHEN e."Оформление" = 'Штат'
        THEN 'Штат'
        WHEN e."Оформление" = 'X-MEN'
        THEN 'X-MEN'
        ELSE 'The Avengers'
      END "Офор",
      e."Подразделение",
      e."ФИО"
    FROM jira_reader.V_EMPLOYEES_SHORT e
    WHERE e."Статус"                   = 'Open'
    ) pivot ( COUNT("ФИО") FOR "Офор" IN ('Штат', 'X-MEN', 'The Avengers') )
  ) s1
LEFT JOIN
  (SELECT e."Подразделение",
    COUNT(e."ФИО") "Всего, чел"
  FROM jira_reader.V_EMPLOYEES_SHORT e
  WHERE e."Статус" = 'Open'
  GROUP BY e."Подразделение"
  ) s2 USING ("Подразделение")
ORDER BY 1;
