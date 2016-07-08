-- Author:            Polina Azarova
-- Date of creation:  08.07.2016
-- Description:       A report on the turnover ratio for the selected period in the context of administration,
--                    registration ( state / vendor )

--------------------------------------//14//---------------------------------------
-- Kt // Коэффициент текучести - отношение количества уволенных сотрудников в среднесписочной численности
-- Kt = Ky/CHsr * 100
SELECT round(kt.KY / kt.CHSR * 100, 2) KT
FROM
  -- Ky // Количество уволенных сотрудников за данный период времени
  (SELECT *
   FROM
     (SELECT count(ky."Дата увольнения") KY
      FROM
        (SELECT c6.DATEVALUE "Дата увольнения"
         FROM jira.JIRAISSUE j
           INNER JOIN jira.PROJECT p ON (j.PROJECT = p.ID AND p.PKEY = 'EMP')
           LEFT JOIN jira.CUSTOMFIELDVALUE c3 ON (c3.ISSUE = j.ID AND c3.CUSTOMFIELD = 12373)
           LEFT JOIN jira.CUSTOMFIELDOPTION o ON (c3.STRINGVALUE = TO_CHAR(o.ID))
           -- o.CUSTOMVALUE  "Подразделение",
           LEFT JOIN jira.CUSTOMFIELDVALUE c4 ON (c4.ISSUE = j.ID AND c4.CUSTOMFIELD = 12375)
           -- o2.CUSTOMVALUE "Оформление",
           LEFT JOIN jira.CUSTOMFIELDOPTION o2 ON (c4.STRINGVALUE = TO_CHAR(o2.ID))
           -- Дата увольнения
           LEFT JOIN jira.CUSTOMFIELDVALUE c6 ON (c6.ISSUE = j.ID AND c6.CUSTOMFIELD = 12570)
         WHERE --TODO add parameter
           c6.DATEVALUE >= to_date('2016-04-01', 'yyyy-mm-dd') AND c6.DATEVALUE <= to_date('2016-05-01', 'yyyy-mm-dd')
           AND ('' IS NULL                           --TODO add parameter
                OR o2.CUSTOMVALUE = '')              --TODO add parameter
           AND ('' IS NULL                           --TODO add parameter
                OR o2.CUSTOMVALUE = '')              --TODO add parameter
        ) ky
       )
     JOIN
     -- CHsr // Среднесписочная численность (количество сотрудников на начало месяца + 
     --                                                      + количество сотрудников за следующий месяц, делённые на 2)
     -- CHsr = CHn + CHk
     (SELECT (cnn.CHN + ckk.CHK) / 2 CHSR
      FROM
        -- CHn // Количество сотрудников на начало месяцв (начало периода)
        (SELECT count(cn."Дата увольнения") CHN
         FROM
           (SELECT c6.DATEVALUE "Дата увольнения"
            FROM jira.JIRAISSUE j
              INNER JOIN jira.PROJECT p ON (j.PROJECT = p.ID AND p.PKEY = 'EMP')
              LEFT JOIN jira.CUSTOMFIELDVALUE c3 ON (c3.ISSUE = j.ID AND c3.CUSTOMFIELD = 12373)
              LEFT JOIN jira.CUSTOMFIELDOPTION o ON (c3.STRINGVALUE = TO_CHAR(o.ID))
              -- o.CUSTOMVALUE  "Подразделение",
              LEFT JOIN jira.CUSTOMFIELDVALUE c4 ON (c4.ISSUE = j.ID AND c4.CUSTOMFIELD = 12375)
              -- o2.CUSTOMVALUE "Оформление",
              LEFT JOIN jira.CUSTOMFIELDOPTION o2 ON (c4.STRINGVALUE = TO_CHAR(o2.ID))
              -- Дата увольнения
              LEFT JOIN jira.CUSTOMFIELDVALUE c6 ON (c6.ISSUE = j.ID AND c6.CUSTOMFIELD = 12570)
            WHERE c6.DATEVALUE IS NULL OR c6.DATEVALUE > to_date('2016-04-01', 'yyyy-mm-dd') OR --TODO add parameter
                  c6.DATEVALUE < to_date('2016-04-30', 'yyyy-mm-dd') --TODO add parameter
                  AND ('' IS NULL                           --TODO add parameter
                       OR o2.CUSTOMVALUE = '')              --TODO add parameter
                  AND ('' IS NULL                           --TODO add parameter
                       OR o2.CUSTOMVALUE = '')              --TODO add parameter
           ) cn
        ) cnn
        JOIN
        -- CHk // Количество сотрудников на начало следующего месяца (конец периода)
        (SELECT count(ck."Дата увольнения") CHk
         FROM
           (SELECT c6.DATEVALUE "Дата увольнения"
            FROM jira.JIRAISSUE j
              INNER JOIN jira.PROJECT p ON (j.PROJECT = p.ID AND p.PKEY = 'EMP')
              LEFT JOIN jira.CUSTOMFIELDVALUE c3 ON (c3.ISSUE = j.ID AND c3.CUSTOMFIELD = 12373)
              LEFT JOIN jira.CUSTOMFIELDOPTION o ON (c3.STRINGVALUE = TO_CHAR(o.ID))
              -- o.CUSTOMVALUE  "Подразделение",
              LEFT JOIN jira.CUSTOMFIELDVALUE c4 ON (c4.ISSUE = j.ID AND c4.CUSTOMFIELD = 12375)
              -- o2.CUSTOMVALUE "Оформление",
              LEFT JOIN jira.CUSTOMFIELDOPTION o2 ON (c4.STRINGVALUE = TO_CHAR(o2.ID))
              -- Дата увольнения
              LEFT JOIN jira.CUSTOMFIELDVALUE c6 ON (c6.ISSUE = j.ID AND c6.CUSTOMFIELD = 12570)
            WHERE c6.DATEVALUE IS NULL OR c6.DATEVALUE >= to_date('2016-04-30', 'yyyy-mm-dd') --TODO add parameter
                                          AND ('' IS NULL                           --TODO add parameter
                                               OR o2.CUSTOMVALUE = '')              --TODO add parameter
                                          AND ('' IS NULL                           --TODO add parameter
                                               OR o2.CUSTOMVALUE = '')              --TODO add parameter
           ) ck
        ) ckk
          ON 1 = 1)
       ON 1 = 1) kt
