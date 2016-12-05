-- Author:            Polina Azarova
-- Date of creation:  08.07.2016
-- Description:       A report on the turnover ratio for the selected period in the context of administration,
--                    registration ( state / vendor )

--                    V_REP_TURNOVER_RATIO -> V_REP_DISMISS_COUNT -> REP_DISMISS_COUNT
--                                         -> V_REP_AVG_TURNOVER_RATIO -> REP_AVG_TURNOVER_RATIO

--------------------------------------//14//---------------------------------------
CREATE OR REPLACE VIEW JIRA_READER.V_REP_TURNOVER_RATIO AS
  SELECT
    kt.MONTH,
    kt."Подразделение",
    kt."Оформление",
    ROUND(kt.KY / kt.CHSR * 100, 2)     KT,
    TO_DATE('2015-12-01', 'yyyy-mm-dd') DATE_ST,
    TO_DATE('2016-12-01', 'yyyy-mm-dd') DATE_END
  FROM
    (SELECT
       -- CHsr // Среднесписочная численность (количество сотрудников в декабре +
       --     //  + количество сотрудников в последующие месяцы, делённое на количество месяцев, прошедщих с декабря)
       -- CHsr = CHn/MONTHS_BETWEEN(DEC, REPORT_MONTH)
       ky.*,
       cn.CHSR
     FROM
       (SELECT *
        -- Ky // Количество уволенных сотрудников за данный период времени
        FROM V_REP_DISMISS_COUNT
       ) ky
       JOIN
       (SELECT
          -- CHsr // Среднесписочная численность (количество сотрудников в декабре +
          -- //  + количество сотрудников в последующие месяцы, делённое на количество месяцев, прошедщих с декабря)
          -- CHsr = CHn/MONTHS_BETWEEN(DEC, REPORT_MONTH)
          SUM(tr.CHSR) CHSR,
          tr."Подразделение",
          tr."Оформление"
        FROM V_REP_AVG_TURNOVER_RATIO tr
        WHERE MONTH <= 2 --TODO
        GROUP BY tr."Подразделение", tr."Оформление"
       ) cn
         ON ky."Подразделение" = cn."Подразделение" AND
            ky."Оформление" = cn."Оформление") kt;
