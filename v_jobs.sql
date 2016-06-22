CREATE OR REPLACE VIEW JIRA_READER.V_JOBS AS
  SELECT
    c9.DATEVALUE           "Job Start Date",
    c10.DATEVALUE          "Job End Date",
    j.SUMMARY              "Summary",
    TO_CHAR(j.DESCRIPTION) "Description",
    o.CUSTOMVALUE          "Employee Department",
    o2.CUSTOMVALUE         "Employee Registration",
    o3.CUSTOMVALUE         "Employee Position",
    CASE j.issuestatus
    WHEN '10809'
      THEN 'Open'
    ELSE 'Close'
    END                    "Status"
  FROM jira.JIRAISSUE j
    INNER JOIN jira.PROJECT p ON (j.PROJECT = p.ID AND p.PKEY = 'JOB')
    -- список подразделений
    LEFT JOIN jira.CUSTOMFIELDVALUE c3 ON (c3.ISSUE = j.ID AND c3.CUSTOMFIELD = 12373)
    -- непосредственно подразделение
    LEFT JOIN jira.CUSTOMFIELDOPTION o ON (c3.STRINGVALUE = TO_CHAR(o.ID))
    -- список возможных оформленеий
    LEFT JOIN jira.CUSTOMFIELDVALUE c4 ON (c4.ISSUE = j.ID AND c4.CUSTOMFIELD = 12375)
    -- непосредственно оформление: штат/вентра и тд
    LEFT JOIN jira.CUSTOMFIELDOPTION o2 ON (c4.STRINGVALUE = TO_CHAR(o2.ID))
    -- список должностей
    LEFT JOIN jira.CUSTOMFIELDVALUE c8 ON (c8.ISSUE = j.ID AND c8.CUSTOMFIELD = 12374)
    -- непосредственно должность
    LEFT JOIN jira.CUSTOMFIELDOPTION o3 ON (c8.STRINGVALUE = TO_CHAR(o3.ID))
    -- Дата создания вакансии
    LEFT JOIN jira.CUSTOMFIELDVALUE c9 ON (c9.ISSUE = j.ID AND c9.CUSTOMFIELD = 13077)
    -- Дата закрытия вакансии
    LEFT JOIN jira.CUSTOMFIELDVALUE c10 ON (c10.ISSUE = j.ID AND c10.CUSTOMFIELD = 13078);

COMMENT ON COLUMN V_JOBS."Job Start Date" IS 'Дата создания вакансии';
COMMENT ON COLUMN V_JOBS."Job End Date" IS 'Дата закрытия вакансии';
COMMENT ON COLUMN V_JOBS."Summary" IS 'Название вакансии';
COMMENT ON COLUMN V_JOBS."Description" IS 'Описание вакансии';
COMMENT ON COLUMN V_JOBS."Employee Department" IS 'Подразделение';
COMMENT ON COLUMN V_JOBS."Employee Registration" IS 'Оформление';
COMMENT ON COLUMN V_JOBS."Employee Position" IS 'Должность';
COMMENT ON COLUMN V_JOBS."Status" IS 'Статус';