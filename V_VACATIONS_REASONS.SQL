CREATE OR REPLACE FORCE VIEW "JIRA_READER"."V_VACATIONS_REASONS" ("REASON_ID", "REASON") AS
SELECT  j.id, j.customvalue FROM jira.customfieldoption j
WHERE customfield = 12871
