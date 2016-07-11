CREATE OR REPLACE TYPE VACATION_TY IS OBJECT (FIO VARCHAR2(255), reason VARCHAR2(255), rn INTEGER);
CREATE OR REPLACE TYPE VACATION_TBL_TY IS TABLE OF VACATION_TY;

CREATE OR REPLACE FUNCTION REP_VACATIONS(p_year_st VARCHAR2, p_month_st VARCHAR2, p_fio VARCHAR2, p_proj VARCHAR2,
                                         p_reg     VARCHAR2, p_dep VARCHAR2)
  RETURN VACATION_TBL_TY
PIPELINED
IS
  CURSOR cur (c_year_st VARCHAR2, c_month_st VARCHAR2, c_fio VARCHAR2, c_proj VARCHAR2, c_reg VARCHAR2, c_dep VARCHAR2)
  IS
    SELECT
      t.FIO,
      -- РЅРѕРјРµСЂ РґРЅСЏ РјРµСЃСЏС†Р°
      t.RN,
      -- РѕС‚РѕР±СЂР°Р¶РµРЅРёРµ РїСЂРёС‡РёРЅС‹ РІ confluence html (С†РІРµС‚ СЃС‚РёРєРµСЂР°/С„РѕРЅР° СЏС‡РµР№РєРё)
      -- РµСЃР»Рё РЅРµС‚ РїСЂРёС‡РёРЅС‹ РѕС‚СЃСѓС‚СЃС‚РІРёСЏ, С‚Рѕ РїСЂРѕРІРµСЂСЏРµРј, РЅРµ РІС‹С…РѕРґРЅРѕР№ Р»Рё СЌС‚Рѕ
      coalesce(t.REASON, t.HOLIDAY) REASON
    FROM
      (SELECT
         f.FIO,
         f.RN,
         -- С‚СЂРёРіРіРµСЂ РѕС‚СЃСѓС‚СЃС‚РІРёР№ (РѕС‚РїСѓСЃРє/РѕС‚РіСѓР»... 1, СЂР°Р±РѕС‚Р° РёР· РґРѕРјР° 0)
         f.REASON,
         f.IS_WORK_DAY,
         CASE WHEN IS_WORK_DAY = '0' -- РµСЃР»Рё РІС‹С…РѕРґРЅРѕР№
           THEN '<tr style="background-color:grey">' -- С‚Рѕ СЏС‡РµР№РєР° СЃРµСЂР°СЏ
         END HOLIDAY
       FROM
         (SELECT
            iwd.FIO,
            iwd.RN,
            vr.REASON,
            iwd.IS_WORK_DAY
          FROM
            (SELECT DISTINCT
               dat.FIO,
               -- РґРµРЅСЊ РјРµСЃСЏС†Р°
               extract(DAY
                       FROM dat.dat) RN,
               dat.IS_WORK_DAY
             FROM
               (SELECT
                  v.SUMMARY            FIO,
                  -- РѕР±РѕРіР°С‰РµРЅРёРµ С„СѓРЅРєС†РёРµР№ СЃ РґР°С‚Р°РјРё РІС‹С…РѕРґРЅС‹С… Рё Р±СѓРґРЅРёС… РґРЅРµР№
                  IS_WORKING_DAY(dd.d) IS_WORK_DAY,
                  dd.d                 dat
                FROM V_EMPLOYEES v
                  JOIN V_EMPLOYEES_FULL emp ON (emp."Р¤РРћ" = v.SUMMARY
                                                AND (c_fio IS NULL
                                                     OR REGEXP_LIKE(lower(emp."Р¤РРћ"), lower(c_fio)))
                                                AND (c_proj IS NULL
                                                     OR (REGEXP_LIKE(emp."РџСЂРѕРµРєС‚С‹", c_proj)))
                                                -- REGEXP_LIKE РёС‰РµС‚ РІС…РѕР¶РґРµРЅРёРµ РїРѕРґСЃС‚СЂРѕРєРё РІ СЃС‚СЂРѕРєСѓ
                                                AND (c_reg IS NULL
                                                     OR emp."РћС„РѕСЂРјР»РµРЅРёРµ" = c_reg)
                                                AND (c_dep IS NULL
                                                     OR emp."РџРѕРґСЂР°Р·РґРµР»РµРЅРёРµ" = c_dep)
                    )
                  JOIN
                  (SELECT TRUNC(to_date(c_year_st || '-' || c_month_st || '-01', 'yyyy-mm-dd') + rownum - 1) d
                   FROM dual
                   CONNECT BY rownum <=
                              CAST(to_char(LAST_DAY(to_date(c_year_st || '-' || c_month_st || '-01', 'yyyy-mm-dd')), 'dd') AS
                                   INT)) dd ON 1 = 1 -- РјРЅРѕР¶РёРј РґР°С‚С‹ РЅР° РІСЃРµС… СЃРѕС‚СЂСѓРґРЅРёРєРѕРІ
               ) dat
            ) iwd
            LEFT JOIN (SELECT
                         dat.FIO,
                         -- РґРµРЅСЊ РјРµСЃСЏС†Р°
                         extract(DAY
                                 FROM dat.STARTDATE) RN,
                         REASON -- РїСЂРёС‡РёРЅР° РѕС‚СЃСѓС‚СЃС‚РІРёСЏ
                       FROM
                         (SELECT
                            v.FIO,
                            dd.d AS                              STARTDATE,
                            v.REASON_ID,
                            '<span style="background-color:' || CASE v.REASON_ID
                                                                WHEN '13040'
                                                                  THEN 'GreenYellow' -- РћС‚РїСѓСЃРє
                                                                WHEN '13041'
                                                                  THEN 'blue' -- РћС‚РіСѓР»
                                                                WHEN '13042'
                                                                  THEN 'red' -- Р‘РѕР»РµР·РЅСЊ
                                                                WHEN '13043'
                                                                  THEN 'grey' -- Р Р°Р±РѕС‚Р° РёР· РґРѕРјР°
                                                                WHEN '13044'
                                                                  THEN 'cyan' -- РљРѕРјР°РЅРґРёСЂРѕРІРєР°
                                                                WHEN '13045'
                                                                  THEN 'cyan' -- РћР±СѓС‡РµРЅРёРµ
                                                                WHEN '13046'
                                                                  THEN 'cyan' -- РљРѕРЅС„РµСЂРµРЅС†РёСЏ
                                                                ELSE 'Medium'
                                                                END || '"/>' || '<a href="http://jira/browse/VAC-' ||
                            v.ISSUENUM || '">' || '__' || '</a>' REASON,
                            v.ISSUENUM
                          FROM V_VACATIONS_CHANGES v
                            LEFT JOIN
                            (SELECT TRUNC(to_date(c_year_st || '-' || c_month_st || '-01', 'yyyy-mm-dd') + rownum - 1) d
                             FROM dual
                             CONNECT BY rownum <=
                                        CAST(to_char(LAST_DAY(to_date(c_year_st || c_month_st || '01' || '-01', 'yyyy-mm-dd')),
                                                     'dd')
                                             AS
                                             INT)) dd
                              ON (dd.d >= TRUNC(v.DATE_START)
                                  AND dd.d <= TRUNC(v.DATE_END))) dat
                      ) vr
              ON vr.FIO = iwd.FIO AND vr.RN = iwd.RN) f
       ORDER BY 1, 2) t;

  BEGIN
    FOR rec IN cur (p_year_st, p_month_st, p_fio, p_proj, p_reg, p_dep)
    LOOP
      PIPE ROW (VACATION_TY(rec.FIO, rec.REASON, rec.RN));
    END LOOP;
    RETURN;
  END;
