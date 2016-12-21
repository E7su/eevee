-- Author:            Polina Azarova
-- Date of creation:  08.07.2016
-- Description:       A report on the turnover ratio for the selected period in the context of administration,
--                    registration ( state / vendor )

--                    V_REP_TURNOVER_RATIO -> V_REP_AVG_TURNOVER -> V_REP_HEADCOUNT

--------------------------------------//14//---------------------------------------
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
    NVL(d.DEPARTMENT, h.DEPARTMENT)     DEP,
    NVL(d.REGISTRATION, h.REGISTRATION) REG,
    NVL(d.DAT, h.DAT)                   DAT,
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
             AND dates.D <= NVL(emp."Дата увольнения", TO_DATE('2016-12-01', 'YYYY-MM-DD')))
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
             AND dem."Дата увольнения" <= dates.D + TO_CHAR(LAST_DAY(dates.D), 'DD'))

       -- проверяем причину ухода
       LEFT JOIN JIRA.JIRAISSUE j ON j.ISSUENUM = SUBSTR(dem."Ключ", 5) AND j.project = 12780
       LEFT JOIN JIRA.CUSTOMFIELDVALUE cfv
         ON (cfv.CUSTOMFIELD = 14886 AND cfv.ISSUE = j.ID) -- 'Employee Unregistration Reason'
     WHERE dem."Оформление" IN ('Штат', 'Вентра') AND
           (cfv.STRINGVALUE IS NULL OR cfv.STRINGVALUE IN (15065, 15062)) -- 'Принудительно', 'Добровольно'

     GROUP BY dates.D, dem."Подразделение", dem."Оформление", CFV.STRINGVALUE) d
      ON h.DAT = d.DAT AND h.DEPARTMENT = d.DEPARTMENT AND h.REGISTRATION = d.REGISTRATION
  ORDER BY 1, 2, 3
