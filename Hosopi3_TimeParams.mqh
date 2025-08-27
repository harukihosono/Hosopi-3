//+------------------------------------------------------------------+
//|                  Hosopi 3 - 時間設定パラメータファイル             |
//|                              Copyright 2025                      |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property link      ""
#property strict

//+------------------------------------------------------------------+
//|                      時間制御パラメータ定義                        |
//+------------------------------------------------------------------+

// ======== 共通時間設定 ========
sinput string Comment_Common_Time = ""; //+--- 共通時間設定 ---+
input ON_OFF DayTimeControl_Active = ON_MODE; // 共通時間設定を有効にする(ON/OFF)
input int buy_StartHour = 0;             // Buy取引開始時刻-時(日本時間)
input int buy_StartMinute = 0;           // Buy取引開始時刻-分(日本時間)
input int buy_EndHour = 24;              // Buy取引終了時刻-時(日本時間)
input int buy_EndMinute = 0;             // Buy取引終了時刻-分(日本時間)
input int sell_StartHour = 0;            // Sell取引開始時刻-時(日本時間)
input int sell_StartMinute = 00;         // Sell取引開始時刻-分(日本時間)
input int sell_EndHour = 24;             // Sell取引終了時刻-時(日本時間)
input int sell_EndMinute = 0;            // Sell取引終了時刻-分(日本時間)

// ======== 日曜日の時間設定 ========
sinput string Comment_Sunday_Time = ""; //+--- 日曜日の時間設定 ---+
input ON_OFF Sunday_Enable = ON_MODE;      // 日曜日を有効にする
input int Sunday_Buy_StartHour = 0;        // 日曜日Buy開始時刻-時
input int Sunday_Buy_StartMinute = 0;      // 日曜日Buy開始時刻-分
input int Sunday_Buy_EndHour = 24;         // 日曜日Buy終了時刻-時
input int Sunday_Buy_EndMinute = 0;        // 日曜日Buy終了時刻-分
input int Sunday_Sell_StartHour = 0;       // 日曜日Sell開始時刻-時
input int Sunday_Sell_StartMinute = 0;     // 日曜日Sell開始時刻-分
input int Sunday_Sell_EndHour = 24;        // 日曜日Sell終了時刻-時
input int Sunday_Sell_EndMinute = 0;       // 日曜日Sell終了時刻-分

// ======== 月曜日の時間設定 ========
sinput string Comment_Monday_Time = ""; //+--- 月曜日の時間設定 ---+
input ON_OFF Monday_Enable = ON_MODE;      // 月曜日を有効にする
input int Monday_Buy_StartHour = 0;        // 月曜日Buy開始時刻-時
input int Monday_Buy_StartMinute = 0;      // 月曜日Buy開始時刻-分
input int Monday_Buy_EndHour = 24;         // 月曜日Buy終了時刻-時
input int Monday_Buy_EndMinute = 0;        // 月曜日Buy終了時刻-分
input int Monday_Sell_StartHour = 0;       // 月曜日Sell開始時刻-時
input int Monday_Sell_StartMinute = 0;     // 月曜日Sell開始時刻-分
input int Monday_Sell_EndHour = 24;        // 月曜日Sell終了時刻-時
input int Monday_Sell_EndMinute = 0;       // 月曜日Sell終了時刻-分

// ======== 火曜日の時間設定 ========
sinput string Comment_Tuesday_Time = ""; //+--- 火曜日の時間設定 ---+
input ON_OFF Tuesday_Enable = ON_MODE;     // 火曜日を有効にする
input int Tuesday_Buy_StartHour = 0;       // 火曜日Buy開始時刻-時
input int Tuesday_Buy_StartMinute = 0;     // 火曜日Buy開始時刻-分
input int Tuesday_Buy_EndHour = 24;        // 火曜日Buy終了時刻-時
input int Tuesday_Buy_EndMinute = 0;       // 火曜日Buy終了時刻-分
input int Tuesday_Sell_StartHour = 0;      // 火曜日Sell開始時刻-時
input int Tuesday_Sell_StartMinute = 0;    // 火曜日Sell開始時刻-分
input int Tuesday_Sell_EndHour = 24;       // 火曜日Sell終了時刻-時
input int Tuesday_Sell_EndMinute = 0;      // 火曜日Sell終了時刻-分

// ======== 水曜日の時間設定 ========
sinput string Comment_Wednesday_Time = ""; //+--- 水曜日の時間設定 ---+
input ON_OFF Wednesday_Enable = ON_MODE;   // 水曜日を有効にする
input int Wednesday_Buy_StartHour = 0;     // 水曜日Buy開始時刻-時
input int Wednesday_Buy_StartMinute = 0;   // 水曜日Buy開始時刻-分
input int Wednesday_Buy_EndHour = 24;      // 水曜日Buy終了時刻-時
input int Wednesday_Buy_EndMinute = 0;     // 水曜日Buy終了時刻-分
input int Wednesday_Sell_StartHour = 0;    // 水曜日Sell開始時刻-時
input int Wednesday_Sell_StartMinute = 0;  // 水曜日Sell開始時刻-分
input int Wednesday_Sell_EndHour = 24;     // 水曜日Sell終了時刻-時
input int Wednesday_Sell_EndMinute = 0;    // 水曜日Sell終了時刻-分

// ======== 木曜日の時間設定 ========
sinput string Comment_Thursday_Time = ""; //+--- 木曜日の時間設定 ---+
input ON_OFF Thursday_Enable = ON_MODE;    // 木曜日を有効にする
input int Thursday_Buy_StartHour = 0;      // 木曜日Buy開始時刻-時
input int Thursday_Buy_StartMinute = 0;    // 木曜日Buy開始時刻-分
input int Thursday_Buy_EndHour = 24;       // 木曜日Buy終了時刻-時
input int Thursday_Buy_EndMinute = 0;      // 木曜日Buy終了時刻-分
input int Thursday_Sell_StartHour = 0;     // 木曜日Sell開始時刻-時
input int Thursday_Sell_StartMinute = 0;   // 木曜日Sell開始時刻-分
input int Thursday_Sell_EndHour = 24;      // 木曜日Sell終了時刻-時
input int Thursday_Sell_EndMinute = 0;     // 木曜日Sell終了時刻-分

// ======== 金曜日の時間設定 ========
sinput string Comment_Friday_Time = ""; //+--- 金曜日の時間設定 ---+
input ON_OFF Friday_Enable = ON_MODE;      // 金曜日を有効にする
input int Friday_Buy_StartHour = 0;        // 金曜日Buy開始時刻-時
input int Friday_Buy_StartMinute = 0;      // 金曜日Buy開始時刻-分
input int Friday_Buy_EndHour = 24;         // 金曜日Buy終了時刻-時
input int Friday_Buy_EndMinute = 0;        // 金曜日Buy終了時刻-分
input int Friday_Sell_StartHour = 0;       // 金曜日Sell開始時刻-時
input int Friday_Sell_StartMinute = 0;     // 金曜日Sell開始時刻-分
input int Friday_Sell_EndHour = 24;        // 金曜日Sell終了時刻-時
input int Friday_Sell_EndMinute = 0;       // 金曜日Sell終了時刻-分

// ======== 土曜日の時間設定 ========
sinput string Comment_Saturday_Time = ""; //+--- 土曜日の時間設定 ---+
input ON_OFF Saturday_Enable = ON_MODE;    // 土曜日を有効にする
input int Saturday_Buy_StartHour = 0;      // 土曜日Buy開始時刻-時
input int Saturday_Buy_StartMinute = 0;    // 土曜日Buy開始時刻-分
input int Saturday_Buy_EndHour = 24;       // 土曜日Buy終了時刻-時
input int Saturday_Buy_EndMinute = 0;      // 土曜日Buy終了時刻-分
input int Saturday_Sell_StartHour = 0;     // 土曜日Sell開始時刻-時
input int Saturday_Sell_StartMinute = 0;   // 土曜日Sell開始時刻-分
input int Saturday_Sell_EndHour = 24;      // 土曜日Sell終了時刻-時
input int Saturday_Sell_EndMinute = 0;     // 土曜日Sell終了時刻-分

// ======== 奇数偶数時間フィルター設定 ========
sinput string Comment_EvenOdd = ""; //+--- 奇数偶数時間フィルター設定 ---+
input EVEN_ODD_STRATEGY EvenOdd_Entry_Strategy = EVEN_ODD_DISABLED; // 奇数偶数エントリー戦略

// ======== 曜日フィルター設定 ========
sinput string Comment_DayFilter = ""; //+--- 曜日フィルター設定 ---+
input bool EnablePositionByDay = false;         // 曜日フィルターを有効化
input bool AllowSundayPosition = true;          // 日曜日の取引を許可
input bool AllowMondayPosition = true;          // 月曜日の取引を許可
input bool AllowTuesdayPosition = true;         // 火曜日の取引を許可
input bool AllowWednesdayPosition = true;       // 水曜日の取引を許可
input bool AllowThursdayPosition = true;        // 木曜日の取引を許可
input bool AllowFridayPosition = true;          // 金曜日の取引を許可
input bool AllowSaturdayPosition = true;        // 土曜日の取引を許可