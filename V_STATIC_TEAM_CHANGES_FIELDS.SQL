CREATE OR REPLACE VIEW JIRA_READER.V_STATIC_TEAM_CHANGES_FIELDS AS
  SELECT           NULL ID, NULL FIELD                  FROM dual
  UNION ALL SELECT 0,       'Team List'                 FROM dual
  UNION ALL SELECT 1,       'Список команд'             FROM dual
  UNION ALL SELECT 2,       'Employee Team List'        FROM dual -- TODO delete
  UNION ALL SELECT 10,      'Team Assign Date'          FROM dual
  UNION ALL SELECT 11,      'Дата включения в команду'  FROM dual
  UNION ALL SELECT 12,      'Employee Team Assign Date' FROM dual; -- TODO delete
