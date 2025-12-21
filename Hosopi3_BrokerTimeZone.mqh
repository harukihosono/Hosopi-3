//+------------------------------------------------------------------+
//|                                       Hosopi3_BrokerTimeZone.mqh |
//|                   Smart Broker TimeZone Detection System        |
//|                   ブローカー別タイムゾーン自動検出システム        |
//|                   (Gotobi_Ultimate_EAより移植)                   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025"
#property version   "1.00"

//+------------------------------------------------------------------+
//| DST（サマータイム）タイプ                                         |
//+------------------------------------------------------------------+
enum ENUM_DST_TYPE
{
    DST_NONE,       // サマータイムなし（GMT固定）
    DST_US,         // アメリカ式（3月第2日曜〜11月第1日曜）
    DST_EU          // ヨーロッパ式（3月最終日曜〜10月最終日曜）
};

//+------------------------------------------------------------------+
//| 時間取得モード（拡張版）                                          |
//+------------------------------------------------------------------+
enum ENUM_TIME_MODE
{
    TIME_MODE_AUTO,         // 自動検出（推奨）
    TIME_MODE_PC,           // PC時間から計算
    TIME_MODE_MANUAL,       // 手動設定（従来のGMT9_BACKTEST）
    TIME_MODE_GMT0_FIXED    // GMT+0固定（従来のGMT_KOTEI）
};

#ifdef __MQL5__

//+------------------------------------------------------------------+
//| ブローカータイムゾーン情報構造体                                   |
//+------------------------------------------------------------------+
struct BrokerTimeInfo
{
    string keyword;         // ブローカー名のキーワード
    int    gmtOffsetWinter; // 冬時間のGMTオフセット（時間）
    int    gmtOffsetSummer; // 夏時間のGMTオフセット（時間）
    ENUM_DST_TYPE dstType;  // DSTタイプ
};

//+------------------------------------------------------------------+
//| ブローカータイムゾーンマネージャークラス                           |
//+------------------------------------------------------------------+
class CBrokerTimeZone
{
private:
    BrokerTimeInfo m_brokerMappings[];

    // Current state
    string m_brokerName;
    int m_gmtOffsetWinter;
    int m_gmtOffsetSummer;
    ENUM_DST_TYPE m_dstType;
    bool m_initialized;

    //+------------------------------------------------------------------+
    //| ブローカーマッピング初期化                                       |
    //+------------------------------------------------------------------+
    void InitMappings()
    {
        // ブローカー別タイムゾーン設定
        // {キーワード, 冬時間GMT, 夏時間GMT, DSTタイプ}
        BrokerTimeInfo mappings[] = {
            //=============================================================
            // XM Group
            //=============================================================
            {"TRADEXFIN", 2, 3, DST_EU},        // XM Global
            {"XM", 2, 3, DST_EU},               // XM
            {"XMTRADING", 2, 3, DST_EU},        // XM Trading Japan

            //=============================================================
            // Exness
            //=============================================================
            {"EXNESS", 0, 0, DST_NONE},         // Exness（GMT+0固定）

            //=============================================================
            // 日本国内ブローカー
            //=============================================================
            {"RAKUTEN", 2, 3, DST_US},          // 楽天証券
            {"RAKUTEN-SEC", 2, 3, DST_US},
            {"GMO", 2, 3, DST_US},              // GMOクリック証券
            {"CLICK-SEC", 2, 3, DST_US},
            {"CLICK SEC", 2, 3, DST_US},
            {"GAITAME.COM", 2, 3, DST_US},      // 外為どっとコム
            {"GAITAMECOM", 2, 3, DST_US},
            {"GAITAME FINEST", 2, 3, DST_US},   // 外為ファイネスト
            {"GAITAMEFINEST", 2, 3, DST_US},
            {"HIROSE", 2, 3, DST_US},           // ヒロセ通商
            {"LION", 2, 3, DST_US},             // LION FX
            {"JFX", 2, 3, DST_US},              // JFX
            {"MONEY PARTNERS", 2, 3, DST_US},   // マネーパートナーズ
            {"MONEYPARTNERS", 2, 3, DST_US},
            {"MANEPA", 2, 3, DST_US},
            {"CENTRAL", 2, 3, DST_US},          // セントラル短資FX
            {"GAITAMEONLINE", 2, 3, DST_US},    // 外為オンライン
            {"GAITAME ONLINE", 2, 3, DST_US},
            {"TRADERS", 2, 3, DST_US},          // トレイダーズ証券
            {"MINNANOFX", 2, 3, DST_US},
            {"SBI", 2, 3, DST_US},              // SBI FXトレード
            {"SBIFX", 2, 3, DST_US},
            {"DMM", 2, 3, DST_US},              // DMM FX
            {"MATSUI", 2, 3, DST_US},           // 松井証券
            {"OANDA", 2, 3, DST_US},            // OANDA
            {"FXCM", 2, 3, DST_US},             // FXCM

            //=============================================================
            // FXGT
            //=============================================================
            {"FXGT", 2, 3, DST_EU},             // FXGT

            //=============================================================
            // 海外ブローカー（ヨーロッパDST）
            //=============================================================
            {"IC MARKETS", 2, 3, DST_EU},       // IC Markets
            {"ICMARKETS", 2, 3, DST_EU},
            {"PEPPERSTONE", 2, 3, DST_EU},      // Pepperstone
            {"HOTFOREX", 2, 3, DST_EU},         // HotForex
            {"HF MARKETS", 2, 3, DST_EU},
            {"HFMARKETS", 2, 3, DST_EU},
            {"TICKMILL", 2, 3, DST_EU},         // Tickmill
            {"TITAN", 2, 3, DST_EU},            // TitanFX
            {"TITANFX", 2, 3, DST_EU},
            {"AXIORY", 2, 3, DST_EU},           // Axiory
            {"THINKMARKETS", 2, 3, DST_EU},     // ThinkMarkets
            {"FP MARKETS", 2, 3, DST_EU},       // FP Markets
            {"FPMARKETS", 2, 3, DST_EU},
            {"FXTM", 2, 3, DST_EU},             // FXTM
            {"FOREXTIME", 2, 3, DST_EU},
            {"VANTAGE", 2, 3, DST_EU},          // Vantage Trading
            {"VANTAGEFX", 2, 3, DST_EU},
            {"THREETRADER", 2, 3, DST_EU},      // ThreeTrader
            {"THREE TRADER", 2, 3, DST_EU},
            {"BIGBOSS", 2, 3, DST_EU},          // BigBoss
            {"BIG BOSS", 2, 3, DST_EU},
            {"LAND", 2, 3, DST_EU},             // Land-FX
            {"LANDFX", 2, 3, DST_EU},
            {"MILTON", 2, 3, DST_EU},           // Milton Markets
            {"IS6", 2, 3, DST_EU},              // IS6FX
            {"IS6FX", 2, 3, DST_EU},
            {"MYFX", 2, 3, DST_EU},             // MYFX Markets
            {"MYFXMARKETS", 2, 3, DST_EU},
            {"TRADEVIEW", 2, 3, DST_EU},        // Tradeview
            {"FXPRO", 2, 3, DST_EU},            // FXPro
            {"AXI", 2, 3, DST_EU},              // Axi
            {"AXITRADER", 2, 3, DST_EU},
            {"EASYMARKETS", 2, 3, DST_EU},      // easyMarkets
            {"EASY MARKETS", 2, 3, DST_EU},
            {"XS.COM", 2, 3, DST_EU},           // XS.com
            {"XSCOM", 2, 3, DST_EU},
            {"FUSION", 2, 3, DST_EU},           // Fusion Markets
            {"FUSIONMARKETS", 2, 3, DST_EU},
            {"GLOBAL PRIME", 2, 3, DST_EU},     // Global Prime
            {"GLOBALPRIME", 2, 3, DST_EU},
            {"BLUEBERRY", 2, 3, DST_EU},        // Blueberry Markets
            {"GO MARKETS", 2, 3, DST_EU},       // GO Markets
            {"GOMARKETS", 2, 3, DST_EU},
            {"ACY", 2, 3, DST_EU},              // ACY Securities
            {"EIGHTCAP", 2, 3, DST_EU},         // Eightcap
            {"MONETA", 2, 3, DST_EU},           // Moneta Markets
            {"FXOPEN", 2, 3, DST_EU},           // FXOpen
            {"FXCHOICE", 2, 3, DST_EU},         // FXChoice

            //=============================================================
            // アメリカDSTブローカー
            //=============================================================
            {"AVATRADE", 2, 3, DST_US},         // AvaTrade
            {"ADMIRAL", 2, 3, DST_US},          // Admiral Markets
            {"ADMIRALMARKETS", 2, 3, DST_US},
            {"ETORO", 2, 3, DST_US},            // eToro
            {"PLUS500", 2, 3, DST_US},          // Plus500
            {"IG", 2, 3, DST_US},               // IG Markets
            {"IG.COM", 2, 3, DST_US},
            {"CMC", 2, 3, DST_US},              // CMC Markets

            //=============================================================
            // GMT+0固定ブローカー
            //=============================================================
            {"ROBOFOREX", 0, 0, DST_NONE},      // RoboForex（一部サーバー）

            //=============================================================
            // その他
            //=============================================================
            {"ALPARI", 2, 3, DST_EU},           // Alpari
            {"FBS", 2, 3, DST_EU},              // FBS
            {"IRONFX", 2, 3, DST_EU},           // IronFX
            {"GKFX", 2, 3, DST_EU},             // GKFX
            {"OCTA", 2, 3, DST_EU}              // OctaFX
        };

        int size = ArraySize(mappings);
        ArrayResize(m_brokerMappings, size);
        for(int i = 0; i < size; i++)
        {
            m_brokerMappings[i] = mappings[i];
        }
    }

    //+------------------------------------------------------------------+
    //| ブローカー名からマッピングを検索                                  |
    //+------------------------------------------------------------------+
    bool FindMapping(const string broker, BrokerTimeInfo &info)
    {
        string upperBroker = broker;
        StringToUpper(upperBroker);

        for(int i = 0; i < ArraySize(m_brokerMappings); i++)
        {
            if(StringFind(upperBroker, m_brokerMappings[i].keyword) >= 0)
            {
                info = m_brokerMappings[i];
                return true;
            }
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| アメリカ式サマータイム判定（3月第2日曜〜11月第1日曜）            |
    //+------------------------------------------------------------------+
    bool IsSummerUS(int year, int month, int day)
    {
        if(month > 3 && month < 11) return true;
        if(month < 3 || month > 11) return false;

        if(month == 3)
        {
            int secondSunday = GetNthSunday(year, 3, 2);
            return (day >= secondSunday);
        }

        if(month == 11)
        {
            int firstSunday = GetNthSunday(year, 11, 1);
            return (day < firstSunday);
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| ヨーロッパ式サマータイム判定（3月最終日曜〜10月最終日曜）        |
    //+------------------------------------------------------------------+
    bool IsSummerEU(int year, int month, int day)
    {
        if(month > 3 && month < 10) return true;
        if(month < 3 || month > 10) return false;

        if(month == 3)
        {
            int lastSunday = GetLastSunday(year, 3);
            return (day >= lastSunday);
        }

        if(month == 10)
        {
            int lastSunday = GetLastSunday(year, 10);
            return (day < lastSunday);
        }

        return false;
    }

    //+------------------------------------------------------------------+
    //| 第N日曜日を取得                                                   |
    //+------------------------------------------------------------------+
    int GetNthSunday(int year, int month, int n)
    {
        MqlDateTime dt;
        dt.year = year;
        dt.mon = month;
        dt.day = 1;
        dt.hour = 12;
        dt.min = 0;
        dt.sec = 0;

        datetime firstDay = StructToTime(dt);
        MqlDateTime firstDt;
        TimeToStruct(firstDay, firstDt);
        int dow = firstDt.day_of_week;

        int firstSunday = (dow == 0) ? 1 : (8 - dow);
        return firstSunday + (n - 1) * 7;
    }

    //+------------------------------------------------------------------+
    //| 月の最終日曜日を取得                                              |
    //+------------------------------------------------------------------+
    int GetLastSunday(int year, int month)
    {
        int lastDay = GetDaysInMonthInternal(year, month);

        MqlDateTime dt;
        dt.year = year;
        dt.mon = month;
        dt.day = lastDay;
        dt.hour = 12;
        dt.min = 0;
        dt.sec = 0;

        datetime lastDayTime = StructToTime(dt);
        MqlDateTime lastDt;
        TimeToStruct(lastDayTime, lastDt);
        int dow = lastDt.day_of_week;

        return lastDay - dow;
    }

    //+------------------------------------------------------------------+
    //| 月の日数を取得                                                    |
    //+------------------------------------------------------------------+
    int GetDaysInMonthInternal(int year, int month)
    {
        if(month == 2)
        {
            if((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0))
                return 29;
            return 28;
        }
        else if(month == 4 || month == 6 || month == 9 || month == 11)
        {
            return 30;
        }
        return 31;
    }

public:
    //+------------------------------------------------------------------+
    //| コンストラクタ                                                    |
    //+------------------------------------------------------------------+
    CBrokerTimeZone()
    {
        m_initialized = false;
        m_gmtOffsetWinter = 2;
        m_gmtOffsetSummer = 3;
        m_dstType = DST_EU;
        InitMappings();
    }

    //+------------------------------------------------------------------+
    //| 初期化                                                            |
    //+------------------------------------------------------------------+
    void Init()
    {
        m_brokerName = AccountInfoString(ACCOUNT_COMPANY);
        string serverName = AccountInfoString(ACCOUNT_SERVER);

        BrokerTimeInfo info;
        if(FindMapping(m_brokerName, info))
        {
            m_gmtOffsetWinter = info.gmtOffsetWinter;
            m_gmtOffsetSummer = info.gmtOffsetSummer;
            m_dstType = info.dstType;

            Print("===== ブローカー時間設定（自動検出） =====");
            Print("ブローカー: ", m_brokerName);
            Print("サーバー: ", serverName);
            Print("タイムゾーン: GMT+", m_gmtOffsetWinter, "(冬) / GMT+", m_gmtOffsetSummer, "(夏)");
            Print("DSTタイプ: ", EnumToString(m_dstType));
        }
        else
        {
            Print("===== ブローカー時間設定（デフォルト） =====");
            Print("ブローカー: ", m_brokerName, " (未登録)");
            Print("サーバー: ", serverName);
            Print("デフォルト設定: GMT+2/+3, EU DST");
            Print("※正しく動作しない場合は手動モードを使用してください");
        }

        m_initialized = true;
    }

    //+------------------------------------------------------------------+
    //| 手動設定で初期化                                                  |
    //+------------------------------------------------------------------+
    void InitManual(int winterOffset, int summerOffset, ENUM_DST_TYPE dstType = DST_US)
    {
        m_brokerName = AccountInfoString(ACCOUNT_COMPANY);
        m_gmtOffsetWinter = winterOffset;
        m_gmtOffsetSummer = summerOffset;
        m_dstType = dstType;

        Print("===== ブローカー時間設定（手動） =====");
        Print("ブローカー: ", m_brokerName);
        Print("手動設定: 冬+", 9 - winterOffset, "h / 夏+", 9 - summerOffset, "h");

        m_initialized = true;
    }

    //+------------------------------------------------------------------+
    //| GMT+0固定で初期化                                                 |
    //+------------------------------------------------------------------+
    void InitGMT0Fixed()
    {
        m_brokerName = AccountInfoString(ACCOUNT_COMPANY);
        m_gmtOffsetWinter = 0;
        m_gmtOffsetSummer = 0;
        m_dstType = DST_NONE;

        Print("===== ブローカー時間設定（GMT+0固定） =====");
        Print("ブローカー: ", m_brokerName);
        Print("固定設定: GMT+0（サマータイムなし）");

        m_initialized = true;
    }

    //+------------------------------------------------------------------+
    //| 現在がサマータイムかどうか                                        |
    //+------------------------------------------------------------------+
    bool IsSummer()
    {
        if(m_dstType == DST_NONE) return false;

        datetime now = TimeCurrent();
        MqlDateTime tm;
        TimeToStruct(now, tm);

        if(m_dstType == DST_US)
            return IsSummerUS(tm.year, tm.mon, tm.day);
        else
            return IsSummerEU(tm.year, tm.mon, tm.day);
    }

    //+------------------------------------------------------------------+
    //| 現在のGMTオフセットを取得                                         |
    //+------------------------------------------------------------------+
    int GetCurrentGMTOffset()
    {
        return IsSummer() ? m_gmtOffsetSummer : m_gmtOffsetWinter;
    }

    //+------------------------------------------------------------------+
    //| 日本時間への変換オフセットを取得                                   |
    //+------------------------------------------------------------------+
    int GetJapanTimeOffset()
    {
        return 9 - GetCurrentGMTOffset();
    }

    //+------------------------------------------------------------------+
    //| サーバー時間を日本時間に変換                                      |
    //+------------------------------------------------------------------+
    datetime ToJapanTime(datetime serverTime)
    {
        return serverTime + GetJapanTimeOffset() * 3600;
    }

    //+------------------------------------------------------------------+
    //| 現在の日本時間を取得                                              |
    //+------------------------------------------------------------------+
    datetime GetJapanTimeNow()
    {
        return ToJapanTime(TimeCurrent());
    }

    //+------------------------------------------------------------------+
    //| 情報取得                                                          |
    //+------------------------------------------------------------------+
    string GetBrokerName() { return m_brokerName; }
    int GetWinterOffset() { return m_gmtOffsetWinter; }
    int GetSummerOffset() { return m_gmtOffsetSummer; }
    ENUM_DST_TYPE GetDSTType() { return m_dstType; }
    bool IsInitialized() { return m_initialized; }
};

//+------------------------------------------------------------------+
//| グローバルインスタンス                                              |
//+------------------------------------------------------------------+
CBrokerTimeZone g_BrokerTimeZone;

//+------------------------------------------------------------------+
//| 時間システム初期化（モード別）                                      |
//+------------------------------------------------------------------+
void InitBrokerTimeZone(ENUM_TIME_MODE mode, int manualWinter = 7, int manualSummer = 6)
{
    bool isBacktest = (bool)MQLInfoInteger(MQL_TESTER);

    switch(mode)
    {
        case TIME_MODE_AUTO:
            if(isBacktest)
            {
                g_BrokerTimeZone.Init();
                Print("実行モード: バックテスト → ブローカー時間自動検出");
            }
            else
            {
                Print("===== 時間モード: AUTO =====");
                Print("実行モード: 本番 → PC時間(TimeGMT)を使用");
            }
            break;

        case TIME_MODE_PC:
            Print("===== 時間モード: PC時間 =====");
            break;

        case TIME_MODE_MANUAL:
            g_BrokerTimeZone.InitManual(9 - manualWinter, 9 - manualSummer, DST_US);
            break;

        case TIME_MODE_GMT0_FIXED:
            g_BrokerTimeZone.InitGMT0Fixed();
            break;
    }
}

//+------------------------------------------------------------------+
//| バックテスト判定                                                    |
//+------------------------------------------------------------------+
bool IsBacktestMode()
{
    return (bool)MQLInfoInteger(MQL_TESTER);
}

//+------------------------------------------------------------------+
//| 日本時間を取得（統合関数）                                          |
//+------------------------------------------------------------------+
datetime GetJapanTimeByMode(ENUM_TIME_MODE mode)
{
    switch(mode)
    {
        case TIME_MODE_AUTO:
            if(IsBacktestMode())
            {
                return g_BrokerTimeZone.GetJapanTimeNow();
            }
            else
            {
                return TimeGMT() + 9 * 3600;
            }

        case TIME_MODE_PC:
            return TimeGMT() + 9 * 3600;

        case TIME_MODE_MANUAL:
            return g_BrokerTimeZone.GetJapanTimeNow();

        case TIME_MODE_GMT0_FIXED:
            return TimeCurrent() + 9 * 3600;
    }

    return g_BrokerTimeZone.GetJapanTimeNow();
}

//+------------------------------------------------------------------+
//| 現在がサマータイムかどうか                                          |
//+------------------------------------------------------------------+
bool IsBrokerSummerTime()
{
    return g_BrokerTimeZone.IsSummer();
}

//+------------------------------------------------------------------+
//| 現在のGMTオフセットを取得                                           |
//+------------------------------------------------------------------+
int GetBrokerGMTOffset()
{
    return g_BrokerTimeZone.GetCurrentGMTOffset();
}

#else   // MQL4 implementation

//+------------------------------------------------------------------+
//| MQL4用の簡易実装                                                   |
//+------------------------------------------------------------------+

int g_MQL4_WinterOffset = 7;
int g_MQL4_SummerOffset = 6;

void InitBrokerTimeZone(int mode, int manualWinter = 7, int manualSummer = 6)
{
    g_MQL4_WinterOffset = manualWinter;
    g_MQL4_SummerOffset = manualSummer;
    Print("MQL4: 時間オフセット設定 冬=", manualWinter, " 夏=", manualSummer);
}

datetime GetJapanTimeByMode(int mode)
{
    if(mode == 1)  // PC時間
        return TimeGMT() + 9 * 3600;
    else if(mode == 3)  // GMT0固定
        return TimeCurrent() + 9 * 3600;
    else
    {
        datetime now = TimeCurrent();
        MqlDateTime tm;
        TimeToStruct(now, tm);

        bool isSummer = (tm.mon > 3 && tm.mon < 11);
        int offset = isSummer ? g_MQL4_SummerOffset : g_MQL4_WinterOffset;

        return now + offset * 3600;
    }
}

bool IsBrokerSummerTime()
{
    datetime now = TimeCurrent();
    MqlDateTime tm;
    TimeToStruct(now, tm);
    return (tm.mon > 3 && tm.mon < 11);
}

int GetBrokerGMTOffset()
{
    return IsBrokerSummerTime() ? (9 - g_MQL4_SummerOffset) : (9 - g_MQL4_WinterOffset);
}

bool IsBacktestMode()
{
    return IsTesting();
}

#endif  // __MQL4__
//+------------------------------------------------------------------+
