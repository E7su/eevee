CREATE OR REPLACE VIEW JIRA_READER.V_REP_TEAMS_CHANGES AS
/*SELECT
  www.EMPLOYEE_ID EMPLOYEE_ID,
--   www.DATE_CREATE,
--   www.DAY_ASSIGN,
--   www.TEAMS,
  taf.DAY_ASSIGN_RIGHT DAY,
--   www.TAF_DATE_CREATE_MAX,
  taf.TEAMS TEAMS,
  REGEXP_COUNT(taf.TEAMS, ',') + 1 TEAMS_COUNT
FROM
  (
    -- для перемещений "задним числом" (с непустым DAY_ASSIGN), идёт поиск списка команд,
    -- актуального во время создания перемещения
    SELECT
      vvvv.EMPLOYEE_ID,
      vvvv.DATE_CREATE,
      vvvv.DAY_ASSIGN,
      vvvv.TEAMS,
      vvvv.DAY_ASSIGN_RIGHT DAY_ASSIGN_RIGHT,
--       vvvv.GROUP_ID,
--       taf.GROUP_ID TAF_GROUP_ID,
      MAX(taf.DATE_CREATE) TAF_DATE_CREATE_MAX

    FROM
      (*/
        SELECT
          -- восстановление данных по найденному ID группы
          vvv.EMPLOYEE_ID      EMPLOYEE_ID,
          taf.DATE_CREATE      DATE_CREATE,
          taf.DAY_ASSIGN       DAY_ASSIGN,
          taf.TEAMS            TEAMS,
          taf.DAY_ASSIGN_RIGHT DAY_ASSIGN_RIGHT,
          vvv.GROUP_ID         GROUP_ID
        FROM (
               SELECT
                 -- если в течения дня было несколько перемещений (в т.ч. фиктивных),
                 -- нужно выбрать самую последнюю (номера групп увеличиваются во времени)
                 taf.EMPLOYEE_ID      EMPLOYEE_ID,
                 MAX(taf.GROUP_ID)    GROUP_ID,
                 taf.DAY_ASSIGN_RIGHT DAY_ASSIGN_RIGHT
               FROM
                 V_REP_TEAMS_APPEND_FIELDS taf
               WHERE taf.EMPLOYEE_ID = 90287 -- TODO Виноградов
               GROUP BY
                 taf.EMPLOYEE_ID,
                 taf.DAY_ASSIGN_RIGHT
             ) vvv
          JOIN V_REP_TEAMS_APPEND_FIELDS taf
            ON (taf.GROUP_ID = vvv.GROUP_ID AND
                taf.DAY_ASSIGN_RIGHT = vvv.DAY_ASSIGN_RIGHT)
      /*) vvvv
      -- актуальные команды на момент изменения "задним числом"
      JOIN V_REP_TEAMS_APPEND_FIELDS taf ON (taf.EMPLOYEE_ID = vvvv.EMPLOYEE_ID)
    WHERE
      vvvv.DAY_ASSIGN_RIGHT + 1 > taf.DATE_CREATE
    --           vvvv.GROUP_ID >= taf.GROUP_ID
    --         ORDER BY 1,2,3,4,5
    GROUP BY
          vvvv.EMPLOYEE_ID,
          vvvv.DATE_CREATE,
          vvvv.DAY_ASSIGN,
          vvvv.TEAMS,
          vvvv.DAY_ASSIGN_RIGHT

) www
  JOIN V_REP_TEAMS_APPEND_FIELDS taf
    ON (taf.EMPLOYEE_ID = www.EMPLOYEE_ID AND
        taf.DATE_CREATE = www.TAF_DATE_CREATE_MAX)
*/
