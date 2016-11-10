CREATE OR REPLACE VIEW JIRA_READER.V_REP_X-MEN_HEADERS_DATES AS
-- Author:            Polina Azarova
-- Date of creation:  19.05.2016
-- Description:       Function for X-MEN HEADERS dates
--                    REP_X-MEN_HEADERS_HOLIDAY -> REP_X-MEN_HEADERS_DATES

CREATE OR REPLACE TYPEX-MEN_HEADERS_DATES_TY IS OBJECT (FIO         VARCHAR2(255),
                                                         ISSUENUM    VARCHAR2(255), DATE_START VARCHAR2(255),
                                                         START_DAY   VARCHAR2(255), END_DAY VARCHAR2(255),
                                                         START_MONTH VARCHAR2(255), END_MONTH VARCHAR2(255),
                                                         RN_S        VARCHAR2(255), RN_E VARCHAR2(255));
CREATE OR REPLACE TYPE X-MEN_HEADERS_DATES_TBL_TY IS TABLE OF CITEB_HEADERS_DATES_TY;

CREATE OR REPLACE FUNCTION REP_X-MEN_HEADERS_DATES(p_year_st VARCHAR2)
  RETURN X-MEN_HEADERS_DATES_TBL_TY
PIPELINED
IS
  CURSOR cur (c_year_st VARCHAR2)
  IS
    SELECT
      vc.FIO                                     FIO,
      vc.ISSUENUM                                ISSUENUM,
      vc.DATE_START                              DATE_START,
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
           AND vc.DATE_START > TRUNC(TO_DATE(c_year_st || '-01-01', 'yyyy-mm-dd'))
           AND vc.DATE_END < TRUNC(TO_DATE(c_year_st || '-12-31', 'yyyy-mm-dd')) AND
           e."Дата увольнения" IS NULL OR (TRUNC(TO_DATE(e."Дата увольнения", 'yyyy-mm-dd')) >=
                                           TRUNC(TO_DATE(c_year_st || '-01-01', 'yyyy-mm-dd'))));
  BEGIN
    FOR rec IN cur (p_year_st)
    LOOP
      PIPE ROW (X-MEN_HEADERS_DATES_TY(rec.FIO, rec.ISSUENUM, rec.DATE_START, rec.START_DAY, rec.END_DAY,
                                       rec.START_MONTH, rec.END_MONTH, rec.RN_S, rec.RN_E));
    END LOOP;
    RETURN;
  END;

/*
SELECT *
 FROM TABLE (REP_X-MEN_HEADERS_DATES('$year_st'))
*/
