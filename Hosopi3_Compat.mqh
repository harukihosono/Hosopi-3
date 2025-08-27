//+------------------------------------------------------------------+
//|                    Hosopi3_Compat.mqh                            |
//|                    MQL4/MQL5互換関数ライブラリ                    |
//|                    Copyright 2025                                |
//+------------------------------------------------------------------+
#ifndef HOSOPI3_COMPAT_MQH
#define HOSOPI3_COMPAT_MQH

// Point変数の互換性
#ifdef __MQL5__
   #define Point _Point
#endif

// AccountEquity関数はMQL4では標準で利用可能
// MQL5では互換用の関数を定義
#ifdef __MQL5__
double AccountEquity()
{
   return AccountInfoDouble(ACCOUNT_EQUITY);
}

//+------------------------------------------------------------------+
//| RefreshRates互換関数                                             |
//+------------------------------------------------------------------+
bool RefreshRates()
{
   // MQL5ではSymbolInfoTickを使用して最新価格を取得
   MqlTick tick;
   return SymbolInfoTick(Symbol(), tick);
}

// Sleep関数はMQL5で標準提供されているため、互換関数は不要
#endif

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

//+------------------------------------------------------------------+
//| MQL4/MQL5互換性のためのマクロ定義                                |
//+------------------------------------------------------------------+
#ifdef __MQL5__
   #define OBJPROP_CORNER_MQL4     OBJPROP_CORNER
   #define OBJPROP_XDISTANCE_MQL4  OBJPROP_XDISTANCE
   #define OBJPROP_YDISTANCE_MQL4  OBJPROP_YDISTANCE
   #define OBJPROP_XSIZE_MQL4      OBJPROP_XSIZE
   #define OBJPROP_YSIZE_MQL4      OBJPROP_YSIZE
   #define OBJPROP_BGCOLOR_MQL4    OBJPROP_BGCOLOR
   #define OBJPROP_COLOR_MQL4      OBJPROP_COLOR
   #define OBJPROP_WIDTH_MQL4      OBJPROP_WIDTH
   #define OBJPROP_BACK_MQL4       OBJPROP_BACK
   #define OBJPROP_SELECTABLE_MQL4 OBJPROP_SELECTABLE
   #define OBJPROP_ZORDER_MQL4     OBJPROP_ZORDER
   #define OBJPROP_HIDDEN_MQL4     OBJPROP_HIDDEN
   #define OBJPROP_STYLE_MQL4      OBJPROP_STYLE
   
   // MQL5用の関数ラッパー
   void ObjectSetMQL4(string name, int prop, double value)
   {
      switch(prop)
      {
         case OBJPROP_CORNER:
         case OBJPROP_XDISTANCE:
         case OBJPROP_YDISTANCE:
         case OBJPROP_XSIZE:
         case OBJPROP_YSIZE:
         case OBJPROP_COLOR:
         case OBJPROP_WIDTH:
         case OBJPROP_BGCOLOR:
         case OBJPROP_BORDER_TYPE:
            ObjectSetInteger(0, name, (ENUM_OBJECT_PROPERTY_INTEGER)prop, (long)value);
            break;
         case OBJPROP_ZORDER:
            ObjectSetInteger(0, name, OBJPROP_ZORDER, (long)value);
            break;
         case OBJPROP_BACK:
         case OBJPROP_SELECTABLE:
            ObjectSetInteger(0, name, (ENUM_OBJECT_PROPERTY_INTEGER)prop, (bool)value);
            break;
      }
   }
   
   bool ObjectCreateMQL4(string name, int type, int window, datetime time1, double price1)
   {
      return ObjectCreate(0, name, (ENUM_OBJECT)type, window, time1, price1);
   }
   
   bool ObjectDeleteMQL4(string name)
   {
      return ObjectDelete(0, name);
   }
   
   int ObjectFindMQL4(string name)
   {
      return ObjectFind(0, name);
   }
   
   bool ObjectSetTextMQL4(string name, string text, int font_size, string font_name, color text_color)
   {
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
      ObjectSetString(0, name, OBJPROP_FONT, font_name);
      ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
      return true;
   }
   
   int ObjectsTotalMQL4()
   {
      return ObjectsTotal(0, -1, -1);
   }
   
   string ObjectNameMQL4(int index)
   {
      return ObjectName(0, index, -1, -1);
   }
   
   #define Bars Bars(_Symbol, _Period)
   
   // MQL5でのMODE定数を定義
   #define MODE_TICKVALUE 16
   #define MODE_TICKSIZE 17
   #define MODE_POINT 11
   #define MODE_DIGITS 12
   #define MODE_SPREAD 13
   
   // MQL5でIsTesting()を実装
   bool IsTesting()
   {
      return (bool)MQLInfoInteger(MQL_TESTER);
   }
   
   // MQL5でMarketInfo()を実装
   double MarketInfo(string symbol, int mode)
   {
      switch(mode)
      {
         case MODE_TICKVALUE:
            return SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
         case MODE_TICKSIZE:
            return SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
         case MODE_POINT:
            return SymbolInfoDouble(symbol, SYMBOL_POINT);
         case MODE_DIGITS:
            return (double)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
         case MODE_SPREAD:
            return (double)SymbolInfoInteger(symbol, SYMBOL_SPREAD);
         default:
            return 0;
      }
   }
   
#else
   // MQL4の場合はそのまま使用
   #define OBJPROP_CORNER_MQL4     OBJPROP_CORNER
   #define OBJPROP_XDISTANCE_MQL4  OBJPROP_XDISTANCE
   #define OBJPROP_YDISTANCE_MQL4  OBJPROP_YDISTANCE
   #define OBJPROP_XSIZE_MQL4      OBJPROP_XSIZE
   #define OBJPROP_YSIZE_MQL4      OBJPROP_YSIZE
   #define OBJPROP_BGCOLOR_MQL4    OBJPROP_BGCOLOR
   #define OBJPROP_COLOR_MQL4      OBJPROP_COLOR
   #define OBJPROP_WIDTH_MQL4      OBJPROP_WIDTH
   #define OBJPROP_BACK_MQL4       OBJPROP_BACK
   #define OBJPROP_SELECTABLE_MQL4 OBJPROP_SELECTABLE
   #define OBJPROP_ZORDER_MQL4     OBJPROP_ZORDER
   #define OBJPROP_HIDDEN_MQL4     OBJPROP_HIDDEN
   #define OBJPROP_STYLE_MQL4      OBJPROP_STYLE
   
   #define ObjectSetMQL4         ObjectSet
   #define ObjectCreateMQL4      ObjectCreate
   #define ObjectDeleteMQL4      ObjectDelete
   #define ObjectFindMQL4        ObjectFind
   #define ObjectSetTextMQL4     ObjectSetText
   #define ObjectsTotalMQL4      ObjectsTotal
   #define ObjectNameMQL4        ObjectName
#endif

//+------------------------------------------------------------------+
//| 共通のオブジェクト削除処理                                     |
//+------------------------------------------------------------------+
void DeleteObjectsByPrefix(string prefix)
{
   int totalObjects = ObjectsTotalMQL();
   for (int i = totalObjects - 1; i >= 0; i--)
   {
      string objName = ObjectNameMQL(i);
      if (StringFind(objName, prefix) == 0)
      {
         ObjectDeleteMQL(objName);
      }
   }
}

//+------------------------------------------------------------------+
//| グローバル変数プレフィックス生成関数                          |
//+------------------------------------------------------------------+
string GenerateGlobalVarPrefix()
{
   return "Hosopi3_" + Symbol() + "_" + IntegerToString(Period()) + "_";
}

#endif // HOSOPI3_COMPAT_MQH