alter session set current_schema = humo;

SELECT ACCOUNT                                                                                                                AS "Folyószámla",
  X__INSDATE                                                                                                                  AS "Rögzítés ideje",
  PAYOFF_PERIOD_DATE                                                                                                          AS "Elszámolási nap" ,
  CAST(COST_NAME AS VARCHAR2(40))                                                                                             AS "Megnevezés",
  COST                                                                                                                        AS "Terhelés/jóváírás",
  COMFORT_COST                                                                                                                AS "Kényelmi díj",
  SUM(COST + COMFORT_COST) over (order by PAYOFF_PERIOD_DATE, X__INSDATE, COST + COMFORT_COST DESC range unbounded preceding) AS "Egyenleg",
  REQUEST_ID,
  FINANCIAL_TRANSACTIONS_ID, 
  POS_RESULT,
  ACCOUNT_RECHARGE_ID,
  GROSS_VALUE,
  CORRECTED_RECHARGE,
  CORRECTING_RECHARGE, 
  CORRECTION_REASON
FROM
  (SELECT IAR.ACCOUNT ACCOUNT,
    IAR.X__INSDATE,
    TRUNC(NVL(PE.PAYOFF_PERIOD_DATE, IAR.X__INSDATE)) PAYOFF_PERIOD_DATE,
    SUBSTR(SJT.X__NAME,0,40) COST_NAME,
    -IAR.REQUEST_COST COST,
    -IAR.COMFORT_COST COMFORT_COST,
     iar.x__id REQUEST_ID,
     FT.FINANCIAL_TRANSACTIONS_ID FINANCIAL_TRANSACTIONS_ID, 
     FT.POS_RESULT,
     AR.ACCOUNT_RECHARGE_ID ACCOUNT_RECHARGE_ID,
     AR.GROSS_VALUE, 
     AR.CORRECTED_RECHARGE,
     AR.CORRECTING_RECHARGE, 
     AR.CORRECTION_REASON
  FROM INCOMING_ACCOUNT_REQUEST IAR,
    SERVICE_JOB_TYPE SJT,
    PAYOFF_ELEM PE,
    FINANCIAL_TRANSACTIONS FT, 
    ACCOUNT_RECHARGE AR,
    ACCOUNT_RECHARGE_TYPE ART
  WHERE IAR.REQUEST_TYPE = SJT.X__ID
  AND IAR.X__ID          = PE.OBJECT_ID (+)
  AND (PE.OBJECT_TABLE   = 'R')
  AND IAR.X__ID          = FT.REQUEST_ID (+)
  AND FT.RECHARGE        = AR.ACCOUNT_RECHARGE_ID (+)
  AND IAR.ACCOUNT        = '2209765'
  AND AR.RECHARGE_TYPE   = ART.X__ID (+)
  UNION ALL
  SELECT OJ.ACCOUNT ACCOUNT,
    OJ.X__INSDATE,
    TRUNC(NVL(PE.PAYOFF_PERIOD_DATE, OJ.X__INSDATE)) PAYOFF_PERIOD_DATE,
    SUBSTR(SJT.X__NAME,0,40) COST_NAME,
    -OJ.OUTPUT_COST COST,
    0 COMFORT_COST,
    oj.x__id REQUEST_ID,
    null FINANCIAL_TRANSACTIONS_ID, 
    null POS_RESULT,
    null ACCOUNT_RECHARGE_ID,
    null GROSS_VALUE,
    null CORRECTED_RECHARGE,
    null CORRECTING_RECHARGE, 
    null CORRECTION_REASON
  FROM OUTPUT_JOB OJ,
    SERVICE_JOB_TYPE SJT,
    PAYOFF_ELEM PE
  WHERE OJ.JOB_TYPE    = SJT.X__ID
  AND OJ.X__ID         = PE.OBJECT_ID (+)
  AND (PE.OBJECT_TABLE = 'O')
  AND OJ.ACCOUNT       = '2209765'
 UNION ALL
  SELECT AR.ACCOUNT ACCOUNT,
    AR.X__INSDATE,
    TRUNC(AR.X__INSDATE) PAYOFF_PERIOD_DATE,
    SUBSTR(ART.X__NAME,0,40) COST_NAME,
    AR.GROSS_VALUE COST,
    0 COMFORT_COST,
    null REQUEST_ID,
    null FINANCIAL_TRANSACTIONS_ID, 
    null POS_RESULT,
    AR.ACCOUNT_RECHARGE_ID ACCOUNT_RECHARGE_ID,
    AR.GROSS_VALUE GROSS_VALUE,
    AR.CORRECTED_RECHARGE,
    AR.CORRECTING_RECHARGE, 
    AR.CORRECTION_REASON
  FROM ACCOUNT_RECHARGE AR,
       ACCOUNT_RECHARGE_TYPE ART
  WHERE AR.RECHARGE_TYPE = ART.X__ID
  AND AR.ACCOUNT         = '2209765'
 UNION ALL
  SELECT AOC.ACCOUNT ACCOUNT,
    AOC.X__INSDATE,
    TRUNC(NVL(PE.PAYOFF_PERIOD_DATE, AOC.X__INSDATE)) PAYOFF_PERIOD_DATE,
    SUBSTR(AOCT.X__NAME,0,40) COST_NAME,
    AOC.COST COST,
    0 COMFORT_COST,
    null REQUEST_ID,
    null FINANCIAL_TRANSACTIONS_ID, 
    null POS_RESULT,
    null ACCOUNT_RECHARGE_ID,
    null GROSS_VALUE, 
    null CORRECTED_RECHARGE,
    null CORRECTING_RECHARGE, 
    null CORRECTION_REASON
  FROM ACCOUNT_OTHER_COST AOC,
    ACCOUNT_OTHER_COST_TYPE AOCT,
    PAYOFF_ELEM PE
  WHERE AOC.COST_TYPE  = AOCT.X__ID
  AND AOC.X__ID        = PE.OBJECT_ID (+)
  AND (PE.OBJECT_TABLE = 'A')
  AND AOC.ACCOUNT      = '2209765'
 )
 WHERE COST <> 0 or comfort_cost <> 0 or gross_value is not null
 
ORDER BY ACCOUNT,
  PAYOFF_PERIOD_DATE,
  X__INSDATE 