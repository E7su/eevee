CREATE OR REPLACE VIEW V_REP_X-MEN_HEADERS_DATES AS
  SELECT
    vc.FIO,
    EXTRACT(DAY FROM vc.DATE_START)   START_DAY,
    EXTRACT(DAY FROM vc.DATE_END)     END_DAY,
    EXTRACT(MONTH FROM vc.DATE_START) START_MONTH,
    EXTRACT(MONTH FROM vc.DATE_END)   END_MONTH,
    EXTRACT(MONTH FROM vc.DATE_START) RN_S,
    EXTRACT(MONTH FROM vc.DATE_END)   RN_E
  FROM V_EMPLOYEES_SHORT e
    LEFT JOIN (SELECT DISTINCT
                 v.FIO,
                 v.DATE_START,
                 v.DATE_END
               FROM V_VACATIONS_CHANGES v
               WHERE v.REASON_ID = '13040'
              ) vc ON e.ФИО = vc.FIO
               WHERE (fio = 'Magneto' OR
                     fio = 'Wolverine' OR
                     fio = 'Mystique' OR
                     fio = 'Professor X' OR
                     fio = 'Bishop' OR
                     fio = 'Storm' OR
                     fio = 'Nightcrawler' OR
                     fio = 'Sprite' OR
                     fio = 'Cyclops' OR
                     fio = 'Iceman' OR
                     fio = 'Thunderbird' OR
                     fio = 'Colossus')
        AND e."Дата увольнения" IS NULL
        AND vc.DATE_START > TRUNC(TO_DATE('2016-01-01', 'yyyy-mm-dd'))
        AND vc.DATE_END < TRUNC(TO_DATE('2016-12-31', 'yyyy-mm-dd')) AND
        e."Дата увольнения" IS NULL OR (TRUNC(TO_DATE(e."Дата увольнения", 'yyyy-mm-dd')) >=
                                        TRUNC(TO_DATE('2016-01-01', 'yyyy-mm-dd')))
  ORDER BY vc.FIO
