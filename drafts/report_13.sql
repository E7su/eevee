-- Author:            Polina Azarova
-- Date of creation:  23.05.2016
-- Description:       A report on the average duration of the work
--                    for the selected period in the context of administration,
--                    registration ( state / vendor )

--------------------------------------//13//---------------------------------------
CREATE OR REPLACE VIEW V_WORK_DURATION AS
  SELECT
    emp."Дата приёма",
    NVL(emp."Дата увольнения", CURRENT_DATE) "Работа до",
    emp."Оформление",
    emp."Подразделение"
  FROM V_EMPLOYEES_SHORT emp
  WHERE emp."Оформление" IN ('', '') AND emp."Дата приёма" > TO_DATE('2010-01-01', 'yyyy-mm-dd')
  ORDER BY 1, 2


-- WITH dates (d) AS (
--   SELECT TO_DATE('2013-01-01', 'yyyy-mm-dd') AS d
--   FROM dual --start
--   UNION ALL
--   SELECT ADD_MONTHS(d, 1) AS d
--   FROM dates
--   WHERE d < CURRENT_DATE /*--end*/
-- )
-- SELECT
--   dates.D,
--   s."Подразделение",
--   s."Оформление",
--   --   стаж в годах,
--   --   для  уволенных -на дату увольнения,
--   --   для  работающих -на текущую дату
--   ROUND(AVG(MONTHS_BETWEEN(s."Работа до", s."Дата приёма") / 12), 2) "Ср-я пр-ть, лет"
-- FROM dates
--   LEFT JOIN (
--               SELECT *
--               FROM V_WORK_DURATION
--             ) s
--     ON (dates.d >= s."Дата приёма" --OR s."Дата приёма" IS NULL
--         AND dates.d <= s."Работа до")
-- --WHERE s."Оформление" = '' --AND s."Подразделение" = ''
-- GROUP BY dates.d, s."Подразделение", s."Оформление"
