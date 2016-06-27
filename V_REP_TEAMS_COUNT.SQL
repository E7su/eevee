-- Author:            Polina Azarova
-- Date of creation:  19.04.2016
-- Description:       Teams of a certain employee in a date

CREATE OR REPLACE VIEW JIRA_READER.V_REP_TEAMS_COUNT AS
  (
    SELECT DISTINCT
  -- для упрощения понимания состояния триггеров:
  -- 1 == человек работал
  -- 0 == не работал
  EMPLOYEE,
  DAY,
  TEAM,
  CELEBRATION_TRIGGER,
  -- триггер праздника (если праздник, то 0, если будни перенесли на выходной -- 1)
  -- если не праздник и ничего не переносили, то <null>
  WORK_TRIGGER,
  -- если сотрудник отсутсвует и не работает из дома, то 0, в остальных случаях <null> // для применения coalesce
  WEEKDAY_TRIGGER,
  -- триггер будних дней (выходной 0, else 1)
  REGEXP_COUNT(TEAM_TMP, ',') + 1   COUNT_TEAMS,
  COALESCE(CELEBRATION_TRIGGER, TO_CHAR(WORK_TRIGGER), TO_CHAR(WEEKDAY_TRIGGER)) /
  (REGEXP_COUNT(TEAM_TMP, ',') + 1) WORKED_DAY_PERCENT
  -- последовательно проверяем:
  -- 0. праздник ли это, если да, то при вычислении формулы процент участия сотрудника в командах будет нулевым,
  --    если из-за переноса праздника выходной день стал рабочим, то вычислится значение
  -- 1. если в триггер праздника хранит <null>, то аналогично проверяем следующий
  -- 2. в случае если в двух предыдущих триггерах <null> результат берём из триггера будних дней
FROM
  (SELECT
     e.SUMMARY                                                      EMPLOYEE,
     tcc.DAY                                                        DAY,
     -- разделение строки на подстроки, разделённые запятыми
     TRIM(REGEXP_SUBSTR(tcc.TEAMS, '[^,]+', 1, lines.column_value)) TEAM,
     tcc.IS_WORKING_DAY                                             WEEKDAY_TRIGGER,
     -- процент участия каждого сотрудника в команде в заданный день (в выходные = 0)
     tcc.TEAMS                                                      TEAM_TMP
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
            WHEN TO_CHAR(tcd.DAY_CURRENT, 'Dy') IN ('Сб', 'Вс')
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
                 ( SELECT LEVEL
                   FROM dual
                   CONNECT BY instr(tcc.TEAMS, ',', 1, LEVEL - 1) > 0
                 ) AS SYS.odciNumberList)) lines,
     V_EMPLOYEES e
   WHERE e.ID = tcc.EMPLOYEE_ID)
  LEFT JOIN
  (SELECT
     v.FIO FIO,
     d     VACATION_DAY,
     REASON_ID,
     0     WORK_TRIGGER -- если сотрудник отсутсвует и не работает из дома, то = 0
   FROM V_VACATION_REASONS v
     LEFT JOIN (
                 SELECT TRUNC(to_date('2016-01-01', 'yyyy-mm-dd') + rownum - 1) d
                 FROM dual
                 CONNECT BY rownum <= TRUNC(current_date) - TRUNC(to_date('2016-01-01', 'yyyy-mm-dd')) + 1) dd
       ON (dd.d >= TRUNC(v.DATE_START) AND dd.d <= TRUNC(v.DATE_END))
     JOIN jira.jiraISSUE iss ON (
       iss.ISSUENUM = v.issuenum
       AND iss.ISSUESTATUS IN (10015, 11507, 11705)) -- Done, Confirmation, Planning
   WHERE v.REASON_ID != 'Работа из дома')
    ON EMPLOYEE = FIO AND DAY = VACATION_DAY
  LEFT JOIN V_CALENDAR vc ON to_char(to_date(vc.DAT, 'yyyy-mm-dd')) = to_char(DAY)
  )
