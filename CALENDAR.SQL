-- Author:            Polina Azarova
-- Date of creation:  28.06.2016

CREATE OR REPLACE TYPE CALENDAR_TY IS OBJECT (D VARCHAR2(255), IS_WORKING_DAY INTEGER, CELEBRATION_TRIGGER INTEGER, CARRY_TRIGGER INTEGER);
CREATE OR REPLACE TYPE CALENDAR_TBL_TY IS TABLE OF CALENDAR_TY;

CREATE OR REPLACE FUNCTION REP_CALENDAR(p_year_st VARCHAR2, p_month_st VARCHAR2, p_day_st VARCHAR2)
  RETURN CALENDAR_TBL_TY
PIPELINED
IS
  CURSOR cur (c_year_st VARCHAR2, c_month_st VARCHAR2, c_day_st VARCHAR2)
  IS
    SELECT
      -- DAT,
      D,
      CASE -- не суббота или воскресенье
      WHEN TO_CHAR(dd.d, 'Dy') IN ('Сб', 'Вс')
        THEN 0
      ELSE 1
      END WORKING_DAY_TRIGGER, -- если выходной, то 0, else 1
      CELEBRATION_TRIGGER, -- если праздник, то 0, else <null>
      CARRY_TRIGGER -- если перенос рабочего дня на выходной, то 1, else <null>
    FROM
      (SELECT * FROM V_CALENDAR_CELEBRATION) vcc
      RIGHT JOIN (SELECT TRUNC(to_date(c_year_st||'-'||c_month_st||'-'||c_day_st, 'yyyy-mm-dd')) d
                  FROM dual) dd ON to_date(vcc.DAT, 'yyyy-mm-dd') = TRUNC(dd.d)
    ORDER BY 1
  ;
  BEGIN
    FOR rec IN cur (p_year_st, p_month_st, p_day_st)
    LOOP
      PIPE ROW (CALENDAR_TY(rec.D, rec.IS_WORKING_DAY, rec.CELEBRATION_TRIGGER, rec.CARRY_TRIGGER));
    END LOOP;
    RETURN;
  END;
