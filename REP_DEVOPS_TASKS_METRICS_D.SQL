-- Author:            Polina Azarova
-- Date of creation:  28.08.2016
-- Description:       V_REP_DEVOPS_METRICS -> REP_DEVOPS_TASKS_METRICS_D -> REP_DEVOPS_TASKS_METRICS ->
--                    -> REP_DEVOPS_TASKS_DURATION -> REP_DEVOPS_TASKS

CREATE OR REPLACE TYPE DEVOPS_TASKS_METRICS_D_TY IS OBJECT (DAT  VARCHAR2(255),
                                                            STAT VARCHAR2(255), VALUE NUMBER);
CREATE OR REPLACE TYPE DEVOPS_TASKS_METRICS_D_TBL_TY IS TABLE OF DEVOPS_TASKS_METRICS_D_TY;

CREATE OR REPLACE FUNCTION REP_DEVOPS_TASKS_METRICS_D(p_type VARCHAR2,
                                                      p_st   VARCHAR2,
                                                      p_end  VARCHAR2)
  RETURN DEVOPS_TASKS_METRICS_D_TBL_TY
PIPELINED
IS
  CURSOR cur (c_type VARCHAR2, c_st VARCHAR2, c_end VARCHAR2)
  IS
    -- первые 2 недели
    SELECT
      'Первая половина' DAT,
      f.*
    FROM
      TABLE (REP_DEVOPS_TASKS_METRICS('30', '15', c_type, c_st, c_end)) f -- 'In Progress' -> 'Done'
    UNION ALL
    -- вторые две недели
    SELECT
      'Вторая половина' DAT,
      s.*
    FROM
      TABLE (REP_DEVOPS_TASKS_METRICS('15', '0', c_type, c_st, c_end)) s; -- 'In Progress' -> 'Done'
  BEGIN
    FOR rec IN cur (p_type, p_st, p_end)
    LOOP
      PIPE ROW (DEVOPS_TASKS_METRICS_D_TY(rec.DAT, rec.STAT, rec.VALUE));
    END LOOP;
    RETURN;
  END;
