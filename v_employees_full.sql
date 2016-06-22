CREATE OR REPLACE FORCE VIEW "JIRA_READER"."V_EMPLOYEES_FULL"
AS
 SELECT j.SUMMARY "ФИО",
    p.PKEY || '-' || j.ISSUENUM "Ключ",
    usr.ID "Ид пользователя",
    usr.USER_NAME "Логин",
    usr.EMAIL_ADDRESS "e_mail",
    c2.DATEVALUE "Дата приёма",
    ROUND(MONTHS_BETWEEN(NVL(c6.DATEVALUE, CURRENT_DATE), c2.DATEVALUE)/12, 1) "Стаж", --стаж в годах, для уволенных - на дату увольнения, для работающих - на текущую дату
    c6.DATEVALUE "Дата увольнения",
    o.CUSTOMVALUE "Подразделение",
    o2.CUSTOMVALUE "Оформление",
    c5.DATEVALUE "День рождения",
    ROUND(MONTHS_BETWEEN(CURRENT_DATE, c5.DATEVALUE)/12, 1) "Возраст", --возраст в годах
    c7.STRINGVALUE "SAP ID",
    c10.STRINGVALUE "Телефон",
    c11.STRINGVALUE "Ставка",
    o5.CUSTOMVALUE "Важность",
    o3.CUSTOMVALUE "Должность",
    o4.CUSTOMVALUE "Город",
    TO_CHAR(j.DESCRIPTION) "Описание",
    regexp_replace(LISTAGG(l1.LABEL, ',') WITHIN GROUP (ORDER BY l1.LABEL),'([^,]+)(,\1)?+','\1') "Проекты", --regexp удаляет дубли, http://www.sql.ru/forum/1100314/listagg-distinct собирает строку из колонки, см https://oracle-base.com/articles/misc/string-aggregation-techniques#listagg
    regexp_replace(LISTAGG(l2.LABEL, ',') WITHIN GROUP (ORDER BY l2.LABEL),'([^,]+)(,\1)?+','\1') "Навыки", --собирает строку из колонки, см https://oracle-base.com/articles/misc/string-aggregation-techniques#listagg
    regexp_replace(LISTAGG(o6.CUSTOMVALUE, ',') WITHIN GROUP (ORDER BY o6.CUSTOMVALUE),'([^,]+)(,\1)?+','\1') "Команда", --собирает строку из колонки, см https://oracle-base.com/articles/misc/string-aggregation-techniques#listagg
    CASE j.issuestatus
      WHEN '10809'
      THEN 'Open'
      ELSE 'Close'
    END "Статус"
  FROM jira.JIRAISSUE j
    INNER JOIN jira.PROJECT p ON (j.PROJECT = p.ID)
    LEFT JOIN jira.CUSTOMFIELDVALUE c2 ON (c2.ISSUE = j.ID AND c2.CUSTOMFIELD = 12376) --дата приема на работу
    LEFT JOIN jira.CUSTOMFIELDVALUE c3 ON (c3.ISSUE = j.ID AND c3.CUSTOMFIELD = 12373) -- список подразделений
    LEFT JOIN jira.CUSTOMFIELDOPTION o ON (c3.STRINGVALUE = TO_CHAR(o.ID)) -- непосредственно подразделение
    LEFT JOIN jira.CUSTOMFIELDVALUE c4 ON (c4.ISSUE = j.ID AND c4.CUSTOMFIELD = 12375) -- список возможных оформленеий
    LEFT JOIN jira.CUSTOMFIELDOPTION o2 ON (c4.STRINGVALUE = TO_CHAR(o2.ID)) -- непосредственно оформление
    LEFT JOIN jira.CUSTOMFIELDVALUE c5 ON (c5.ISSUE = j.ID AND c5.CUSTOMFIELD = 12372) --ДР
    LEFT JOIN jira.CUSTOMFIELDVALUE c6 ON (c6.ISSUE = j.ID AND c6.CUSTOMFIELD = 12570) --Дата увольнения
    LEFT JOIN jira.CUSTOMFIELDVALUE c7 ON (c7.ISSUE = j.ID AND c7.CUSTOMFIELD = 12470) --ID SAP
    LEFT JOIN jira.CUSTOMFIELDVALUE c8 ON (c8.ISSUE = j.ID AND c8.CUSTOMFIELD = 12374) -- список должностей
    LEFT JOIN jira.CUSTOMFIELDOPTION o3 ON (c8.STRINGVALUE = TO_CHAR(o3.ID)) -- непосредственно должность
    LEFT JOIN jira.CUSTOMFIELDVALUE c9 ON (c9.ISSUE = j.ID AND c9.CUSTOMFIELD = 12377) -- список городов
    LEFT JOIN jira.CUSTOMFIELDOPTION o4 ON (c9.STRINGVALUE = TO_CHAR(o4.ID)) -- непосредственно город
    LEFT JOIN jira.CUSTOMFIELDVALUE c10 ON (c10.ISSUE = j.ID AND c10.CUSTOMFIELD = 12471) --телефон
    LEFT JOIN jira.CUSTOMFIELDVALUE c11 ON (c11.ISSUE = j.ID AND c11.CUSTOMFIELD = 12581) --ставка
    LEFT JOIN jira.CUSTOMFIELDVALUE c12 ON (c12.ISSUE = j.ID AND c12.CUSTOMFIELD = 12771) --список важностей
    LEFT JOIN jira.CUSTOMFIELDOPTION o5 ON (c12.STRINGVALUE = TO_CHAR(o5.ID)) -- непосредственно важность
    LEFT JOIN jira.LABEL l1 ON (l1.ISSUE = j.ID AND l1.FIELDID = 12472) --список проектов
    LEFT JOIN jira.LABEL l2 ON (l2.ISSUE = j.ID AND l2.FIELDID = 12380) --список навыков
    LEFT JOIN jira.CUSTOMFIELDVALUE c13 ON (c13.ISSUE = j.ID AND c13.CUSTOMFIELD = 13173) -- список команд
    LEFT JOIN jira.CUSTOMFIELDOPTION o6 ON (c13.STRINGVALUE = TO_CHAR(o6.ID)) -- непосредственно команда
    LEFT JOIN
      (SELECT u2.ID,
        u2.USER_NAME,
        u2.EMAIL_ADDRESS,
        u2.LOWER_DISPLAY_NAME
      FROM --нужно для удаления дубликатов записей, см например по Саевскому
        (SELECT MAX(u.id) id,
          u.LOWER_DISPLAY_NAME
        FROM jira.CWD_USER u
        WHERE u.ACTIVE = 1
        GROUP BY u.LOWER_DISPLAY_NAME
        ) u1 INNER JOIN jira.CWD_USER u2 ON (u1.ID = u2.ID) --where u2.LOWER_DISPLAY_NAME = lower('Magneto')
      ) usr ON (usr.LOWER_DISPLAY_NAME = lower(j.SUMMARY)) --для получения логина/email пользователя
  WHERE p.PKEY                       = 'EMP'
  GROUP BY --группировка нужна для того, чтобы получить список проектов и навыков в виде строк
    j.SUMMARY,
    p.PKEY || '-' || j.ISSUENUM,
    usr.ID,
    usr.USER_NAME,
    usr.EMAIL_ADDRESS,
    c2.DATEVALUE,
    ROUND(MONTHS_BETWEEN(CURRENT_DATE, c2.DATEVALUE)/12, 1),
    c6.DATEVALUE,
    o.CUSTOMVALUE,
    o2.CUSTOMVALUE,
    c5.DATEVALUE,
    ROUND(MONTHS_BETWEEN(CURRENT_DATE, c5.DATEVALUE)/12, 1),
    c7.STRINGVALUE,
    c10.STRINGVALUE,
    c11.STRINGVALUE,
    o5.CUSTOMVALUE, --"Важность",
    o3.CUSTOMVALUE,
    o3.CUSTOMVALUE,
    o4.CUSTOMVALUE,
    TO_CHAR(j.DESCRIPTION),
    CASE j.issuestatus
      WHEN '10809'
      THEN 'Open'
      ELSE 'Close'
    END;
