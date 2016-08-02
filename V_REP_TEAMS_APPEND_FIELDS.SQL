-- Author:            Polina Azarova
-- Date of creation:  27.05.2016
-- Description:       Append changing team fields of the employee

CREATE OR REPLACE VIEW JIRA_READER.V_REP_TEAMS_APPEND_FIELDS AS
  -- выбор списков команд и дат перемещений из __групп изменения__ карточки сотрудника
  SELECT
    -- объединение пар полей из одной группы в одну запись
    MAX(v.EMPLOYEE_ID)             EMPLOYEE_ID,
    MAX(v.DATE_CREATE)             DATE_CREATE,
    MAX(v.DAY_ASSIGN)              DAY_ASSIGN,
    MAX(v.TEAMS)                   TEAMS,
    -- дата "задним числом" переопределяет дату создания
    TRUNC(COALESCE(
              MAX(v.DAY_ASSIGN),
              MAX(v.DATE_CREATE))) DAY_ASSIGN_RIGHT,
    v.GROUP_ID                     GROUP_ID
  FROM
    (
      -- выбор всех полей, связанных с перемещением между командами
      SELECT
        j.ID                                                          EMPLOYEE_ID,-- ID сотрудника
        cg.CREATED                                                    DATE_CREATE,-- дата создания группы перемещений
        CASE WHEN f.ID >= 10 THEN TO_DATE(ci.NEWSTRING, 'dd.mm.yyyy') ELSE NULL END DAY_ASSIGN, -- NULL или день перемещения
        CASE WHEN f.ID <  10 THEN TO_CHAR(ci.NEWSTRING) ELSE NULL END TEAMS,      -- NULL или список команд
        cg.ID                                                         GROUP_ID    -- ID группы перемещений
      FROM JIRA.JIRAISSUE j
        JOIN JIRA.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
        JOIN JIRA.CHANGEITEM ci ON (ci.GROUPID = cg.ID AND ci.FIELDTYPE = 'custom')
        JOIN V_STATIC_TEAM_CHANGES_FIELDS f ON (f.FIELD = ci.FIELD)
      WHERE
        j.PROJECT = 12780
    ) v
  GROUP BY
    v.GROUP_ID


  UNION ALL

  -- выбор списка команд сотрудника, данные ему при устройстве на работу (многие - пустые)
  SELECT
    i.EMPLOYEE_ID         EMPLOYEE_ID,
    i.DATE_CREATE   DATE_CREATE,
    NULL                  DAY_ASSIGN,
    TO_CHAR(ci.OLDSTRING) TEAMS,
    TRUNC(i.DATE_CREATE)   DAY_ASSIGN_RIGHT,
    cg.ID                 GROUP_ID
  FROM
    (
      -- выбор самой ранней группы изменений списка команд у сотрудника
      SELECT
        j.ID        EMPLOYEE_ID,
        j.CREATED   DATE_CREATE, -- дата создания карточки сотрудника
        MIN(cg.ID)  GROUP_ID
      FROM JIRA.JIRAISSUE j
        JOIN JIRA.CHANGEGROUP cg ON (cg.ISSUEID = j.ID)
        JOIN JIRA.CHANGEITEM ci ON (ci.GROUPID = cg.ID AND ci.FIELDTYPE = 'custom')
        JOIN V_STATIC_TEAM_CHANGES_FIELDS f ON (f.FIELD = ci.FIELD AND f.ID < 10)
        LEFT JOIN jira.CUSTOMFIELDVALUE c ON (c.ISSUE = j.ID AND c.CUSTOMFIELD = 12376) --дата приема на работу
      WHERE
        j.PROJECT = 12780
      GROUP BY
        j.ID,
        j.CREATED
    ) i
    JOIN JIRA.CHANGEGROUP cg ON (cg.ID = i.GROUP_ID)
    JOIN JIRA.CHANGEITEM ci ON (ci.GROUPID = cg.ID AND ci.FIELDTYPE = 'custom')
    JOIN V_STATIC_TEAM_CHANGES_FIELDS f ON (f.FIELD = ci.FIELD AND f.ID < 10)
  WHERE
    ci.OLDSTRING IS NOT NULL;
;
