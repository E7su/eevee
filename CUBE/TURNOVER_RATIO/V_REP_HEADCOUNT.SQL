CREATE OR REPLACE VIEW V_REP_HEADCOUNT AS
  WITH dates (D) AS (
    SELECT TO_DATE('2015-12-01', 'YYYY-MM-DD') AS D
    FROM dual -- //start
    UNION ALL
    SELECT ADD_MONTHS(D, 1) AS D
    FROM dates
    WHERE D < CURRENT_DATE -- end//
  )
  SELECT
    emp."Подразделение" DEPARTMENT,
    D                   DAT,
    COUNT(emp."ФИО")    HEADCOUNT
  FROM dates
    LEFT JOIN (SELECT *
               FROM JIRA_READER.V_EMPLOYEES_SHORT) emp
      ON (dates.D >= emp."Дата приёма"
          AND dates.D <= NVL(emp."Дата увольнения", TO_DATE('2016-12-01', 'yyyy-mm-dd')))
  GROUP BY dates.D, emp."Подразделение"
  ORDER BY 1
