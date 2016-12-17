-- Author:            Polina Azarova
-- Date of creation:  28.08.2016
-- Description:       V_REP_DEVOPS_METRICS -> REP_DEVOPS_TASKS_METRICS ->
--                    -> REP_DEVOPS_TASKS_DURATION -> REP_DEVOPS_TASKS

-- третья по вложенности функция, вычисляет метрики
CREATE OR REPLACE TYPE DEVOPS_TASKS_METRICS_TY IS OBJECT (PKEY       VARCHAR2(255), TYPE VARCHAR2(255),
                                                          SUMMARY    VARCHAR2(255), ISSUEID VARCHAR2(255),
                                                          START_DATE DATE, END_DATE DATE, DURATION NUMBER,
                                                          STAT       VARCHAR2(255), VALUE NUMBER, COUNTER NUMBER);
CREATE OR REPLACE TYPE DEVOPS_TASKS_METRICS_TBL_TY IS TABLE OF DEVOPS_TASKS_METRICS_TY;

CREATE OR REPLACE FUNCTION REP_DEVOPS_TASKS_METRICS(p_day NUMBER, p_end_day NUMBER, p_overall VARCHAR2)
  RETURN DEVOPS_TASKS_METRICS_TBL_TY
PIPELINED
IS
  CURSOR cur (c_day NUMBER, c_end_day NUMBER, c_overall VARCHAR2)
  IS
    -- Среднее
    SELECT
      v.PKEY,
      v.TYPE,
      v.SUMMARY,
      v.ISSUEID,
      v.START_DATE,
      v.END_DATE,
      v.DURATION,
      v.STAT,
      v.VALUE,
      dtd.COUNTER
    FROM
      -- количество записей, для вычисления метрик в eazyBI (так как он суммирует их значения
      --  нужно будет поделить их на counter чтобы получить верное значение)
      (SELECT COUNT(ISSUEID) COUNTER, td.PKEY, td.TYPE
       FROM TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_overall)) td
       GROUP BY td.PKEY, td.TYPE
      ) dtd
      JOIN
      (SELECT td.*, vv.STAT, vv.VALUE FROM

        -- Среднее арифметическое
        (SELECT
           'AVERAGE'                               STAT,
           -- в eazyBI будет среднее:  avg = sum / counter
           dtd.PKEY,
           dtd.TYPE,
           SUM(dtd.DURATION) / COUNT(dtd.DURATION) VALUE
         FROM
           (TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_overall))) dtd
         GROUP BY dtd.PKEY, dtd.TYPE

         UNION ALL

         -- Медиана
         SELECT
           'MEDIANA'   STAT,
           rn.PKEY,
           rn.TYPE,
           rn.DURATION VALUE
         -- значение длительности, находящейся в середине списка
         FROM
           (SELECT
              -- находит середину в списке длительностей
              ROUND(COUNT(dtd.DURATION) / 2) - 1 RN,
              dtd.PKEY,
              dtd.TYPE
            FROM
              (TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_overall))) dtd
            GROUP BY dtd.PKEY, dtd.TYPE
           ) ct
           JOIN (SELECT
                   ROW_NUMBER() OVER (ORDER BY dtd.PKEY, dtd.TYPE) -
                   RANK() OVER (ORDER BY dtd.PKEY, dtd.TYPE) RN,
                   dtd.PKEY,
                   dtd.TYPE,
                   dtd.DURATION
                 FROM
                   (TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_overall))) dtd
                 ORDER BY dtd.PKEY, dtd.TYPE, dtd.DURATION
                ) rn ON rn.RN = ct.RN AND rn.PKEY = ct.PKEY AND rn.TYPE = ct.TYPE

         UNION ALL

         -- 90ый перцентиль
         SELECT
           'PERCENTILE' STAT,
           rn.PKEY,
           rn.TYPE,
           rn.DURATION  VALUE
         FROM
           -- находит запись, где порядковый номер приблизительно равен 90% длины списка
           (SELECT
              ROUND(COUNT(dtd.DURATION) / 100 * 90) - 1 RN,
              dtd.PKEY,
              dtd.TYPE
            FROM
              (TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_overall))) dtd
            GROUP BY dtd.PKEY, dtd.TYPE
           ) ct
           JOIN (SELECT
                   ROW_NUMBER() OVER (ORDER BY dtd.PKEY, dtd.TYPE) -
                   RANK() OVER (ORDER BY dtd.PKEY, dtd.TYPE) RN,
                   dtd.PKEY,
                   dtd.TYPE,
                   dtd.DURATION
                 FROM
                   (TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_overall))) dtd
                 ORDER BY dtd.PKEY, dtd.TYPE, dtd.DURATION
                ) rn ON rn.RN = ct.RN AND rn.PKEY = ct.PKEY AND rn.TYPE = ct.TYPE) vv
        -- обогащение данными
        JOIN (TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_overall))) td
          ON td.PKEY = vv.PKEY AND td.TYPE = vv.TYPE) v
        ON dtd.PKEY = v.PKEY AND dtd.TYPE = v.TYPE;
  BEGIN
    FOR rec IN cur (p_day, p_end_day, p_overall)
    LOOP
      PIPE ROW (DEVOPS_TASKS_METRICS_TY(rec.PKEY, rec.TYPE, rec.SUMMARY, rec.ISSUEID, rec.START_DATE, rec.END_DATE,
                                        rec.DURATION, rec.STAT, rec.VALUE, rec.COUNTER));
    END LOOP;
    RETURN;
  END;
