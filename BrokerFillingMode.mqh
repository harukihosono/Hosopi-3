//+------------------------------------------------------------------+
//|                                          BrokerFillingMode.mqh  |
//|                   Smart Broker Filling Mode Detection System    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2024"
#property version   "2.00"

// MQL4/MQL5 compatibility - MQL4では全て無効化
#ifndef __MQL4__
//+------------------------------------------------------------------+
//| Global Variables Prefix                                         |
//+------------------------------------------------------------------+
#define FILLING_MODE_PREFIX "FillMode_"

//+------------------------------------------------------------------+
//| Main Filling Mode Manager Class                                 |
//+------------------------------------------------------------------+
class CBrokerFillingMode
{
private:
    // Static mappings
    struct BrokerMap
    {
        string keyword;
        ENUM_ORDER_TYPE_FILLING mode;
    };

    BrokerMap m_brokerMappings[];

    // Current state
    string m_brokerName;
    ENUM_ORDER_TYPE_FILLING m_currentMode;
    bool m_initialized;

    //+------------------------------------------------------------------+
    void InitMappings()
    {
        BrokerMap mappings[] = {
            {"TRADEXFIN", ORDER_FILLING_IOC},     // XM
            {"XM", ORDER_FILLING_IOC},
            {"EXNESS", ORDER_FILLING_FOK},
            {"FXGT", ORDER_FILLING_IOC},          // FXGT
            {"GAITAME FINEST", ORDER_FILLING_IOC}, // 外為ファイネスト
            {"GAITAMEFINEST", ORDER_FILLING_IOC}, // 外為ファイネスト（スペースなし）
            {"IC MARKETS", ORDER_FILLING_FOK},
            {"PEPPERSTONE", ORDER_FILLING_FOK},
            {"HOTFOREX", ORDER_FILLING_FOK},
            {"HF MARKETS", ORDER_FILLING_FOK},
            {"ROBOFOREX", ORDER_FILLING_RETURN},
            {"ALPARI", ORDER_FILLING_RETURN},
            {"FBS", ORDER_FILLING_RETURN},
            {"OCTA", ORDER_FILLING_RETURN},
            {"TICKMILL", ORDER_FILLING_IOC},
            {"TITAN", ORDER_FILLING_IOC},
            {"AVATRADE", ORDER_FILLING_IOC},
            {"FXTM", ORDER_FILLING_IOC},
            {"FOREXTIME", ORDER_FILLING_IOC},
            {"ADMIRAL", ORDER_FILLING_RETURN},
            {"AXIORY", ORDER_FILLING_FOK},
            {"THINKMARKETS", ORDER_FILLING_IOC},
            {"IRONFX", ORDER_FILLING_FOK},
            {"GKFX", ORDER_FILLING_FOK},
            {"FXCM", ORDER_FILLING_FOK},
            {"FP MARKETS", ORDER_FILLING_FOK}
        };

        int size = ArraySize(mappings);
        ArrayResize(m_brokerMappings, size);
        for(int i = 0; i < size; i++)
        {
            m_brokerMappings[i].keyword = mappings[i].keyword;
            m_brokerMappings[i].mode = mappings[i].mode;
        }
    }

    //+------------------------------------------------------------------+
    ENUM_ORDER_TYPE_FILLING GetMappedMode(const string broker)
    {
        string upperBroker = broker;
        StringToUpper(upperBroker);

        for(int i = 0; i < ArraySize(m_brokerMappings); i++)
        {
            if(StringFind(upperBroker, m_brokerMappings[i].keyword) >= 0)
                return m_brokerMappings[i].mode;
        }

        return (ENUM_ORDER_TYPE_FILLING)-1;
    }

    //+------------------------------------------------------------------+
    ENUM_ORDER_TYPE_FILLING GetStoredMode(const string broker)
    {
        string varName = FILLING_MODE_PREFIX + broker;

        if(GlobalVariableCheck(varName))
        {
            int mode = (int)GlobalVariableGet(varName);
            if(mode >= 0 && mode <= 2)
                return (ENUM_ORDER_TYPE_FILLING)mode;
        }

        return (ENUM_ORDER_TYPE_FILLING)-1;
    }

    //+------------------------------------------------------------------+
    void StoreMode(const string broker, ENUM_ORDER_TYPE_FILLING mode)
    {
        string varName = FILLING_MODE_PREFIX + broker;
        GlobalVariableSet(varName, mode);
        GlobalVariableSetOnCondition(varName, mode, mode);
    }

    //+------------------------------------------------------------------+
    bool TestMode(ENUM_ORDER_TYPE_FILLING mode)
    {
        long symbolModes = SymbolInfoInteger(_Symbol, SYMBOL_FILLING_MODE);

        switch(mode)
        {
            case ORDER_FILLING_FOK:
                return (symbolModes & 1) != 0;  // SYMBOL_FILLING_FOK = 1
            case ORDER_FILLING_IOC:
                return (symbolModes & 2) != 0;  // SYMBOL_FILLING_IOC = 2
            case ORDER_FILLING_RETURN:
                return (symbolModes & 4) != 0;  // SYMBOL_FILLING_RETURN = 4
        }

        return false;
    }

    //+------------------------------------------------------------------+
    ENUM_ORDER_TYPE_FILLING DetectOptimalMode()
    {
        // Priority order for testing
        ENUM_ORDER_TYPE_FILLING testOrder[] = {
            ORDER_FILLING_FOK,
            ORDER_FILLING_IOC,
            ORDER_FILLING_RETURN
        };

        for(int i = 0; i < 3; i++)
        {
            if(TestMode(testOrder[i]))
            {
                ENUM_ORDER_TYPE_FILLING detected = testOrder[i];
                StoreMode(m_brokerName, detected);

                if(i > 0)
                    Print("New broker detected. Filling mode: ", EnumToString(detected));

                return detected;
            }
        }

        // Fallback
        return ORDER_FILLING_FOK;
    }

public:
    //+------------------------------------------------------------------+
    CBrokerFillingMode()
    {
        m_initialized = false;
        m_currentMode = ORDER_FILLING_FOK;
        InitMappings();
    }

    //+------------------------------------------------------------------+
    void Init()
    {
        m_brokerName = AccountInfoString(ACCOUNT_COMPANY);
        StringToUpper(m_brokerName);

        // 1. Check static mapping
        ENUM_ORDER_TYPE_FILLING mode = GetMappedMode(m_brokerName);

        // 2. If not found, check stored mapping
        if(mode == -1)
            mode = GetStoredMode(m_brokerName);

        // 3. If still not found, detect optimal mode
        if(mode == -1)
            mode = DetectOptimalMode();
        else if(!TestMode(mode))  // Verify stored/mapped mode still works
            mode = DetectOptimalMode();

        m_currentMode = mode;
        m_initialized = true;

        Print("Broker: ", m_brokerName, " | Filling Mode: ", EnumToString(m_currentMode));
    }

    //+------------------------------------------------------------------+
    ENUM_ORDER_TYPE_FILLING GetMode()
    {
        if(!m_initialized)
            Init();

        return m_currentMode;
    }

    //+------------------------------------------------------------------+
    void Reset()
    {
        // Clear all stored modes
        for(int i = GlobalVariablesTotal() - 1; i >= 0; i--)
        {
            string name = GlobalVariableName(i);
            if(StringFind(name, FILLING_MODE_PREFIX) == 0)
                GlobalVariableDel(name);
        }

        m_initialized = false;
        Print("All stored filling modes cleared");
    }
};

//+------------------------------------------------------------------+
//| Global Instance and Helper Functions                            |
//+------------------------------------------------------------------+
CBrokerFillingMode g_FillingMode;

//+------------------------------------------------------------------+
void InitFillingMode()
{
    g_FillingMode.Init();
}

//+------------------------------------------------------------------+
ENUM_ORDER_TYPE_FILLING GetFillingMode()
{
    return g_FillingMode.GetMode();
}

//+------------------------------------------------------------------+
void ResetFillingModes()
{
    g_FillingMode.Reset();
}

#else   // MQL4 implementation

//+------------------------------------------------------------------+
//| MQL4 Dummy Implementation (フィリングモードはMT4に存在しない)    |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void InitFillingMode()
{
    // MQL4では何もしない
}

//+------------------------------------------------------------------+
int GetFillingMode()
{
    // MQL4では常に0を返す（フィリングモードなし）
    return 0;
}

//+------------------------------------------------------------------+
void ResetFillingModes()
{
    // MQL4では何もしない
}

#endif  // __MQL4__

//+------------------------------------------------------------------+
//| Usage Example                                                    |
//+------------------------------------------------------------------+
/*
int OnInit()
{
    InitFillingMode();
    return INIT_SUCCEEDED;
}

void OnTrade()
{
    #ifdef IS_MQL5
    MqlTradeRequest request;
    request.type_filling = GetFillingMode();
    // ... rest of order setup
    #endif
}
*/