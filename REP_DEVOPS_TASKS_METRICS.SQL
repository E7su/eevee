-- Author:            Polina Azarova
-- Date of creation:  28.08.2016
-- Description:       V_REP_DEVOPS_METRICS -> REP_DEVOPS_TASKS_METRICS_D -> REP_DEVOPS_TASKS_METRICS ->
--                    -> REP_DEVOPS_TASKS_DURATION -> REP_DEVOPS_TASKS

-- третья по вложенности функция, вычисляет метрики
CREATE OR REPLACE TYPE DEVOPS_TASKS_METRICS_TY IS OBJECT (STAT  VARCHAR2(255),
                                                          VALUE VARCHAR2(255));
CREATE OR REPLACE TYPE DEVOPS_TASKS_METRICS_TBL_TY IS TABLE OF DEVOPS_TASKS_METRICS_TY;

CREATE OR REPLACE FUNCTION REP_DEVOPS_TASKS_METRICS(p_day NUMBER, p_end_day NUMBER, p_type VARCHAR2, p_st VARCHAR2,
                                                    p_end VARCHAR2)
  RETURN DEVOPS_TASKS_METRICS_TBL_TY
PIPELINED
IS
  CURSOR cur (c_day NUMBER, c_end_day NUMBER, c_type VARCHAR2, c_st VARCHAR2, c_end VARCHAR2)
  IS
    -- Среднее
    SELECT
      'AVERAGE'        STAT,
      AVG(rt.DURATION) VALUE
    FROM (SELECT *
          FROM
            TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_type, c_st, c_end))) rt
    UNION ALL
    -- Медиана
    SELECT
      'MEDIANA'  STAT,
      f.DURATION VALUE -- значение длительности, находящейся в середине списка
    FROM
      (SELECT ROUND(COUNT(rt.DURATION) / 2) COUNTER -- находит середину в списке длительностей
       FROM (SELECT *
             FROM
               TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_type, c_st, c_end))) rt) t
      JOIN (SELECT
              -- сортирует по возрастанию
              ROWNUM RN,
              DURATION
            FROM
              (SELECT DURATION
               FROM
                 (SELECT *
                  FROM
                    TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_type, c_st, c_end))) rt
               ORDER BY DURATION)
           ) f ON f.RN = t.COUNTER
    UNION ALL
    -- 90ый перцентиль
    SELECT
      'PERCENTILE' STAT,
      f.DURATION   VALUE
    FROM
      -- находит запись, где порядковый номер приблизительно равен 90% длины списка
      (SELECT ROUND(COUNT(rt.DURATION) / 100 * 90) COUNTER
       FROM (SELECT *
             FROM
               TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_type, c_st, c_end))) rt) t
      JOIN (SELECT
              ROWNUM RN,
              DURATION
            FROM
              (SELECT DURATION -- сортирует по возрастанию
               FROM
                 (SELECT *
                  FROM
                    TABLE (REP_DEVOPS_TASKS_DURATION(c_day, c_end_day, c_type, c_st, c_end))) rt
               ORDER BY DURATION)) f ON f.RN = t.COUNTER;
  BEGIN
    FOR rec IN cur (p_day, p_end_day, p_type, p_st, p_end)
    LOOP
      PIPE ROW (DEVOPS_TASKS_METRICS_TY(rec.STAT, rec.VALUE));
    END LOOP;
    RETURN;
  END;
