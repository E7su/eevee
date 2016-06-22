CREATE OR REPLACE VIEW JIRA_READER.V_REP_TEAMS_CHANGES AS
  -- если список групп сотрудника изменялся - брать из истории изменений карточки
  SELECT
    v.EMPLOYEE_ID                       EMPLOYEE_ID,
    CASE
    WHEN cid.ID IS NULL
      THEN v.CREATE_DAY
    ELSE to_date(to_char(cid.NEWSTRING), 'dd.mm.yyyy')
    END                                 DAY,
    to_char(ci.NEWSTRING)               TEAMS,
    REGEXP_COUNT(ci.NEWSTRING, ',') + 1 TEAMS_COUNT
  FROM
    (
      SELECT
        j.ID              EMPLOYEE_ID,
        TRUNC(cg.CREATED) CREATE_DAY,
        MAX(cg.ID)        GROUP_ID,
        -- ID последней группы изменений команд в ДАННЫЙ день
        MAX(ci.ID)        ITEM_ID -- ID записи со списком команд в данной группе
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
      WHERE
        j.PROJECT = 12780 -- INNER JOIN jira.PROJECT p ON (j.PROJECT = p.ID AND p.PKEY = 'EMP')
      GROUP BY
        j.ID,
        TRUNC(cg.CREATED)

    ) v
    LEFT JOIN JIRA.CHANGEITEM ci ON (ci.ID = v.ITEM_ID)
    LEFT JOIN JIRA.CHANGEGROUP cgi ON (cgi.ID = v.GROUP_ID)
    LEFT JOIN JIRA.CHANGEITEM cid ON (cid.GROUPID = cgi.ID
                                      AND cid.FIELDTYPE = 'custom'
                                      AND cid.FIELD IN
                                          (
                                            'Team Assign Date',
                                            'Дата включения в команду'
                                          )
    )

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
                                   AND j.PROJECT =
                                       12780 -- INNER JOIN jira.PROJECT p ON (j.PROJECT = p.ID AND p.PKEY = 'EMP')
      --       AND j.summary IN ('Magneto')
    )
  GROUP BY
    j.ID,
    j.CREATED
