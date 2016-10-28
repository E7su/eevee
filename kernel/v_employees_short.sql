CREATE OR REPLACE FORCE VIEW "JIRA_READER"."V_EMPLOYEES_SHORT" ("ФИО", "Ключ", "Дата приёма", "Дата увольнения", "Подразделение", "Оформление", "День рождения", "SAP ID", "Телефон", "Должность", "Город", "Описание", "Статус")
AS
  SELECT
    j.SUMMARY "ФИО",
    p.PKEY || '-' || j.ISSUENUM "Ключ",
    c2.DATEVALUE "Дата приёма",
    c6.DATEVALUE "Дата увольнения",
    o.CUSTOMVALUE "Подразделение",
    o2.CUSTOMVALUE "Оформление",
    c5.DATEVALUE "День рождения",
    c7.STRINGVALUE "SAP ID",
    c10.STRINGVALUE "Телефон",
    o3.CUSTOMVALUE "Должность",
    o4.CUSTOMVALUE "Город",
    TO_CHAR(j.DESCRIPTION) "Описание",
    CASE j.issuestatus
      WHEN '10809'
      THEN 'Open'
      ELSE 'Close'
    END "Статус"
  FROM jira.JIRAISSUE j
    INNER JOIN jira.PROJECT p ON (j.PROJECT = p.ID AND p.PKEY = 'EMP')
    LEFT JOIN jira.CUSTOMFIELDVALUE c2 ON (c2.ISSUE = j.ID AND c2.CUSTOMFIELD = 12376)      -- Дата приёма
    LEFT JOIN jira.CUSTOMFIELDVALUE c3 ON (c3.ISSUE = j.ID AND c3.CUSTOMFIELD = 12373)
    LEFT JOIN jira.CUSTOMFIELDOPTION o ON (c3.STRINGVALUE = TO_CHAR(o.ID))                  -- Подразделение
    LEFT JOIN jira.CUSTOMFIELDVALUE c4 ON (c4.ISSUE = j.ID AND c4.CUSTOMFIELD = 12375)
    LEFT JOIN jira.CUSTOMFIELDOPTION o2 ON (c4.STRINGVALUE = TO_CHAR(o2.ID))
    LEFT JOIN jira.CUSTOMFIELDVALUE c5 ON (c5.ISSUE = j.ID AND c5.CUSTOMFIELD = 12372)      -- День рождения
    LEFT JOIN jira.CUSTOMFIELDVALUE c6 ON (c6.ISSUE = j.ID AND c6.CUSTOMFIELD = 12570)      -- Дата увольнения
    LEFT JOIN jira.CUSTOMFIELDVALUE c7 ON (c7.ISSUE = j.ID AND c7.CUSTOMFIELD = 12470)      -- SAP ID
    LEFT JOIN jira.CUSTOMFIELDVALUE c8 ON (c8.ISSUE = j.ID AND c8.CUSTOMFIELD = 12374)
    LEFT JOIN jira.CUSTOMFIELDOPTION o3 ON (c8.STRINGVALUE = TO_CHAR(o3.ID))                -- Должность
    LEFT JOIN jira.CUSTOMFIELDVALUE c9 ON (c9.ISSUE = j.ID AND c9.CUSTOMFIELD = 12377)
    LEFT JOIN jira.CUSTOMFIELDOPTION o4 ON (c9.STRINGVALUE = TO_CHAR(o4.ID))                -- Город
    LEFT JOIN jira.CUSTOMFIELDVALUE c10 ON (c10.ISSUE = j.ID AND c10.CUSTOMFIELD = 12471);  -- Телефон


COMMENT ON COLUMN V_EMPLOYEES_SHORT."ФИО" IS 'ФИО';
COMMENT ON COLUMN V_EMPLOYEES_SHORT."Ключ" IS 'Ключ';
COMMENT ON COLUMN V_EMPLOYEES_SHORT."Дата приёма" IS 'Дата приёма';
COMMENT ON COLUMN V_EMPLOYEES_SHORT."Дата увольнения" IS 'Дата увольнения';
COMMENT ON COLUMN V_EMPLOYEES_SHORT."Подразделение" IS 'Подразделение';
COMMENT ON COLUMN V_EMPLOYEES_SHORT."Оформление" IS 'Оформление';
COMMENT ON COLUMN V_EMPLOYEES_SHORT."День рождения" IS 'День рождения';
COMMENT ON COLUMN V_EMPLOYEES_SHORT."SAP ID" IS 'SAP ID';
COMMENT ON COLUMN V_EMPLOYEES_SHORT."Телефон" IS 'Номер телефона';
COMMENT ON COLUMN V_EMPLOYEES_SHORT."Должность" IS 'Должность';
COMMENT ON COLUMN V_EMPLOYEES_SHORT."Город" IS 'Расположение';
COMMENT ON COLUMN V_EMPLOYEES_SHORT."Описание" IS 'Описание';
COMMENT ON COLUMN V_EMPLOYEES_SHORT."Статус" IS 'Статус';
