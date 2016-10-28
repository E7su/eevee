CREATE OR REPLACE TYPE VACATION_COUNT_TY IS OBJECT (FIO   VARCHAR2(255), PASS INTEGER,
                                                    PLANN INTEGER, SURPLUS INTEGER, EXPECTED INTEGER);
CREATE OR REPLACE TYPE VACATION_COUNT_TBL_TY IS TABLE OF VACATION_COUNT_TY;

CREATE OR REPLACE FUNCTION REP_VACATIONS_COUNT(p_year_st VARCHAR2, p_year_end VARCHAR2, p_dep VARCHAR2, p_reg VARCHAR2,
                                               p_fio     VARCHAR2)
  RETURN VACATION_COUNT_TBL_TY
PIPELINED
IS
  CURSOR cur (c_year_st VARCHAR2, c_year_end VARCHAR2, c_dep VARCHAR2, c_reg VARCHAR2, c_fio VARCHAR2)
  IS
    SELECT
      t.ФИО,
      SUM(t.IS_PASSED)                          "Потрачено",
      SUM(t.IS_VACATION) - SUM(t.IS_PASSED)     "В планах",
      MAX(t.MAX_VACATIONS) - SUM(t.IS_VACATION) "Осталось",
      MAX(t.MAX_VACATIONS)                      "Положено"
    FROM (SELECT
            emp.ФИО,
            vac.VACATION_DAY,

            -- all planned & passed vacations have 1 in this field
            CASE WHEN vac.VACATION_DAY <= TRUNC(SYSDATE)
              THEN 1
            ELSE 0 END                                              IS_PASSED,

            -- all planned vacations will have 1 in this field
            CASE WHEN vac.VACATION_DAY IS NOT NULL
              THEN 1
            ELSE 0 END                                              IS_VACATION,

            (TO_NUMBER(c_year_end) - TO_NUMBER(c_year_st) + 1) * 28 MAX_VACATIONS

          FROM V_EMPLOYEES_SHORT emp
            LEFT JOIN (SELECT DISTINCT
                         vc.FIO,
                         dd.D VACATION_DAY
                       FROM V_VACATIONS_CHANGES vc
                         LEFT JOIN (
                                     SELECT
                                       TRUNC(TO_DATE(c_year_st || '-' || '01' || '-01', 'yyyy-mm-dd') + ROWNUM - 1) d
                                     FROM dual
                                     CONNECT BY ROWNUM <=
                                                TRUNC(TO_DATE(c_year_end || '-' || '12' || '-31', 'yyyy-mm-dd')) -
                                                TRUNC(TO_DATE(c_year_st || '-' || '01' || '-01', 'yyyy-mm-dd')) +
                                                1) dd
                           ON (dd.D >= TRUNC(vc.DATE_START) AND dd.D <= TRUNC(vc.DATE_END))
                         JOIN V_VACATIONS_REASONS vr ON (vr.ID = vc.REASON_ID)
                       WHERE vr.VALUE = 'Отпуск') vac
              ON emp.ФИО = vac.FIO
          WHERE (c_fio IS NULL OR (LOWER(emp.ФИО) LIKE '%' || LOWER(c_fio) || '%'))
                AND (c_reg IS NULL OR emp."Оформление" = c_reg)
                AND (c_dep IS NULL OR emp."Подразделение" = c_dep)
                AND emp."Дата увольнения" IS NULL
                OR (TRUNC(TO_DATE(emp."Дата увольнения", 'yyyy-mm-dd')) >=
                    TRUNC(TO_DATE(c_year_st || '-' || '01' || '-01', 'yyyy-mm-dd')))) t
    GROUP BY t.ФИО
    ORDER BY t.ФИО;

  BEGIN
    FOR rec IN cur (p_year_st, p_year_end, p_dep, p_reg, p_fio)
    LOOP
      PIPE ROW (VACATION_COUNT_TY(rec."ФИО", rec."Потрачено", rec."В планах", rec."Осталось", rec."Положено"));
    END LOOP;
    RETURN;
  END;

/*
SELECT
  FIO      "ФИО",
  PASS     "Потрачено",
  PLANN    "В планах",
  SURPLUS  "Осталось",
  EXPECTED "Положено"
FROM TABLE (REP_VACATIONS_COUNT('$year_st', '$year_end', '$dep', '$reg', '$fio'))
*/
