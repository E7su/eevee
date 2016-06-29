CREATE OR REPLACE TYPE VACATION_REASONS_TY IS OBJECT (FIO VARCHAR2(255), reason VARCHAR2(255), rn INTEGER);
CREATE OR REPLACE TYPE VACATION_REASONS_TBL_TY IS TABLE OF VACATION_REASONS_TY;

CREATE OR REPLACE FUNCTION REP_VACATIONS_REASONS(p_year_st  VARCHAR2, p_month_st VARCHAR2, p_day_st VARCHAR2,
                                               p_year_end VARCHAR2, p_month_end VARCHAR2, p_day_end VARCHAR2,
                                               p_fio      VARCHAR2, p_reg VARCHAR2, p_dep VARCHAR2)
  RETURN VACATION_REASONS_TBL_TY
PIPELINED
IS
  CURSOR cur (c_year_st VARCHAR2, c_month_st VARCHAR2, c_day_st VARCHAR2, c_year_end VARCHAR2, c_month_end VARCHAR2,
    c_day_end VARCHAR2, c_fio VARCHAR2, c_reg VARCHAR2, c_dep VARCHAR2)
  IS
    SELECT DISTINCT
      dat.fio                     "Ф.И.О.",
      dat.REASON AS            reason,
      extract(DAY
              FROM dat.startdate) rn
    FROM
      (SELECT
         v.FIO,
         dd.d AS startdate,
         vr.VALUE REASON,
         emp."ФИО",
         emp."Подразделение",
         emp."Оформление"

       FROM V_VACATIONS v
         LEFT JOIN (
                     SELECT TRUNC(to_date(c_year_st || '-' || c_month_st || '-' || c_day_st, 'yyyy-mm-dd') + rownum -
                                  1) d -- дата начала
                     FROM dual
                     CONNECT BY rownum <=
                                TRUNC(to_date(c_year_end || '-' || c_month_end || '-' || c_day_end, 'yyyy-mm-dd')) -
                                TRUNC(to_date(c_year_st || '-' || c_month_st || '-' || c_day_st, 'yyyy-mm-dd')) + 1
                   ) dd ON (dd.d >= TRUNC(v.DATE_START) AND dd.d <= TRUNC(v.DATE_END))

         JOIN V_EMPLOYEES_SHORT emp ON (
           emp."ФИО" = v.fio)
        JOIN V_VACATIONS_REASONS vr ON (vr.ID = v.REASON_ID)
      ) dat
    WHERE fio IS NOT NULL
          AND startdate IS NOT NULL
          AND (c_fio IS NULL
               OR (lower(dat."ФИО") LIKE '%' || lower(c_fio) || '%'))
          AND (c_reg IS NULL
               OR dat."Оформление" = c_reg)
          AND (c_dep IS NULL
               OR dat."Подразделение" = c_dep);

  BEGIN
    FOR rec IN cur (p_year_st, p_month_st, p_day_st, p_year_end, p_month_end, p_day_end, p_fio, p_reg, p_dep)
    LOOP
      PIPE ROW (VACATION_REASONS_TY(rec."Ф.И.О.", rec.reason, rec.rn));
    END LOOP;
    RETURN;
  END;
