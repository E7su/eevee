-- Date of creation:  19.04.2016
-- Description:       Teams of a certain employee in a date

CREATE OR REPLACE VIEW JIRA_READER.V_REP_TEAMS_COUNT AS
  (
    SELECT
      e.SUMMARY                                                      EMPLOYEE,
      tcc.DAY                                                        DAY,
      -- разделение строки на подстроки, разделённые запятыми
      TRIM(REGEXP_SUBSTR(tcc.TEAMS, '[^,]+', 1, lines.column_value)) TEAM,
      tcc.IS_WORKING_DAY                                             IS_WORKING_DAY,
      -- процент участия каждого сотрудника в команде в заданный день (в выходные = 0)
      tcc.IS_WORKING_DAY * (1 / (REGEXP_COUNT(tcc.TEAMS, ',') + 1))  WORKED_DAY_PERCENT
    FROM (
           WITH dates (D) AS (
             SELECT TO_DATE('2016-03-01', 'yyyy-mm-dd')
             FROM dual --start
             UNION ALL
             SELECT D + 1 AS day_of_month
             FROM dates
             WHERE D < CURRENT_DATE --end
           )
           SELECT
             -- обогащение пары (сотрудник, тек. дата) списком и количеством команд
             tcd.EMPLOYEE_ID EMPLOYEE_ID,
             tcd.DAY_CURRENT DAY,
             CASE -- не суббота или воскресенье
             WHEN TO_CHAR(tcd.DAY_CURRENT, 'Dy') IN ('Sat', 'Sun')
               THEN 0
             ELSE 1
             END             IS_WORKING_DAY,
             vv.TEAMS,
             vv.TEAMS_COUNT
           FROM (
                  -- для каждой пары (сотрудник, тек. дата) определение даты последнего изменения команд
                  SELECT
                    tc.EMPLOYEE_ID EMPLOYEE_ID,
                    dates.D        DAY_CURRENT,
                    MAX(tc.DAY)    DAY_LASTCHANGE
                  FROM
                    V_REP_TEAMS_CHANGES tc
                    RIGHT JOIN dates ON (tc.DAY <= dates.D)
                  GROUP BY
                    tc.EMPLOYEE_ID,
                    dates.D
                ) tcd
             LEFT JOIN V_REP_TEAMS_CHANGES vv
               ON (vv.EMPLOYEE_ID = tcd.EMPLOYEE_ID AND vv.DAY = tcd.DAY_LASTCHANGE)
         ) tcc,
      TABLE (CAST(MULTISET
                  (SELECT LEVEL
                   FROM dual
                   CONNECT BY instr(tcc.TEAMS, ',', 1, LEVEL - 1) > 0
                  ) AS SYS.odciNumberList)) lines,
      V_EMPLOYEES e
    WHERE e.ID = tcc.EMPLOYEE_ID
  )