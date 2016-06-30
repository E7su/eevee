-- Author:            Polina Azarova
-- Date of creation:  19.04.2016
-- Description:       Teams of a certain employee in a date

CREATE OR REPLACE VIEW JIRA_READER.V_REP_TEAMS_COUNT AS
  (
    SELECT
      tcc.EMPLOYEE                                                                        EMPLOYEE,
      tcc.DAY                                                                             DAY,
      -- разделение строки на подстроки, разделённые запятыми
      TRIM(REGEXP_SUBSTR(tcc.TEAMS, '[^,]+', 1, lines.column_value))                      TEAM,
      -- триггер будних дней (выходной/праздник 0, будень/перенос 1)
      tcc.IS_WORKING_DAY                                                                  IS_WORKING_DAY,
      -- триггер отсутствий (отпуск/отгул... 1, работа из дома 0)
      tcc.IS_VACATION_DAY                                                                 IS_VACATION_DAY,
      -- причина отсутствия
      tcc.VACATION_REASON                                                                 VACATION_REASON,
      -- процент участия каждого сотрудника в команде в заданный день
      tcc.IS_WORKING_DAY * (1 - tcc.IS_VACATION_DAY) / (REGEXP_COUNT(tcc.TEAMS, ',') + 1) WORKED_DAY_PERCENT
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
             e.SUMMARY                       EMPLOYEE,
             tcd.DAY_CURRENT                 DAY,
             IS_WORKING_DAY(tcd.DAY_CURRENT) IS_WORKING_DAY,
             CASE WHEN vvv.VALUE IS NULL
               THEN 0
             ELSE 1 END                      IS_VACATION_DAY,
             vvv.VALUE                       VACATION_REASON,
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
             LEFT JOIN V_REP_TEAMS_CHANGES vv ON (vv.EMPLOYEE_ID = tcd.EMPLOYEE_ID AND vv.DAY = tcd.DAY_LASTCHANGE)

             -- получение имени сотрудника по его ID
             JOIN V_EMPLOYEES e ON (e.ID = tcd.EMPLOYEE_ID)

             -- получение отсутствий сотрудника
             LEFT JOIN
             (
               SELECT
                 vc.*,
                 vr.VALUE
               FROM
                 V_VACATIONS_CHANGES vc
                 JOIN V_VACATIONS_REASONS vr ON (vr.ID = vc.REASON_ID AND vr.IS_WORKING_DAY = 0)
             ) vvv ON (tcd.DAY_CURRENT >= TRUNC(vvv.DATE_START) AND tcd.DAY_CURRENT <= TRUNC(vvv.DATE_END)
                       AND vvv.FIO = e.SUMMARY)

         ) tcc,
      TABLE (CAST(MULTISET
                  (SELECT LEVEL
                   FROM dual
                   CONNECT BY instr(tcc.TEAMS, ',', 1, LEVEL - 1) > 0
                  ) AS SYS.odciNumberList)) lines
  )
