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
      dat.FIO,
      dat.REASON AS               REASON,
      EXTRACT(DAY
              FROM dat.STARTDATE) RN
    FROM
      (SELECT
         vc.FIO,
         dd.D AS  STARTDATE,
         vr.VALUE REASON,
         emp."ФИО",
         emp."Подразделение",
         emp."Оформление"

       FROM V_VACATIONS_CHANGES vc
         LEFT JOIN (
                     SELECT TRUNC(TO_DATE(c_year_st || '-' || c_month_st || '-' || c_day_st, 'yyyy-mm-dd') + ROWNUM -
                                  1) D -- дата начала
                     FROM dual
                     CONNECT BY ROWNUM <=
                                TRUNC(to_date(c_year_end || '-' || c_month_end || '-' || c_day_end, 'yyyy-mm-dd')) -
                                TRUNC(TO_DATE(c_year_st || '-' || c_month_st || '-' || c_day_st, 'yyyy-mm-dd')) + 1
                   ) dd ON (dd.D >= TRUNC(vc.DATE_START) AND dd.D <= TRUNC(vc.DATE_END))

         JOIN V_EMPLOYEES_SHORT emp ON (
           emp."ФИО" = vc.FIO)
         JOIN V_VACATIONS_REASONS vr ON (vr.ID = vc.REASON_ID)
      ) dat
    WHERE dat.FIO IS NOT NULL
          AND dat.STARTDATE IS NOT NULL
          AND (c_fio IS NULL
               OR (LOWER(dat."ФИО") LIKE '%' || LOWER(c_fio) || '%'))
          AND (c_reg IS NULL
               OR dat."Оформление" = c_reg)
          AND (c_dep IS NULL
               OR dat."Подразделение" = c_dep);

  BEGIN
    FOR rec IN cur (p_year_st, p_month_st, p_day_st, p_year_end, p_month_end, p_day_end, p_fio, p_reg, p_dep)
    LOOP
      PIPE ROW (VACATION_REASONS_TY(rec.FIO, rec.REASON, rec.RN));
    END LOOP;
    RETURN;
  END;
  
/*  SELECT t.*
FROM
  (
    SELECT *
    FROM TABLE (REP_VACATIONS_REASONS('$year_st', '$month_st', '$day_st', '$year_end', '$month_end', '$day_end', '$fio', '$reg', '$dep'))
  )
    PIVOT (
      count(rn)
      FOR reason
      IN ('Отпуск', 'Отгул', 'Болезнь', 'Работа из дома', 'Командировка', 'Обучение', 'Конференция')) t
ORDER BY 1
*/
