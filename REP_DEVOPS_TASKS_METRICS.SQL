-- Author:            Polina Azarova
-- Date of creation:  28.08.2016
-- Description:       V_REP_DEVOPS_METRICS -> REP_DEVOPS_TASKS_METRICS_D -> REP_DEVOPS_TASKS_METRICS ->
--                    -> REP_DEVOPS_TASKS_DURATION -> REP_DEVOPS_TASKS

-- третья по вложенности функция, вычисляет метрики
CREATE OR REPLACE TYPE DEVOPS_TASKS_METRICS_TY IS OBJECT (PKEY       VARCHAR2(255), TYPE VARCHAR2(255),
                                                          SUMMARY    VARCHAR2(255), ISSUEID VARCHAR2(255),
                                                          START_DATE DATE, END_DATE DATE, DURATION NUMBER,
                                                          STAT       VARCHAR2(255), VALUE NUMBER, COUNTER NUMBER);
CREATE OR REPLACE TYPE DEVOPS_TASKS_METRICS_TBL_TY IS TABLE OF DEVOPS_TASKS_METRICS_TY;

CREATE OR REPLACE FUNCTION REP_DEVOPS_TASKS_METRICS(p_day NUMBER, p_end_day NUMBER, p_type VARCHAR2, p_st VARCHAR2,
                                                    p_end VARCHAR2)
  RETURN DEVOPS_TASKS_METRICS_TBL_TY
PIPELINED
IS
  CURSOR cur (c_day NUMBER, c_end_day NUMBER, c_type VARCHAR2, c_st VARCHAR2, c_end VARCHAR2)
  IS
    -- Среднее
    SELECT *
    FROM
      -- количество записей, для вычисления метрик в eazyBI (так как он суммирует их значения
      --  нужно будет поделить их на counter чтобы получить верное значение)
      (SELECT COUNT(ISSUEID) COUNTER
       FROM TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_type, c_st, c_end)) td
      ) dtd
      JOIN
      ((SELECT
          'AVERAGE'         STAT,
          -- в eazyBI будет среднее:  avg = sum / counter
          SUM(dtd.DURATION) VALUE
        FROM
          (SELECT *
           FROM TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_type, c_st, c_end))) dtd
        UNION ALL

        -- Медиана
        SELECT
          'MEDIANA'   STAT,
          rn.DURATION VALUE
        -- значение длительности, находящейся в середине списка
        FROM
          (SELECT
             -- находит середину в списке длительностей
             ROUND(COUNT(dtd.DURATION) / 2) RN
           FROM
             (SELECT *
              FROM TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_type, c_st, c_end))) dtd
          ) ct
          JOIN (SELECT
                  ROWNUM RN,
                  dtd.DURATION
                FROM
                  (SELECT *
                   FROM TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_type, c_st, c_end))) dtd
               ) rn ON rn.RN = ct.RN
        GROUP BY rn.DURATION
        UNION ALL

        -- 90ый перцентиль
        SELECT
          'PERCENTILE' STAT,
          rn.DURATION  VALUE
        FROM
          -- находит запись, где порядковый номер приблизительно равен 90% длины списка
          (SELECT ROUND(COUNT(dtd.DURATION) / 100 * 90) COUNTER
           FROM
             (SELECT *
              FROM TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_type, c_st, c_end))) dtd
          ) ct
          JOIN (SELECT
                  ROWNUM RN,
                  dtd.DURATION
                FROM
                  (SELECT DURATION
                   FROM TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_type, c_st, c_end))) dtd
               ) rn ON rn.RN = ct.COUNTER
        GROUP BY rn.DURATION)
        -- обогащение данными
        JOIN (SELECT td.*
              FROM TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_type, c_st, c_end)) td
      ) ON 1 = 1)
        ON 1 = 1;

  BEGIN
    FOR rec IN cur (p_day, p_end_day, p_type, p_st, p_end)
    LOOP
      PIPE ROW (DEVOPS_TASKS_METRICS_TY(rec.PKEY, rec.TYPE, rec.SUMMARY, rec.ISSUEID, rec.START_DATE, rec.END_DATE,
                                        rec.DURATION, rec.STAT, rec.VALUE, rec.COUNTER));
    END LOOP;
    RETURN;
  END;
