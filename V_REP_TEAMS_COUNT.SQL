-- Author:            Polina Azarova
-- Date of creation:  19.04.2016
-- Description:       Teams of a certain employee in a date

CREATE OR REPLACE VIEW JIRA_READER.V_REP_TEAMS_COUNT AS
  (
    SELECT DISTINCT
      -- для упрощения понимания состояния триггеров:
      -- 1 == человек работал
      -- 0 == не работал

      w1.EMPLOYEE,
      w1.DAY,
      w1.TEAM,
      -- триггер праздника (если праздник, то 0)
      -- если не праздник, то <null>
      vc.CELEBRATION_TRIGGER,
      -- если сотрудник отсутсвует и не работает из дома, то 0, в остальных случаях -- <null> // для применения coalesce
      w2.WORK_TRIGGER,
      -- триггер переноса рабочего дня на выходной
      -- если перенос произошёл, то 1
      -- если нет переноса -- <null>
      vc.CARRY_TRIGGER,
      -- триггер будних дней (выходной 0, else 1)
      w1.WEEKDAY_TRIGGER,
      -- количество команд
      REGEXP_COUNT(TEAM_TMP, ',') + 1   COUNT_TEAMS,
    -- последовательно проверяем до тех пор, пока не получим не нулловое значение:
    -- 0. праздник ли это, если да, то при вычислении формулы процент участия сотрудника в командах будет 0,
    --    ибо 0/team_count == 0
    -- 1. отсутствие в офисе или отсутствие работы из дома, тогда 0, else <null> // то есть если сейчас не праздник
    --    и сотрудник не отсутствует, то скорее всего от присутствует на работе, но нужно проверить пункты 2, 3.
    -- 2. если из-за переноса праздника выходной день стал рабочим, то == 1, вычислится значение в этот день,
    --    в противном случае <null>
    -- 3. в случае если в трёх предыдущих триггерах <null> результат берём из триггера будних дней: в выходные 0, else 1
      COALESCE(CELEBRATION_TRIGGER, TO_CHAR(WORK_TRIGGER), CARRY_TRIGGER, TO_CHAR(WEEKDAY_TRIGGER)) /
      (REGEXP_COUNT(TEAM_TMP, ',') + 1) WORKED_DAY_PERCENT
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
                SELECT TO_DATE('2016-01-01', 'yyyy-mm-dd')
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
       WHERE e.ID = tcc.EMPLOYEE_ID) w1
      LEFT JOIN
      (SELECT
         v.FIO FIO,
         d     VACATION_DAY,
         v.REASON_ID,
         0     WORK_TRIGGER -- если сотрудник отсутствует и не работает из дома, то = 0
       FROM V_VACATIONS v
         LEFT JOIN (
                     SELECT TRUNC(to_date('2016-01-01', 'yyyy-mm-dd') + rownum - 1) d
                     FROM dual
                     CONNECT BY rownum <= TRUNC(current_date) - TRUNC(to_date('2016-01-01', 'yyyy-mm-dd')) + 1) dd
           ON (dd.d >= TRUNC(v.DATE_START) AND dd.d <= TRUNC(v.DATE_END))
         JOIN V_VACATIONS_REASONS vr ON (vr.ID = v.REASON_ID AND vr.IS_WORKING_DAY = 1)
        ) w2
        ON w1.EMPLOYEE = w2.FIO AND w1.DAY = w2.VACATION_DAY
      LEFT JOIN V_CALENDAR_CELEBRATION vc ON to_char(to_date(vc.DAT, 'yyyy-mm-dd')) = to_char(DAY)
  )
