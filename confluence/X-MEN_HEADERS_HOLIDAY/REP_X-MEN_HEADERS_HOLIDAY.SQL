-- Author:            Polina Azarova
-- Date of creation:  19.05.2016
-- Description:       Function for X-MEN HEADERS holiday
--                    REP_X-MEN_HEADERS_HOLIDAY -> REP_X-MEN_HEADERS_DATES

CREATE OR REPLACE TYPE X-MEN_HEADERS_HOLIDAY_TY IS OBJECT (ФИО     VARCHAR2(255), RN VARCHAR2(255),
                                                           HOLIDAY VARCHAR2(255), Итого VARCHAR2(255));
CREATE OR REPLACE TYPE X-MEN_HEADERS_HOLIDAY_TBL_TY IS TABLE OF CITEB_HEADERS_HOLIDAY_TY;

CREATE OR REPLACE FUNCTION REP_X-MEN_HEADERS_HOLIDAY(p_year_st VARCHAR2)
  RETURN X-MEN_HEADERS_HOLIDAY_TBL_TY
PIPELINED
IS
  CURSOR cur (c_year_st VARCHAR2)
  IS
    SELECT
      d.ФИО                            ФИО,
      d.RN                             RN,
      -- выведет значения через запятую
      REPLACE(d.HOLIDAY, '><', '>, <') HOLIDAY,
      i.Итого                          Итого
    FROM
      (SELECT
         COALESCE(s.FIO, e.FIO) ФИО,
         COALESCE(s.RN, e.RN)   RN,
         e.HOLIDAY || s.HOLIDAY HOLIDAY
       FROM
         (SELECT
            sdh.FIO                       FIO,
            sdh.RN                        RN,
            -- через запятую в таблице
            LISTAGG(sdh.HOLIDAY, ', ')
            WITHIN GROUP (
              ORDER BY sdh.HOLIDAY_ORDER) HOLIDAY
          FROM
            (SELECT
               ROWNUM                                                                            HOLIDAY_ORDER,
               sd.FIO,
               sd.RN,
               -- ссылка на issue отпуска в jira
               '<a href="http://jira/browse/VAC-' || sd.issuenum || '">' || sd.HOLIDAY || '</a>' HOLIDAY
             FROM (SELECT
                     vac.FIO,
                     vac.ISSUENUM,
                     -- в ячейку месяца начала отпуска
                     vac.RN_S                                                                             RN,
                     CASE vac.END_DAY
                     -- удаление даты начала, если отпуск длиной один день
                     WHEN vac.START_DAY
                       THEN vac.END_DAY
                     ELSE
                       -- а если отпуск не один день, то
                       (CASE vac.START_MONTH
                        -- если отпуск не попал на границу месяцев,
                        -- выводим через чёрточку время отпуска
                        WHEN vac.END_MONTH
                          THEN vac.START_DAY || '-' || vac.END_DAY
                        -- а конец отпуска, который попал на другой месяц, подтягивается из нижней части джойна
                        ELSE
                          -- если первый день отпуска попал на последний день месяца, то выводим это число
                          (CASE vac.START_DAY
                           WHEN TO_CHAR(LAST_DAY(TO_DATE(vac.DATE_START, 'YYYY-MM-DD')), 'DD')
                             THEN vac.START_DAY
                           ELSE
                             -- в противном случае выводим через черточку первый день отпуска и последний день месяца
                             vac.START_DAY || '-' ||
                             TO_CHAR(LAST_DAY(TO_DATE(vac.DATE_START, 'YYYY-MM-DD')), 'DD') END) END) END HOLIDAY
                   FROM (SELECT *
                         FROM TABLE (REP_X-MEN_HEADERS_DATES(c_year_st))) vac
                   ORDER BY vac.FIO, vac.RN_E, vac.START_DAY
                  ) sd
            ) sdh
          GROUP BY sdh.FIO, sdh.RN
         ) s

         FULL JOIN -- обработка ситуации, когда отпуск попал на границу двух месяцев

         (SELECT
            edh.FIO,
            edh.RN,
            edh.HOLIDAY
          FROM
            (SELECT
               ROWNUM HOLIDAY_ORDER,
               ed.FIO,
               ed.RN,
               ed.ISSUENUM,
               ed.HOLIDAY
             FROM (SELECT
                     vac.FIO,
                     vac.ISSUENUM,
                     -- в ячейку с месяцем окончания отпуска
                     vac.RN_E RN,
                     CASE vac.END_MONTH
                     WHEN vac.START_MONTH
                       -- дата удаляется, если отпуск длиной один день
                       THEN NULL
                     -- если попал на границу, то вторая часть отпуска была с первого дня месяца
                     ELSE
                       (CASE vac.END_DAY
                        WHEN '1'
                          THEN '<a href="http://jira/browse/VAC-' || vac.ISSUENUM || '">' || '1' || '</a>'
                        ELSE
                          '<a href="http://jira/browse/VAC-' || vac.ISSUENUM || '">' || '1-' || vac.END_DAY || '</a>'
                        END)
                     END      HOLIDAY
                   FROM
                     (SELECT *
                      FROM TABLE (REP_X-MEN_HEADERS_DATES(c_year_st))) vac
                  ) ed
             WHERE HOLIDAY IS NOT NULL
            ) edh
         ) e ON s.FIO = e.FIO AND s.RN = e.RN) d
      JOIN
      (SELECT
         -- джойн чтобы посчитать Итого
         fvac.FIO,
         SUM(fvac.COUNTER) Итого
       FROM (SELECT
               emp.SUMMARY                     FIO,
               vc.DATE_END - vc.DATE_START + 1 COUNTER
             FROM JIRA_READER.V_EMPLOYEES emp
               JOIN (SELECT DISTINCT
                       v.FIO,
                       -- TODO deprecated, switch to JIRA_READER.V_EMPLOYEES.EMPLOYEE
                       v.DATE_START,
                       v.DATE_END
                     FROM JIRA_READER.V_VACATIONS_CHANGES v
                     WHERE v.REASON_ID = '13040') vc
                 ON emp.SUMMARY = vc.FIO
             WHERE vc.DATE_START > TRUNC(TO_DATE(c_year_st || '-01-01', 'YYYY-MM-DD'))
                   AND vc.DATE_END < TRUNC(TO_DATE(c_year_st || '-12-31', 'YYYY-MM-DD'))
             ORDER BY FIO) fvac
       GROUP BY fvac.FIO
      ) i ON i.FIO = d.ФИО;
  BEGIN
    FOR rec IN cur (p_year_st)
    LOOP
      PIPE ROW (X-MEN_HEADERS_HOLIDAY_TY(rec.ФИО, rec.RN, rec.HOLIDAY, rec.Итого));
    END LOOP;
    RETURN;
  END;

/*
SELECT
d.ФИО,
d."1"  Январь,
d."2"  Февраль,
d."3"  Март,
d."4"  Апрель,
d."5"  Май,
d."6"  Июнь,
d."7"  Июль,
d."8"  Август,
d."9"  Сентябрь,
d."10" Октябрь,
d."11" Ноябрь,
d."12" Декабрь,
d.Итого
FROM
(SELECT *
 FROM TABLE (REP_X-MEN_HEADERS_HOLIDAY('$year_st')))
 PIVOT (MAX(HOLIDAY)
   FOR RN
   IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)) d
ORDER BY 1
*/

