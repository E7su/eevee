-- Author:            Polina Azarova
-- Date of creation:  30.08.2016
-- Description:       Report of registered devices

CREATE OR REPLACE VIEW JIRA_READER.V_REP_DEVICES AS
  SELECT
    e.EMPLOYEE       EMPLOYEE,
    dc.TYPE          TYPE,
    dc.DESCRIPTION   DESCRIPTION,
    dc.SERIAL_NUMBER SERIAL_NUMBER,
    dc.ISSUENUM      ISSUENUM,
    dc.MEMORY        MEMORY,
    dc.HAS_SSD       HAS_SSD,
    dc.IS_SELF       IS_SELF,
    dm.MONITOR_TYPE  MONITOR_TYPE,
    dm.DESCRIPTION   MONITOR_DESCRIPTION,
    dm.SERIAL_NUMBER MONITOR_SERIAL_NUMBER,
    dm.ISSUENUM      MONITOR_ISSUENUM
  FROM
    (
      SELECT
        d.ISSUENUM,
        d.EMPLOYEE_LOGIN,
        NVL(d.COMPUTER_TYPE, d.NOTEBOOK_TYPE) TYPE,
        d.DESCRIPTION,
        d.SERIAL_NUMBER,
        d.MEMORY,
        d.HAS_SSD,
        d.IS_SELF,
        -- поле ID компьютера/ноутбука для соединения с ID монитора
        -- ID компьютера всегда >= 10, ID ноутбука всегда < 10 (поэтому ноутбуки выводятся первыми)
        -- идёт сортировка по всем устройствам сотрудника, в зависимости от их ID
        -- изначально ID устанавливается и редактируется в админке JIRA в списке значении custom fields
        ROW_NUMBER() OVER (ORDER BY d.EMPLOYEE_LOGIN, NVL(d.COMPUTER_TYPE_SEQ + 10, 0) + NVL(d.NOTEBOOK_TYPE_SEQ, 0)) -
        RANK() OVER (ORDER BY d.EMPLOYEE_LOGIN) NUM
      FROM JIRA_READER.V_DEVICES d
      WHERE d.DEVICE_TYPE IN (12102, 12101) --('Device Computer', 'Device Notebook')
    ) dc
    FULL OUTER JOIN
    (
      SELECT
        d.ISSUENUM,
        d.EMPLOYEE_LOGIN,
        d.MONITOR_TYPE,
        d.DESCRIPTION,
        d.SERIAL_NUMBER,
        d.MONITOR_TYPE_SEQ,
        -- поле ID монитора для соединения с ID компьютера/ноутбука
        ROW_NUMBER() OVER (ORDER BY d.EMPLOYEE_LOGIN, d.MONITOR_TYPE_SEQ) -
        RANK() OVER (ORDER BY d.EMPLOYEE_LOGIN) NUM
      FROM JIRA_READER.V_DEVICES d
      WHERE d.DEVICE_TYPE = 12103 --'Device Monitor'
    ) dm ON (dm.EMPLOYEE_LOGIN = dc.EMPLOYEE_LOGIN AND dm.NUM = dc.NUM)
    LEFT JOIN JIRA_READER.V_EMPLOYEES e ON (e.LOGIN = dm.EMPLOYEE_LOGIN);

/*
SELECT
  rd.EMPLOYEE "Сотрудник",
  '<a href="http://jiraft.regions.alfaintra.net/browse/DEVICE-' || rd.ISSUENUM || '">' || rd.TYPE || '</a>' "Компьютер",
  rd.MEMORY "Память",
  rd.HAS_SSD "SSD?",
  rd.IS_SELF "Личный?",
  rd.SERIAL_NUMBER "Серийный номер",
  rd.DESCRIPTION "Комментарий",
  '<a href="http://jiraft.regions.alfaintra.net/browse/DEVICE-' || rd.MONITOR_ISSUENUM || '">' || rd.MONITOR_TYPE || '</a>' "Монитор",
  rd.MONITOR_SERIAL_NUMBER "Серийный номер",
  rd.MONITOR_DESCRIPTION  "Комментарий"
FROM JIRA_READER.V_REP_DEVICES rd
 */
