-- Author:            Polina Azarova
-- Date of creation:  19.05.2016
-- Description:       X-MEN HEADERS vacations dates

CREATE OR REPLACE VIEW JIRA_READER.V_REP_X-MEN_HEADERS_DATES AS
  SELECT
    vc.FIO,
    vc.ISSUENUM,
    vc.DATE_START,
    TO_CHAR(EXTRACT(DAY FROM vc.DATE_START))   START_DAY,
    TO_CHAR(EXTRACT(DAY FROM vc.DATE_END))     END_DAY,
    TO_CHAR(EXTRACT(MONTH FROM vc.DATE_START)) START_MONTH,
    TO_CHAR(EXTRACT(MONTH FROM vc.DATE_END))   END_MONTH,
    EXTRACT(MONTH FROM vc.DATE_START)          RN_S,
    EXTRACT(MONTH FROM vc.DATE_END)            RN_E
  FROM JIRA_READER.V_EMPLOYEES_SHORT e
    LEFT JOIN (SELECT DISTINCT
                 v.FIO,
                 v.ISSUENUM,
                 v.DATE_START,
                 v.DATE_END
               FROM JIRA_READER.V_VACATIONS_CHANGES v
               WHERE v.REASON_ID = '13040'
              ) vc ON e.ФИО = vc.FIO
  WHERE (vc.FIO IN
          ('Magneto',
           'Wolverine',
           'Mystique',
           'Professor X',
           'Bishop',
           'Storm',
           'Nightcrawler',
           'Sprite',
           'Cyclops',
           'Iceman',
           'Thunderbird',
           'Colossus')
         AND e."Дата увольнения" IS NULL
         --         AND vc.DATE_START > TRUNC(TO_DATE('$year_st' || '-01-01', 'yyyy-mm-dd'))
         --         AND vc.DATE_END < TRUNC(TO_DATE('$year_st' || '-12-31', 'yyyy-mm-dd')) AND
         --         e."Дата увольнения" IS NULL OR (TRUNC(TO_DATE(e."Дата увольнения", 'yyyy-mm-dd')) >=
         --                                         TRUNC(TO_DATE('$year_st' || '-01-01', 'yyyy-mm-dd'))))
         AND vc.DATE_START > TRUNC(TO_DATE('2017-01-01', 'yyyy-mm-dd'))
         AND vc.DATE_END < TRUNC(TO_DATE('2017-12-31', 'yyyy-mm-dd')) AND
         e."Дата увольнения" IS NULL OR (TRUNC(TO_DATE(e."Дата увольнения", 'yyyy-mm-dd')) >=
                                         TRUNC(TO_DATE('2017-01-01', 'yyyy-mm-dd'))))
--   ORDER BY vc.FIO
