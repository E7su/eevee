-- Author:            Polina Azarova
-- Date of creation:  19.05.2016
-- Description:       X-MEN HEADERS vacation

CREATE OR REPLACE VIEW V_REP_X-MEN_HEADERS_HOLIDAY AS
  SELECT
    s.ФИО,
    s."1" || e."1"   "Январь",
    s."2" || e."2"   "Февраль",
    s."3" || e."3"   "Март",
    s."4" || e."4"   "Апрель",
    s."5" || e."5"   "Май",
    s."6" || e."6"   "Июнь",
    s."7" || e."7"   "Июль",
    s."8" || e."8"   "Август",
    s."9" || e."9"   "Сентябрь",
    s."10" || e."10" "Октябрь",
    s."11" || e."11" "Ноябрь",
    s."12" || e."12" "Декабрь",
    s.Итого
  FROM
    (SELECT
       h.*,
       i.HOLIDAY Итого
     FROM
       (SELECT *
        FROM (SELECT
                tt.FIO                       ФИО,
                tt.RN,
                LISTAGG(tt.HOLIDAY, ', ')
                WITHIN GROUP (
                  ORDER BY tt.HOLIDAY_ORDER) HOLIDAY
              FROM
                (SELECT
                   ROWNUM HOLIDAY_ORDER,
                   t.FIO,
                   t.RN,
                   t.HOLIDAY
                 FROM (SELECT
                         vac.FIO,
                         -- в ячейку месяца начала отпуска
                         vac.RN_S RN,
                         CASE vac.END_DAY
                         WHEN vac.START_DAY
                           THEN TO_CHAR(vac.END_DAY) -- удаление даты начала, если отпуск длиной один день
                         ELSE vac.START_DAY || '.' || vac.START_MONTH || '-' || vac.END_DAY || '.' ||
                              vac.END_MONTH -- через чёрточку, если дата начала != дате конца
                         END      HOLIDAY
                       FROM V_REP_CITEB_HEADERS_DATES vac
                       ORDER BY vac.FIO, vac.RN_E, vac.START_DAY
                      ) t
                ) tt
              GROUP BY tt.FIO, tt.RN)
              PIVOT (MAX(HOLIDAY)
                FOR RN
                IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12))) h
       JOIN (SELECT
               fvac.FIO,
               SUM(fvac.COUNTER) HOLIDAY
             FROM (SELECT
                     emp.SUMMARY                     FIO,
                     vc.DATE_END - vc.DATE_START + 1 COUNTER
                   FROM V_EMPLOYEES emp
                     JOIN (SELECT DISTINCT
                             v.FIO,
                             v.DATE_START,
                             v.DATE_END
                           FROM V_VACATIONS_CHANGES v
                           WHERE v.REASON_ID = '13040') vc
                       ON emp.SUMMARY = vc.FIO
                   WHERE vc.DATE_START > TRUNC(TO_DATE('2016-01-01', 'yyyy-mm-dd'))
                         AND vc.DATE_END < TRUNC(TO_DATE('2016-12-31', 'yyyy-mm-dd'))
                   ORDER BY FIO) fvac
             GROUP BY fvac.FIO
            ) i ON i.FIO = h.ФИО) s
  
    JOIN
  
    (SELECT *
     FROM
       (SELECT
          tt.FIO ФИО,
          tt.RN,
          tt.HOLIDAY
        FROM
          (SELECT
             ROWNUM HOLIDAY_ORDER,
             t.FIO,
             t.RN,
             t.HOLIDAY
           FROM (SELECT
                   vac.FIO,
                   -- в ячейку с месяцем окончания отпуска
                   vac.RN_E RN,
                   CASE vac.END_MONTH
                   WHEN vac.START_MONTH
                     THEN NULL -- удаление даты начала, если отпуск длиной один день
                   ELSE vac.START_DAY || '.' || vac.START_MONTH || '-' || vac.END_DAY || '.' ||
                        vac.END_MONTH -- через чёрточку
                   END      HOLIDAY
                 FROM
                   V_REP_CITEB_HEADERS_DATES vac
                ) t
          ) tt
       )
        PIVOT (MAX(HOLIDAY)
          FOR RN
          IN (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12))) e
      ON s.ФИО = e.ФИО
  ORDER BY 1
