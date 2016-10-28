CREATE OR REPLACE VIEW JIRA_READER.V_CALENDAR_CELEBRATION AS
  SELECT
    TO_CHAR('2016-01-01') DAT,
    
    '0'                   CELEBRATION_TRIGGER, -- триггер праздника (если праздник, то 0), если не праздник -- <null>
    
    NULL                  CARRY_TRIGGER  -- триггер переноса рабочего дня на выходной
                                         -- если перенос произошёл, то 1,  если нет переноса -- <null>
  FROM dual
  UNION ALL
  SELECT
    '2016-01-04',
    '0',
    NULL
  FROM dual
  UNION ALL
  SELECT
    '2016-01-05',
    '0',
    NULL
  FROM dual
  UNION ALL
  SELECT
    '2016-01-06',
    '0',
    NULL
  FROM dual
  UNION ALL
  SELECT
    '2016-01-07',
    '0',
    NULL
  FROM dual
  UNION ALL
  SELECT
    '2016-01-08',
    '0',
    NULL
  FROM dual
  UNION ALL
  SELECT
    '2016-02-22',
    '0',
    NULL
  FROM dual
  UNION ALL
  SELECT
    '2016-02-23',
    '0',
    NULL
  FROM dual
  UNION ALL
  SELECT
    '2016-03-07',
    '0',
    NULL
  FROM dual
  UNION ALL
  SELECT
    '2016-03-08',
    '0',
    NULL
  FROM dual
  UNION ALL
  SELECT
    '2016-05-02',
    '0',
    NULL
  FROM dual
  UNION ALL
  SELECT
    '2016-05-03',
    '0',
    NULL
  FROM dual
  UNION ALL
  SELECT
    '2016-05-09',
    '0',
    NULL
  FROM dual
  UNION ALL
  SELECT
    '2016-06-13',
    '0',
    NULL
  FROM dual
  UNION ALL
  SELECT
    '2016-11-04',
    '0',
    NULL
  FROM dual
  UNION ALL
  SELECT
    '2016-02-20' DAT,
    NULL,
    '1'
  FROM dual;
