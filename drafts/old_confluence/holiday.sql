SELECT
  fio_final "ФИО",
  SUM(is_passed) "Потрачено",
  SUM(is_vacation) - SUM(is_passed) "В планах",
  MAX(MAX_VACATIONS) - SUM(is_vacation) "Осталось",
  MAX(MAX_VACATIONS) "Положено"
FROM (
  SELECT
    emp.ФИО fio_final,
    vacation_day,

    -- all planned & passed vacations have 1 in this field
    CASE WHEN vacation_day <= TRUNC(SYSDATE) THEN 1
    ELSE 0 END is_passed,

    -- all planned vacations will have 1 in this field
    CASE WHEN vacation_day IS NOT NULL THEN 1
    ELSE 0 END is_vacation,

    (to_number('$year_end') - to_number('$year_st') + 1) * 28 MAX_VACATIONS

  FROM V_EMPLOYEES_SHORT emp
  LEFT JOIN (
    SELECT DISTINCT
      fio,
      d vacation_day
    FROM V_VACATION_REASONS v
    LEFT JOIN (
      SELECT  TRUNC(to_date('$year_st-01-01', 'yyyy-mm-dd') + rownum - 1) d
      FROM    dual
      CONNECT BY rownum <= TRUNC(to_date('$year_end-12-31', 'yyyy-mm-dd')) - TRUNC(to_date('$year_st-01-01', 'yyyy-mm-dd')) + 1) dd
        ON (dd.d >= TRUNC(v.DATE_START) AND dd.d <= TRUNC(v.DATE_END))
    JOIN jira.jiraISSUE iss ON (
             iss.issuenum = v.issuenum
             AND iss.issuestatus IN (10015, 11507, 11705)) -- Done, Confirmation, Planning


    WHERE v.reason_id = 'Отпуск' ) vac
  ON emp.ФИО = vac.fio

  WHERE ('$fio' IS NULL OR (lower(emp.ФИО) LIKE '%' || lower('$fio') || '%'))
    AND ('$reg' IS NULL OR emp."Оформление" = '$reg')
    AND ('$dep' IS NULL OR emp."Подразделение" = '$dep')
    AND emp."Дата увольнения" is NULL
        or (TRUNC(to_date(emp."Дата увольнения", 'yyyy-mm-dd')) >= TRUNC(to_date('$year_st-01-01', 'yyyy-mm-dd'))))

GROUP BY fio_final
ORDER BY fio_final
