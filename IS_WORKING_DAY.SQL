-- Author:            Polina Azarova
-- Date of creation:  28.06.2016
-- Description:       Function to determine the working days

CREATE OR REPLACE TYPE IS_WORKING_DAY_TY IS OBJECT (DAT VARCHAR2(255), IS_WORKING_DAY INTEGER);
CREATE OR REPLACE TYPE IS_WORKING_DAY_TBL_TY IS TABLE OF IS_WORKING_DAY_TY;

CREATE OR REPLACE FUNCTION IS_WORKING_DAY(p_year_st VARCHAR2, p_month_st VARCHAR2, p_day_st VARCHAR2)
  RETURN IS_WORKING_DAY_TBL_TY
PIPELINED
IS
  CURSOR cur (c_year_st VARCHAR2, c_month_st VARCHAR2, c_day_st VARCHAR2)
  IS
    SELECT
      w.DAT,
      -- последовательно проверяем до тех пор, пока не получим не нулловое значение:
      -- 0. праздник ли это, если да, то == 0, else <null>
      -- 1. если из-за переноса праздника выходной день стал рабочим, то == 1, else <null>
      -- 2. в случае если в трёх предыдущих триггерах <null> результат берём из триггера будних дней: в выходные 0, else 1
      COALESCE(w.CELEBRATION_TRIGGER, w.CARRY_TRIGGER, TO_CHAR(w.WEEKDAY_TRIGGER)) IS_WORKING_DAY
    FROM
      (SELECT
         dd.d DAT,
         -- триггер праздника (если праздник, то 0)
         -- если не праздник, то <null>
         vc.CELEBRATION_TRIGGER,
         -- триггер переноса рабочего дня на выходной
         -- если перенос произошёл, то 1
         -- если нет переноса -- <null>
         vc.CARRY_TRIGGER,
         -- триггер будних дней (выходной 0, else 1)
         CASE -- не суббота или воскресенье
         WHEN TO_CHAR(dd.d, 'Dy') IN ('Сб', 'Вс')
           THEN 0
         ELSE 1
         END  WEEKDAY_TRIGGER
       FROM
         (SELECT *
          FROM V_CALENDAR_CELEBRATION) vc
         RIGHT JOIN (SELECT TRUNC(to_date(c_year_st || '-' || c_month_st || '-' || c_day_st, 'yyyy-mm-dd')) d
                     FROM dual) dd ON to_date(vc.DAT, 'yyyy-mm-dd') = TRUNC(dd.d)
       ORDER BY 1) w;
  BEGIN
    FOR rec IN cur (p_year_st, p_month_st, p_day_st)
    LOOP
      PIPE ROW (IS_WORKING_DAY_TY(rec.DAT, rec.IS_WORKING_DAY));
    END LOOP;
    RETURN;
  END;
