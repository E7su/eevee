CREATE OR REPLACE TYPE VACATION_TY IS OBJECT (FIO VARCHAR2(255), reason VARCHAR2(255), rn INTEGER);
CREATE OR REPLACE TYPE VACATION_TBL_TY IS TABLE OF VACATION_TY;

CREATE OR REPLACE FUNCTION REP_VACATIONS(p_year_st VARCHAR2, p_month_st VARCHAR2, p_fio VARCHAR2, p_proj VARCHAR2,
                                         p_reg     VARCHAR2, p_dep VARCHAR2)
  RETURN VACATION_TBL_TY
PIPELINED
IS
  CURSOR cur (c_year_st VARCHAR2, c_month_st VARCHAR2, c_fio VARCHAR2, c_proj VARCHAR2, c_reg VARCHAR2, c_dep VARCHAR2)
  IS
    SELECT
  t.FIO,
  -- номер дня месяца
  t.RN,
  -- отображение причины в confluence html (цвет стикера/фона ячейки)
  -- если нет причины отсутствия, то проверяем, не выходной ли это
  coalesce(t.REASON, t.HOLIDAY) REASON
FROM
  (SELECT
     f.FIO,
     f.RN,
     -- триггер отсутствий (отпуск/отгул... 1, работа из дома 0)
     f.REASON,
     f.IS_WORK_DAY,
     CASE WHEN IS_WORK_DAY = '0' -- если выходной
       THEN '<tr style="background-color:grey">' -- то ячейка серая
     END HOLIDAY
   FROM
     (SELECT iwd.FIO, iwd.RN, vr.REASON, iwd.IS_WORK_DAY
      FROM
        (SELECT DISTINCT
           dat.FIO,
           extract(DAY
                   FROM dat.dat) RN,
           dat.IS_WORK_DAY
         FROM
           (SELECT
              v.SUMMARY            FIO,
              IS_WORKING_DAY(dd.d) IS_WORK_DAY,
              dd.d                 dat
            FROM V_EMPLOYEES v
              JOIN
              (SELECT TRUNC(to_date(to_date(c_year_st || '-' || c_month_st || '-01', 'yyyy-mm-dd') + rownum - 1) d
               FROM dual
               CONNECT BY rownum <=
                          CAST(to_char(LAST_DAY(to_date(c_year_st || '-' || '01' || '-01', 'yyyy-mm-dd')), 'dd') AS
                               INT)) dd ON 1 = 1
           ) dat
        ) iwd
        LEFT JOIN (SELECT
                     dat.FIO,
                     extract(DAY
                             FROM dat.STARTDATE) RN,
                     REASON
                   FROM
                     (SELECT
                        v.FIO,
                        dd.d AS                              STARTDATE,
                        v.REASON_ID,
                        '<span style="background-color:' || CASE v.REASON_ID
                                                            WHEN '13040'
                                                              THEN 'GreenYellow' -- Отпуск
                                                            WHEN '13041'
                                                              THEN 'blue' -- Отгул
                                                            WHEN '13042'
                                                              THEN 'red' -- Болезнь
                                                            WHEN '13043'
                                                              THEN 'grey' -- Работа из дома
                                                            WHEN '13044'
                                                              THEN 'cyan' -- Командировка
                                                            WHEN '13045'
                                                              THEN 'cyan' -- Обучение
                                                            WHEN '13046'
                                                              THEN 'cyan' -- Конференция
                                                            ELSE 'Medium'
                                                            END || '"/>' || '<a href="http://jira/browse/VAC-' ||
                        v.ISSUENUM || '">' || '__' || '</a>' REASON,
                        v.ISSUENUM
                      FROM V_VACATIONS_CHANGES v
                        JOIN V_EMPLOYEES_FULL emp ON (emp."ФИО" = v.FIO
                                                      AND (c_fio IS NULL
                                                           OR REGEXP_LIKE(lower(emp."ФИО"), lower(c_fio)))
                                                      AND (c_proj IS NULL
                                                           OR (REGEXP_LIKE(emp."Проекты", c_proj)))
                                                      -- REGEXP_LIKE ищет вхождение подстроки в строку
                                                      AND (c_reg IS NULL
                                                           OR emp."Оформление" = c_reg)
                                                      AND (c_dep IS NULL
                                                           OR emp."Подразделение" = c_dep)
                          )
                        LEFT JOIN
                        (SELECT TRUNC(to_date(c_year_st || '-' || c_month_st || '-01', 'yyyy-mm-dd') + rownum - 1) d
                         FROM dual
                         CONNECT BY rownum <=
                                    CAST(to_char(LAST_DAY(to_date(c_year_st || '-' || '01' || '-01', 'yyyy-mm-dd')), 'dd')
                                         AS
                                         INT)) dd
                          ON (dd.d >= TRUNC(v.DATE_START)
                              AND dd.d <= TRUNC(v.DATE_END))) dat
                  )vr
          ON vr.FIO = iwd.FIO AND vr.RN = iwd.RN) f
   ORDER BY 1, 2) t;

  BEGIN
    FOR rec IN cur (p_year_st, p_month_st, p_fio, p_proj, p_reg, p_dep)
    LOOP
      PIPE ROW (VACATION_TY(rec.FIO, rec.REASON, rec.RN));
    END LOOP;
    RETURN;
  END;
