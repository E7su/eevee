CREATE OR REPLACE TYPE VACATION_COUNT_TY IS OBJECT (FIO VARCHAR2(255), pass INTEGER, plann INTEGER, surplus INTEGER, expected INTEGER);
CREATE OR REPLACE TYPE VACATION_COUNT_TBL_TY IS TABLE OF VACATION_COUNT_TY;

CREATE OR REPLACE FUNCTION REP_VACATIONS_COUNT(p_year_st VARCHAR2, p_year_end VARCHAR2, p_dep VARCHAR2, p_reg VARCHAR2,
                                               p_fio     VARCHAR2)
  RETURN VACATION_COUNT_TBL_TY
PIPELINED
IS
  CURSOR cur (c_year_st VARCHAR2, c_year_end VARCHAR2, c_dep VARCHAR2, c_reg VARCHAR2, c_fio VARCHAR2)
  IS
    SELECT
      fio_final                             "ФИО",
      SUM(is_passed)                        "Потрачено",
      SUM(is_vacation) - SUM(is_passed)     "В планах",
      MAX(MAX_VACATIONS) - SUM(is_vacation) "Осталось",
      MAX(MAX_VACATIONS)                    "Положено"
    FROM (
      SELECT
        emp.ФИО                                                   fio_final,
        vacation_day,

        -- all planned & passed vacations have 1 in this field
        CASE WHEN vacation_day <= TRUNC(SYSDATE)
          THEN 1
        ELSE 0 END                                                is_passed,

        -- all planned vacations will have 1 in this field
        CASE WHEN vacation_day IS NOT NULL
          THEN 1
        ELSE 0 END                                                is_vacation,

        (to_number(c_year_end) - to_number(c_year_st) + 1) * 28 MAX_VACATIONS

      FROM V_EMPLOYEES_SHORT emp
        LEFT JOIN (
                    SELECT DISTINCT
                      fio,
                      d vacation_day
                    FROM V_VACATIONS v
                      LEFT JOIN (
                                  SELECT TRUNC(to_date(c_year_st||'-'||'01'||'-01', 'yyyy-mm-dd') + rownum - 1) d
                                  FROM dual
                                  CONNECT BY rownum <= TRUNC(to_date(c_year_end||'-'||'12'||'-31', 'yyyy-mm-dd')) -
                                                       TRUNC(to_date(c_year_st||'-'||'01'||'-01', 'yyyy-mm-dd')) + 1) dd
                        ON (dd.d >= TRUNC(v.DATE_START) AND dd.d <= TRUNC(v.DATE_END))
                      JOIN jira.jiraISSUE iss ON (
                        iss.issuenum = v.issuenum
                        AND iss.issuestatus IN (10015, 11507, 11705)) -- Done, Confirmation, Planning
                      JOIN V_VACATIONS_REASONS vr ON (vr.ID = v.REASON_ID)
                    WHERE vr.VALUE = 'Отпуск') vac
          ON emp.ФИО = vac.fio

      WHERE (c_fio IS NULL OR (lower(emp.ФИО) LIKE '%' || lower(c_fio) || '%'))
            AND (c_reg IS NULL OR emp."Оформление" = c_reg)
            AND (c_dep IS NULL OR emp."Подразделение" = c_dep)
            AND emp."Дата увольнения" IS NULL
            OR (TRUNC(to_date(emp."Дата увольнения", 'yyyy-mm-dd')) >= TRUNC(to_date(c_year_st||'-'||'01'||'-01', 'yyyy-mm-dd'))))

    GROUP BY fio_final
    ORDER BY fio_final;

  BEGIN
    FOR rec IN cur (p_year_st, p_year_end, p_dep, p_reg, p_fio)
    LOOP
      PIPE ROW (VACATION_COUNT_TY(rec."ФИО", rec."Потрачено", rec."В планах", rec."Осталось", rec."Положено"));
    END LOOP;
    RETURN;
  END;
