CREATE OR REPLACE VIEW JIRA_READER.V_REP_TEAMS_CHANGES AS
  -- если список групп сотрудника изменялся - брать из истории изменений карточки
  SELECT
    vvvv.EMPLOYEE_ID                       EMPLOYEE_ID,
    CASE
    WHEN cid.ID IS NULL
      THEN
        vvvv.DATE_CREATE
    ELSE to_date(to_char(cid.NEWSTRING), 'dd.mm.yyyy')
    END
                                           DAY,
    vvvv.FIELDVALUE                        TEAMS,
    REGEXP_COUNT(vvvv.FIELDVALUE, ',') + 1 TEAMS_COUNT
  FROM
    (
      -- виртуальная таблица актуальных названий полей
      WITH fields (ID, FIELD) AS (
        SELECT
          NULL ID,
          NULL FIELD
        FROM dual
        UNION ALL SELECT
                    0,
                    'Team List'
                  FROM dual
        UNION ALL SELECT
                    1,
                    'Список команд'
                  FROM dual
        UNION ALL SELECT
                    10,
                    'Team Assign Date'
                  FROM dual
        UNION ALL SELECT
                    11,
                    'Дата включения в команду'
                  FROM dual
        UNION ALL SELECT
                    12,
                    'Employee Team Assign Date'
                  FROM dual
      )
      SELECT
        -- восстановление данный по найденному ID группы
        vvv.EMPLOYEE_ID EMPLOYEE_ID,
        cg.CREATED      DATE_CREATE,
        CASE WHEN f.ID >= 10
          THEN TO_DATE(ci.NEWSTRING)
        ELSE NULL END   DAY_ASSIGN,
        CASE WHEN f.ID < 10
          THEN TO_CHAR(ci.NEWSTRING)
        ELSE NULL END   TEAMS,

        vvv.GROUP_ID,
        vvv.DAY_ASSIGN_RIGHT
      FROM (
             SELECT
               -- актуальная группа операций перевода между командами для выбранного дня
               vv.EMPLOYEE_ID,
               MAX(vv.GROUP_ID) GROUP_ID,
               vv.DAY_ASSIGN_RIGHT
             FROM
               (
                 SELECT
                   -- объединение пар полей из одной группы в одну запись
                   MAX(v.EMPLOYEE_ID)             EMPLOYEE_ID,
                   MAX(v.DATE_CREATE)             DATE_CREATE,
                   TRUNC(COALESCE(
                             MAX(v.DAY_ASSIGN),
                             MAX(v.DATE_CREATE))) DAY_ASSIGN_RIGHT,
                   -- дата "задним числом" переопределяет дату создания
                   v.GROUP_ID                     GROUP_ID
                 FROM
                   (
                     SELECT
                       j.ID          EMPLOYEE_ID,
                       cg.CREATED    DATE_CREATE,
                       CASE WHEN f.ID >= 10
                         THEN TO_DATE(ci.NEWSTRING)
                       ELSE NULL END DAY_ASSIGN,
                       cg.ID         GROUP_ID
                     FROM JIRA.JIRAISSUE j
                       JOIN JIRA.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
                       JOIN JIRA.CHANGEITEM ci ON (ci.GROUPID = cg.ID AND ci.FIELDTYPE = 'custom')
                       JOIN fields f ON (f.FIELD = ci.FIELD)
                     WHERE
                       j.PROJECT = 12780 -- INNER JOIN jira.PROJECT p ON (j.PROJECT = p.ID AND p.PKEY = 'EMP')
                       AND j.ID = 84395 -- TODO Magneto
                   ) v
                 GROUP BY
                   v.GROUP_ID
               ) vv
             GROUP BY
               vv.EMPLOYEE_ID,
               vv.DAY_ASSIGN_RIGHT
           ) vvv
        JOIN JIRA.CHANGEGROUP cg ON (cg.ID = vvv.GROUP_ID)
        JOIN JIRA.CHANGEITEM ci ON (ci.GROUPID = cg.ID AND ci.FIELDTYPE = 'custom')
        JOIN fields f ON (f.FIELD = ci.FIELD AND f.ID < 10)
--     ) vvvv
/*
  UNION ALL

  -- если список групп сотрудника не изменялся, брать из поля в карточке
  SELECT
    j.ID                       EMPLOYEE_ID,
    TRUNC(j.CREATED)           DAY,
    LISTAGG(o6.CUSTOMVALUE, ',')
    WITHIN GROUP (
      ORDER BY o6.CUSTOMVALUE) TEAMS,
    COUNT(*)                   TEAMS_COUNT
  FROM JIRA.JIRAISSUE j
    LEFT JOIN jira.CUSTOMFIELDVALUE c13 ON (c13.ISSUE = j.ID AND c13.CUSTOMFIELD = 13173)
    -- список команд
    LEFT JOIN jira.CUSTOMFIELDOPTION o6 ON (c13.STRINGVALUE = TO_CHAR(o6.ID))
  -- непосредственно команда
  WHERE
    j.PROJECT = 12780 AND
    o6.CUSTOMVALUE IS NOT NULL AND -- заполнено поле списка команд
    j.ID NOT IN (
      SELECT
        DISTINCT j.ID EMPLOYEE_ID -- те, у кого хотя бы раз меняли команду после создания карточки
      FROM JIRA.JIRAISSUE j
        JOIN JIRA.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
        JOIN JIRA.CHANGEITEM ci ON (ci.GROUPID = cg.ID
                                    AND ci.FIELDTYPE = 'custom'
                                    AND ci.FIELD IN
                                        (
                                          'Team List',
                                          'Список команд'
                                        )
                                   )
            AND j.PROJECT = 12780 -- INNER JOIN jira.PROJECT p ON (j.PROJECT = p.ID AND p.PKEY = 'EMP')
      --       AND j.summary IN ('Magneto')
    )
  GROUP BY
    j.ID,
    j.CREATED
*/
