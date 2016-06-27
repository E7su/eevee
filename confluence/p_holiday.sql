SELECT
  FIO      "ФИО",
  PASS     "Потрачено",
  PLANN    "В планах",
  SURPLUS  "Осталось",
  EXPECTED "Положено"
FROM TABLE (REP_VACATIONS_COUNT('$year_st', '$year_end', '$dep', '$reg', '$fio'))
