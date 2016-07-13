CREATE OR REPLACE TYPE VACATION_TY IS OBJECT (FIO      VARCHAR2(255), REASON VARCHAR2(255), DAT DATE,
                                              ISSUENUM VARCHAR2(255), COLOR VARCHAR2(255), IS_WORKING_DAY NUMBER);
CREATE OR REPLACE TYPE VACATION_TBL_TY IS TABLE OF VACATION_TY;

CREATE OR REPLACE FUNCTION REP_VACATIONS(p_year_st VARCHAR2, p_month_st VARCHAR2, p_fio VARCHAR2, p_proj VARCHAR2,
                                         p_reg     VARCHAR2, p_dep VARCHAR2)
  RETURN VACATION_TBL_TY
PIPELINED
IS
  CURSOR cur (c_year_st VARCHAR2, c_month_st VARCHAR2, c_fio VARCHAR2, c_proj VARCHAR2, c_reg VARCHAR2, c_dep VARCHAR2)
  IS
    WITH dates (D) AS (
      SELECT TO_DATE(c_year_st || '-' || c_month_st || '-01', 'yyyy-mm-dd')
      FROM dual --start
      UNION ALL
      SELECT D + 1 AS day_of_month
      FROM dates
      WHERE D < LAST_DAY(D) --end
    )
    SELECT DISTINCT
      -- обогащение пары (сотрудник, тек. дата) триггером рабочих дней
      em.EMPLOYEE                    FIO,
      em.DAY_CURRENT                 DAT,
      IS_WORKING_DAY(em.DAY_CURRENT) IS_WORKING_DAY,
      COALESCE(vv.REASON, '0')       REASON,
      vv.ISSUENUM,
      vv.COLOR
    FROM (SELECT
            e."ФИО" EMPLOYEE,
            dates.D DAY_CURRENT
          FROM
            V_EMPLOYEES_FULL e
            JOIN dates ON (1 = 1)
                          AND c_fio IS NULL
                          OR REGEXP_LIKE(lower(e."ФИО"), lower(c_fio))
                             AND (c_proj IS NULL
                                  OR (REGEXP_LIKE(e."Проекты", c_proj)))
                             -- REGEXP_LIKE ищет вхождение подстроки в строку
                             AND (c_reg IS NULL
                                  OR e."Оформление" = c_reg)
                             AND (c_dep IS NULL
                                  OR e."Подразделение" = c_dep)
         ) em

      -- получение отсутствий сотрудника
      LEFT JOIN
      (SELECT
         vc.DATE_START,
         vc.DATE_END,
         vc.FIO,
         vc.ISSUENUM,
         vr.VALUE REASON,
         vr.COLOR
       FROM
         V_VACATIONS_CHANGES vc
         JOIN V_VACATIONS_REASONS vr ON (vr.ID = vc.REASON_ID)
      ) vv ON (vv.FIO = em.employee)
    WHERE
      em.DAY_CURRENT >= TRUNC(vv.DATE_START) AND
      em.DAY_CURRENT <= TRUNC(vv.DATE_END) OR vv.DATE_START IS NULL AND vv.DATE_END IS NULL;
  BEGIN
    FOR rec IN cur (p_year_st, p_month_st, p_fio, p_proj, p_reg, p_dep)
    LOOP
      PIPE ROW (VACATION_TY(rec.FIO, rec.REASON, rec.DAT, rec.ISSUENUM, rec.COLOR, rec.IS_WORKING_DAY));
    END LOOP;
    RETURN;
  END;

/*
SELECT t.*
FROM
  (SELECT
     fr.FIO,
     fr.RN,
     CASE fr.IS_WORKING_DAY
     WHEN 0
       THEN '<tr style="background-color:grey">' || fr.REASON
     -- если выходной, то красим фон ячейки серым,
     -- а если был заведён отпуск в выходной/праздник, то поверх серого фона рисуем цветной квадратик
     ELSE fr.REASON
     END REASON
   FROM (
          SELECT
            f.FIO,
            extract(DAY
                    FROM f.DAT)                           RN,
            f.IS_WORKING_DAY,
            -- если отсутствие, то рисуем цветной квадратик
            CASE f.REASON
            WHEN '0'
              THEN NULL
            ELSE '<span style="background-color:' || f.COLOR || '"/>' || '<a href="http://jira/browse/VAC-' ||
                 f.ISSUENUM || '">' || '__' || '</a>' END REASON
          FROM (
                 SELECT *
                 FROM TABLE (REP_VACATIONS('2016', '02', '', '', '', ''))
               ) f
        ) fr
  )
   PIVOT (
     MAX(REASON)
     FOR RN
     IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31)
   ) t
ORDER BY 1
*/
