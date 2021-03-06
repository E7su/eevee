CREATE OR REPLACE FORCE VIEW JIRA_READER.V_VACATIONS_REASONS AS
  SELECT
    cfo.ID              ID,
    cfo.CUSTOMVALUE     VALUE,
    cfoe.IS_WORKING_DAY IS_WORKING_DAY,
    cfoe.COLOR          COLOR
  FROM
    JIRA.CUSTOMFIELDOPTION cfo
    JOIN
    (
      SELECT           NULL ID, NULL IS_WORKING_DAY,  NULL COLOR FROM dual
      UNION ALL SELECT 13040,   0,                    '#ADFF2F'  FROM dual -- Отпуск
      UNION ALL SELECT 13041,   0,                    '#7B68EE'  FROM dual -- Отгул
      UNION ALL SELECT 13042,   0,                    '#FF0000'  FROM dual -- Болезнь
      UNION ALL SELECT 13043,   1,                    '#808080'  FROM dual -- Работа из дома
      UNION ALL SELECT 13044,   0,                    '#00BFFF'  FROM dual -- Командировка
      UNION ALL SELECT 13045,   0,                    '#00BFFF'  FROM dual -- Обучение
      UNION ALL SELECT 13046,   0,                    '#00BFFF'  FROM dual -- Конференция
    ) cfoe ON cfoe.ID = cfo.ID
WHERE
  cfo.CUSTOMFIELD = 12871;
