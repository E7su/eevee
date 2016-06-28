CREATE OR REPLACE TYPE VACATION_TY IS OBJECT (FIO VARCHAR2(255), reason VARCHAR2(255), rn INTEGER);
CREATE OR REPLACE TYPE VACATION_TBL_TY IS TABLE OF VACATION_TY;

CREATE OR REPLACE FUNCTION REP_VACATIONS(p_year_st VARCHAR2, p_month_st VARCHAR2, p_fio VARCHAR2, p_proj VARCHAR2, p_reg VARCHAR2, p_dep VARCHAR2)
  RETURN VACATION_TBL_TY
PIPELINED
IS
  CURSOR cur (c_year_st VARCHAR2, c_month_st VARCHAR2, c_fio VARCHAR2, c_proj VARCHAR2, c_reg VARCHAR2, c_dep VARCHAR2)
  IS
    SELECT dat.fio "Ф.И.О.",
           '<span style="background-color:' || CASE dat.REASON_ID
                                               WHEN '13040' THEN 'GreenYellow' -- Отпуск
                                               WHEN '13041' THEN 'blue'        -- Отгул
                                               WHEN '13042' THEN 'red'         -- Болезнь
                                               WHEN '13043' THEN 'grey'        -- Работа из дома
                                               WHEN '13044' THEN 'cyan'        -- Командировка
                                               WHEN '13045' THEN 'cyan'        -- Обучение
                                               WHEN '13046' THEN 'cyan'        -- Конференция
                                               ELSE 'Medium'
                                               END || '"/>' || '<a href="http://jira/browse/VAC-' || dat.issuenum || '">' || '__' || '</a>' reason,
           extract(DAY
                   FROM dat.startdate) rn


    FROM
      (SELECT v.FIO,
         dd.d AS startdate,
         v.REASON_ID,
         v.ISSUENUM,
         emp."ФИО",
         emp."Подразделение",
         emp."Оформление",
         emp."Проекты"
       FROM V_VACATIONS v
         LEFT JOIN
         (SELECT TRUNC(to_date(c_year_st || '-' || c_month_st || '-01', 'yyyy-mm-dd') + rownum - 1) d
          FROM dual CONNECT BY rownum <= CAST(to_char(LAST_DAY(to_date(c_year_st || '-' || '01' || '-01', 'yyyy-mm-dd')),'dd') AS INT)) dd ON (dd.d >= TRUNC(v.DATE_START)
                                                                                                                                               AND dd.d <= TRUNC(v.DATE_END))
         JOIN V_EMPLOYEES_FULL emp ON (emp."ФИО" = v.fio
                                       AND (c_fio IS NULL
                                            OR REGEXP_LIKE (lower(emp."ФИО"), lower(c_fio)))
                                       AND (c_proj  IS NULL
                                            OR (REGEXP_LIKE (emp."Проекты", c_proj )))-- REGEXP_LIKE ищет вхождение подстроки в строку
                                       AND (c_reg IS NULL
                                            OR emp."Оформление" = c_reg)
                                       AND (c_dep IS NULL
                                            OR emp."Подразделение" = c_dep)
           )
         JOIN jira.jiraISSUE
           ON jira.jiraISSUE.issuenum = v.issuenum
       WHERE  jira.jiraISSUE.issuestatus in (10015, 11507, 11705) and jira.jiraISSUE.PROJECT = 12883) dat     -- Done, Confirmation, Planning

    WHERE fio IS NOT NULL
          AND startdate IS NOT NULL;

  BEGIN
    FOR rec IN cur (p_year_st, p_month_st, p_fio, p_proj, p_reg, p_dep)
    LOOP
      PIPE ROW (VACATION_TY(rec."Ф.И.О.", rec.reason, rec.rn));
    END LOOP;
    RETURN;
  END;
