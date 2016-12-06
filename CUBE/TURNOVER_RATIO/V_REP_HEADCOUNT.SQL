CREATE OR REPLACE VIEW V_REP_HEADCOUNT AS
  WITH dates (D) AS (
    SELECT TO_DATE('2015-12-01', 'YYYY-MM-DD') AS D
    FROM dual -- //start
    UNION ALL
    SELECT ADD_MONTHS(D, 1) AS D
    FROM dates
    WHERE D < TO_DATE('2016-12-01', 'YYYY-MM-DD') -- end//
  )
  SELECT
    h.DEPARTMENT,
    h.REGISTRATION,
    h.DAT,
    h.HEADCOUNT,
    d.DISMISS
  FROM
    --// headcount //--
    (SELECT
       emp."Подразделение" DEPARTMENT,
       emp."Оформление"    REGISTRATION,
       dates.D             DAT,
       COUNT(emp."ФИО")    HEADCOUNT
     FROM dates
       LEFT JOIN JIRA_READER.V_EMPLOYEES_SHORT emp
         ON (dates.D >= emp."Дата приёма"
             AND dates.D <= NVL(emp."Дата увольнения", TO_DATE('2016-12-01', 'yyyy-mm-dd')))
     WHERE emp."Оформление" IN ('Штат', 'Вентра')
     GROUP BY dates.D, emp."Подразделение", emp."Оформление") h
    LEFT JOIN
    --// dismiss //--
    (SELECT
       dem."Подразделение"          DEPARTMENT,
       dem."Оформление"             REGISTRATION,
       dates.D                      DAT,
       COUNT(dem."Дата увольнения") DISMISS
     FROM dates
       LEFT JOIN JIRA_READER.V_EMPLOYEES_SHORT dem
         ON (dates.D >= dem."Дата приёма" AND
             dem."Дата увольнения" >= dates.D
             AND dem."Дата увольнения" <= dates.D + TO_CHAR(LAST_DAY(TO_DATE(dates.D, 'YYYY-MM-DD')), 'DD')
         )
     WHERE dem."Оформление" IN ('Штат', 'Вентра')
     GROUP BY dates.D, dem."Подразделение", dem."Оформление") d
      ON h.DAT = d.DAT AND h.DEPARTMENT = d.DEPARTMENT AND h.REGISTRATION = d.REGISTRATION
  ORDER BY 1, 2
