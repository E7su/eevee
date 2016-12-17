-- Author:            Polina Azarova
-- Date of creation:  28.08.2016
-- Description:       V_REP_DEVOPS_METRICS -> REP_DEVOPS_TASKS_METRICS ->
--                    -> REP_DEVOPS_TASKS_DURATION -> REP_DEVOPS_TASKS

-- предпоследняя по вложенности функция, считает длительность выполнения задачи в рабочих днях
CREATE OR REPLACE TYPE DEVOPS_TASKS_DURATION_TY IS OBJECT (PKEY       VARCHAR2(255), TYPE VARCHAR2(255),
                                                           SUMMARY    VARCHAR2(255), ISSUEID VARCHAR2(255),
                                                           START_DATE DATE, END_DATE DATE, DURATION NUMBER);
CREATE OR REPLACE TYPE DEVOPS_TASKS_DURATION_TBL_TY IS TABLE OF DEVOPS_TASKS_DURATION_TY;

CREATE OR REPLACE FUNCTION REP_DEVOPS_TASKS_DURATION(p_day NUMBER, p_end_day NUMBER, p_overall VARCHAR2)
  RETURN DEVOPS_TASKS_DURATION_TBL_TY
PIPELINED
IS
  CURSOR cur (c_day NUMBER, c_end_day NUMBER, c_overall VARCHAR2)
  IS
    SELECT
      v.PKEY,
      v.TYPE,
      v.SUMMARY,
      v.ISSUEID,
      v.START_DATE,
      v.END_DATE,
      v.DURATION
    FROM
      (
        SELECT
          -- если NULL, идёт обычная группировка по проектам
          -- если не NULL, название проекта перезасывается как 'OVERALL', считается общая статистика
          NVL(c_overall, dt.PKEY) PKEY,
          dt.TYPE,
          dt.SUMMARY,
          dt.ISSUEID,
          dt.START_DATE,
          dt.END_DATE,

          -- из длительности выполнения задачи вычитаем выходные и праздники
          CASE
          WHEN dt.TYPE = 'User Story'
            THEN
              -- календарная длительность - количество выходных
              dt.END_DATE - dt.START_DATE - (COUNT(dt.WORK_DATE) - SUM(dt.DAY_IS_WORKING))

          WHEN dt.TYPE = 'DevOps Task' AND dt.START_DATE != dt.END_DATE AND TRUNC(dt.END_DATE) - TRUNC(dt.START_DATE) < 2 -- отсечение задач, идущих более 2 дней
            THEN
              -- из часов 24 часов в сутках вычесть 15 часов ночи, количество ночей = округление разности дат
              dt.END_DATE - dt.START_DATE - (COUNT(dt.WORK_DATE) - SUM(dt.DAY_IS_WORKING)) -
              (TRUNC(dt.END_DATE) - TRUNC(dt.START_DATE) - (COUNT(dt.WORK_DATE) - SUM(dt.DAY_IS_WORKING))) * 16 / 24

          WHEN dt.TYPE = 'DevOps Task' AND dt.START_DATE = dt.END_DATE
            THEN
              -- если, в результат округления, совпали даты начала и окончания, считаем длину задачи = 2ч.
              2 / 24
          ELSE
            0
          END                     DURATION
        FROM
          (SELECT * FROM TABLE (REP_DEVOPS_TASKS(c_day, c_end_day))) dt
        GROUP BY
          dt.PKEY,
          dt.TYPE,
          dt.SUMMARY,
          dt.ISSUEID,
          dt.START_DATE,
          dt.END_DATE
      ) v
    WHERE v.DURATION != 0;
  BEGIN
    FOR rec IN cur (p_day, p_end_day, p_overall)
    LOOP
      PIPE ROW (DEVOPS_TASKS_DURATION_TY(rec.PKEY, rec.TYPE, rec.SUMMARY, rec.ISSUEID, rec.START_DATE, rec.END_DATE,
                                         rec.DURATION));
    END LOOP;
    RETURN;
  END;
