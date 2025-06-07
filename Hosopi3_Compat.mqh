//+------------------------------------------------------------------+
//|                    Hosopi3_Compat.mqh                            |
//|                    MQL4/MQL5互換関数ライブラリ                    |
//|                    Copyright 2025                                |
//+------------------------------------------------------------------+
#ifndef HOSOPI3_COMPAT_MQH
#define HOSOPI3_COMPAT_MQH

//+------------------------------------------------------------------+
//| アカウント番号を取得する互換関数                                  |
//+------------------------------------------------------------------+
int GetAccountNumber()
{
   #ifdef __MQL4__
      return AccountNumber();
   #else
      return (int)AccountInfoInteger(ACCOUNT_LOGIN);
   #endif
}

//+------------------------------------------------------------------+
//| オブジェクト検索の互換関数                                        |
//+------------------------------------------------------------------+
bool ObjectExists(string name)
{
   #ifdef __MQL4__
      return (ObjectFind(name) >= 0);
   #else
      return (ObjectFind(0, name) >= 0);
   #endif
}

//+------------------------------------------------------------------+
//| オブジェクト削除の互換関数                                        |
//+------------------------------------------------------------------+
bool ObjectDeleteMQL(string name)
{
   #ifdef __MQL4__
      return ObjectDelete(name);
   #else
      return ObjectDelete(0, name);
   #endif
}

//+------------------------------------------------------------------+
//| オブジェクト総数取得の互換関数                                    |
//+------------------------------------------------------------------+
int ObjectsTotalMQL()
{
   #ifdef __MQL4__
      return ObjectsTotal();
   #else
      return ObjectsTotal(0, -1, -1);
   #endif
}

//+------------------------------------------------------------------+
//| オブジェクト名取得の互換関数                                      |
//+------------------------------------------------------------------+
string ObjectNameMQL(int index)
{
   #ifdef __MQL4__
      return ObjectName(index);
   #else
      return ObjectName(0, index, -1, -1);
   #endif
}

#endif // HOSOPI3_COMPAT_MQH