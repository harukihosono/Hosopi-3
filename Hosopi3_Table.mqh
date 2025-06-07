//+------------------------------------------------------------------+
//|                Hosopi 3 - テーブル表示関数 (MQL4/MQL5共通)       |
//|                       Copyright 2025                             |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_Ghost.mqh"

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
         case OBJPROP_ZORDER:
         case OBJPROP_BGCOLOR:
         case OBJPROP_BORDER_TYPE:
            ObjectSetInteger(0, name, prop, (long)value);
            break;
         case OBJPROP_BACK:
         case OBJPROP_SELECTABLE:
            ObjectSetInteger(0, name, prop, (bool)value);
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
   
   #define ObjectSetMQL4         ObjectSet
   #define ObjectCreateMQL4      ObjectCreate
   #define ObjectDeleteMQL4      ObjectDelete
   #define ObjectFindMQL4        ObjectFind
   #define ObjectSetTextMQL4     ObjectSetText
   #define ObjectsTotalMQL4      ObjectsTotal
   #define ObjectNameMQL4        ObjectName
#endif

//+------------------------------------------------------------------+
//| ポジションテーブルを作成する - レイアウトパターン対応版           |
//+------------------------------------------------------------------+
void CreatePositionTable()
{
   DeletePositionTable(); // 既存のテーブルを削除
   g_TableObjectCount = 0;
   
   // レイアウトパターンを適用
   ApplyLayoutPattern();
   
   // テーブル位置を調整された値に設定
   int adjustedTableX = g_EffectiveTableX;
   int adjustedTableY = g_EffectiveTableY;
   
   // ヘッダー列のラベルと位置の修正
   string headers[8] = {"No", "Type", "Lots", "Symbol", "Price", "OpenTime", "Level", "Profit"};
   int columnWidths[8] = {25, 45, 45, 90, 95, 140, 45, 90}; // 各列の幅
   int positions[8]; // 各列の開始位置
   
   // 各列の開始位置を計算
   positions[0] = 5; // 最初の列は少し余白を取る
   for(int i = 1; i < 8; i++) {
      positions[i] = positions[i-1] + columnWidths[i-1];
   }
   
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string tablePrefix = g_ObjectPrefix + "GhostTable_";
   
   // 背景の作成
   string bgName = tablePrefix + "BG";
   ObjectCreateMQL4(bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetMQL4(bgName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
   ObjectSetMQL4(bgName, OBJPROP_XDISTANCE_MQL4, adjustedTableX);
   ObjectSetMQL4(bgName, OBJPROP_YDISTANCE_MQL4, adjustedTableY);
   ObjectSetMQL4(bgName, OBJPROP_XSIZE_MQL4, TABLE_WIDTH);
   ObjectSetMQL4(bgName, OBJPROP_YSIZE_MQL4, TITLE_HEIGHT + TABLE_ROW_HEIGHT * 2);
   ObjectSetMQL4(bgName, OBJPROP_BGCOLOR_MQL4, C'16,16,24');
   ObjectSetMQL4(bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetMQL4(bgName, OBJPROP_COLOR_MQL4, C'64,64,96');
   ObjectSetMQL4(bgName, OBJPROP_WIDTH_MQL4, 1);
   ObjectSetMQL4(bgName, OBJPROP_BACK_MQL4, false);
   ObjectSetMQL4(bgName, OBJPROP_SELECTABLE_MQL4, false);
   #ifdef __MQL5__
      ObjectSetInteger(0, bgName, OBJPROP_ZORDER, 0);
   #else
      ObjectSetInteger(0, bgName, OBJPROP_ZORDER, 0);
   #endif
   
   // タイトル背景
   string titleBgName = tablePrefix + "TitleBG";
   ObjectCreateMQL4(titleBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetMQL4(titleBgName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
   ObjectSetMQL4(titleBgName, OBJPROP_XDISTANCE_MQL4, adjustedTableX);
   ObjectSetMQL4(titleBgName, OBJPROP_YDISTANCE_MQL4, adjustedTableY);
   ObjectSetMQL4(titleBgName, OBJPROP_XSIZE_MQL4, TABLE_WIDTH);
   ObjectSetMQL4(titleBgName, OBJPROP_YSIZE_MQL4, TITLE_HEIGHT);
   ObjectSetMQL4(titleBgName, OBJPROP_BGCOLOR_MQL4, C'32,32,48');
   ObjectSetMQL4(titleBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetMQL4(titleBgName, OBJPROP_COLOR_MQL4, C'32,32,48');
   ObjectSetMQL4(titleBgName, OBJPROP_WIDTH_MQL4, 1);
   ObjectSetMQL4(titleBgName, OBJPROP_BACK_MQL4, false);
   ObjectSetMQL4(titleBgName, OBJPROP_SELECTABLE_MQL4, false);
   #ifdef __MQL5__
      ObjectSetInteger(0, titleBgName, OBJPROP_ZORDER, 1);
   #else
      ObjectSetInteger(0, titleBgName, OBJPROP_ZORDER, 1);
   #endif
   
   // タイトルテキスト
   string titleName = tablePrefix + "Title";
   ObjectCreateMQL4(titleName, OBJ_LABEL, 0, 0, 0);
   ObjectSetMQL4(titleName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
   ObjectSetMQL4(titleName, OBJPROP_XDISTANCE_MQL4, adjustedTableX + 10);
   ObjectSetMQL4(titleName, OBJPROP_YDISTANCE_MQL4, adjustedTableY + 3);
   ObjectSetTextMQL4(titleName, GhostTableTitle, 7, "MS Gothic", TABLE_TEXT_COLOR);
   ObjectSetMQL4(titleName, OBJPROP_SELECTABLE_MQL4, false);
   #ifdef __MQL5__
      ObjectSetInteger(0, titleName, OBJPROP_ZORDER, 2);
   #else
      ObjectSetInteger(0, titleName, OBJPROP_ZORDER, 2);
   #endif
   
   // ヘッダー背景
   string headerBgName = tablePrefix + "HeaderBG";
   ObjectCreateMQL4(headerBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetMQL4(headerBgName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
   ObjectSetMQL4(headerBgName, OBJPROP_XDISTANCE_MQL4, adjustedTableX);
   ObjectSetMQL4(headerBgName, OBJPROP_YDISTANCE_MQL4, adjustedTableY + TITLE_HEIGHT);
   ObjectSetMQL4(headerBgName, OBJPROP_XSIZE_MQL4, TABLE_WIDTH);
   ObjectSetMQL4(headerBgName, OBJPROP_YSIZE_MQL4, TABLE_ROW_HEIGHT);
   ObjectSetMQL4(headerBgName, OBJPROP_BGCOLOR_MQL4, TABLE_HEADER_BG);
   ObjectSetMQL4(headerBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetMQL4(headerBgName, OBJPROP_COLOR_MQL4, TABLE_HEADER_BG);
   ObjectSetMQL4(headerBgName, OBJPROP_WIDTH_MQL4, 1);
   ObjectSetMQL4(headerBgName, OBJPROP_BACK_MQL4, false);
   ObjectSetMQL4(headerBgName, OBJPROP_SELECTABLE_MQL4, false);
   #ifdef __MQL5__
      ObjectSetInteger(0, headerBgName, OBJPROP_ZORDER, 1);
   #else
      ObjectSetInteger(0, headerBgName, OBJPROP_ZORDER, 1);
   #endif
   
   // ヘッダー列のラベルを作成
   for(int i = 0; i < 8; i++)
   {
      string name = tablePrefix + "Header_" + headers[i];
      ObjectCreateMQL4(name, OBJ_LABEL, 0, 0, 0);
      ObjectSetMQL4(name, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
      ObjectSetMQL4(name, OBJPROP_XDISTANCE_MQL4, adjustedTableX + positions[i]);
      ObjectSetMQL4(name, OBJPROP_YDISTANCE_MQL4, adjustedTableY + TITLE_HEIGHT + 4);
      ObjectSetTextMQL4(name, headers[i], 8, "MS Gothic", TABLE_TEXT_COLOR);
      ObjectSetMQL4(name, OBJPROP_SELECTABLE_MQL4, false);
      #ifdef __MQL5__
         ObjectSetInteger(0, name, OBJPROP_ZORDER, 2);
      #else
         ObjectSetInteger(0, name, OBJPROP_ZORDER, 2);
      #endif
      
      // オブジェクト名を保存
      SaveObjectName(name, g_TableNames, g_TableObjectCount);
   }
   
   // オブジェクト名を保存
   SaveObjectName(bgName, g_TableNames, g_TableObjectCount);
   SaveObjectName(titleBgName, g_TableNames, g_TableObjectCount);
   SaveObjectName(titleName, g_TableNames, g_TableObjectCount);
   SaveObjectName(headerBgName, g_TableNames, g_TableObjectCount);
   
   // テーブルを更新
   UpdatePositionTable();
}

//+------------------------------------------------------------------+
//| ポジションテーブルを更新する - レイアウトパターン対応版           |
//+------------------------------------------------------------------+
void UpdatePositionTable()
{
   // バックテスト時は更新頻度を下げる
   if(IsTesting() && MathMod(Bars, 20) != 0)
      return;
      
   // レイアウトパターンを適用
   ApplyLayoutPattern();
   
   // テーブル位置を調整された値に設定
   int adjustedTableX = g_EffectiveTableX;
   int adjustedTableY = g_EffectiveTableY;
   
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string tablePrefix = g_ObjectPrefix + "GhostTable_";
   
   // 列の位置を定義
   int columnWidths[8] = {25, 45, 45, 90, 95, 140, 45, 90}; // 各列の幅
   int positions[8]; // 各列の開始位置
   
   // 各列の開始位置を計算
   positions[0] = 5; // 最初の列は少し余白を取る
   for(int i = 1; i < 8; i++) {
      positions[i] = positions[i-1] + columnWidths[i-1];
   }
   
   // 行オブジェクトをクリア（ヘッダーと背景は残す）
   int total = ObjectsTotalMQL4();
   for(int i = total - 1; i >= 0; i--)
   {
      if(i >= ObjectsTotalMQL4()) continue; // 安全チェック
      
      string name = ObjectNameMQL4(i);
      if(StringFind(name, tablePrefix + "Row_") == 0)
      {
         ObjectDeleteMQL4(name);
      }
   }
   
   // ゴーストポジションの表示
   int totalGhostPositions = g_GhostBuyCount + g_GhostSellCount;
   
   // 一時配列にすべてのポジション(ゴースト+リアル)を結合
   PositionInfo allPositions[];
   
   // リアル注文の数をカウント
   int realBuyCount = 0;
   int realSellCount = 0;
   
   // リアル注文を数える（MQL4/MQL5共通化）
   #ifdef __MQL5__
      int totalPos = PositionsTotal();
      for(int i = totalPos - 1; i >= 0; i--) {
         if(PositionSelectByTicket(PositionGetTicket(i))) {
            if(PositionGetSymbol(i) == Symbol() && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) realBuyCount++;
               if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) realSellCount++;
            }
         }
      }
   #else
      for(int i = OrdersTotal() - 1; i >= 0; i--) {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
               if(OrderType() == OP_BUY) realBuyCount++;
               if(OrderType() == OP_SELL) realSellCount++;
            }
         }
      }
   #endif
   
   // 全ポジション数を計算
   int totalPositions = totalGhostPositions + realBuyCount + realSellCount;
   ArrayResize(allPositions, totalPositions);
   
   // Buy ゴーストポジションをコピー
   for(int i = 0; i < g_GhostBuyCount; i++) {
      allPositions[i] = g_GhostBuyPositions[i];
   }
   
   // Sell ゴーストポジションをコピー
   for(int i = 0; i < g_GhostSellCount; i++) {
      allPositions[g_GhostBuyCount + i] = g_GhostSellPositions[i];
   }
   
   // リアル注文を配列に追加
   int nextIndex = totalGhostPositions;
   
   #ifdef __MQL5__
      for(int i = PositionsTotal() - 1; i >= 0; i--) {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket)) {
            if(PositionGetSymbol(i) == Symbol() && PositionGetInteger(POSITION_MAGIC) == MagicNumber) {
               PositionInfo pos;
               pos.type = (int)PositionGetInteger(POSITION_TYPE);
               pos.lots = PositionGetDouble(POSITION_VOLUME);
               pos.symbol = PositionGetString(POSITION_SYMBOL);
               pos.price = PositionGetDouble(POSITION_PRICE_OPEN);
               pos.profit = PositionGetDouble(POSITION_PROFIT);
               pos.ticket = (int)ticket;
               pos.openTime = (datetime)PositionGetInteger(POSITION_TIME);
               pos.isGhost = false;
               pos.level = 0;
               
               allPositions[nextIndex++] = pos;
            }
         }
      }
   #else
      for(int i = OrdersTotal() - 1; i >= 0; i--) {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
            if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
               PositionInfo pos;
               pos.type = OrderType();
               pos.lots = OrderLots();
               pos.symbol = OrderSymbol();
               pos.price = OrderOpenPrice();
               pos.profit = OrderProfit();
               pos.ticket = OrderTicket();
               pos.openTime = OrderOpenTime();
               pos.isGhost = false;
               pos.level = 0;
               
               allPositions[nextIndex++] = pos;
            }
         }
      }
   #endif
   
   // 各ポジションのレベルを計算
   int buyCount = 0;
   int sellCount = 0;
   
   for(int i = 0; i < totalPositions; i++) {
      if((allPositions[i].type == OP_BUY) || 
         #ifdef __MQL5__
            (allPositions[i].type == POSITION_TYPE_BUY)
         #else
            false
         #endif
        ) {
         // Buy側ポジションのレベルを時系列の順番で計算
         int orderRank = 1;
         for(int j = 0; j < totalPositions; j++) {
            if((allPositions[j].type == OP_BUY) || 
               #ifdef __MQL5__
                  (allPositions[j].type == POSITION_TYPE_BUY)
               #else
                  false
               #endif
              ) {
               if(allPositions[j].openTime < allPositions[i].openTime) {
                  orderRank++;
               }
            }
         }
         allPositions[i].level = orderRank - 1;
         buyCount++;
      } else {
         // Sell側ポジションのレベルを時系列の順番で計算
         int orderRank = 1;
         for(int j = 0; j < totalPositions; j++) {
            if((allPositions[j].type == OP_SELL) || 
               #ifdef __MQL5__
                  (allPositions[j].type == POSITION_TYPE_SELL)
               #else
                  false
               #endif
              ) {
               if(allPositions[j].openTime < allPositions[i].openTime) {
                  orderRank++;
               }
            }
         }
         allPositions[i].level = orderRank - 1;
         sellCount++;
      }
   }
   
   // ポジションをソート（ロット数の昇順）
   PositionInfo sortedPositions[];
   ArrayResize(sortedPositions, totalPositions);
   int sortedCount = 0;
   
   // BUY側のゴーストポジションをロット数の昇順にソート
   for(int i = 0; i < 100; i++) {
      double minLot = 999999.0;
      int minIndex = -1;
      
      for(int j = 0; j < totalPositions; j++) {
         bool isBuy = (allPositions[j].type == OP_BUY) || 
                      #ifdef __MQL5__
                         (allPositions[j].type == POSITION_TYPE_BUY)
                      #else
                         false
                      #endif
                      ;
         
         if(isBuy && allPositions[j].isGhost && allPositions[j].lots < minLot) {
            bool alreadySorted = false;
            for(int k = 0; k < sortedCount; k++) {
               if(sortedPositions[k].ticket == allPositions[j].ticket && 
                  sortedPositions[k].openTime == allPositions[j].openTime &&
                  sortedPositions[k].price == allPositions[j].price &&
                  sortedPositions[k].type == allPositions[j].type) {
                  alreadySorted = true;
                  break;
               }
            }
            
            if(!alreadySorted) {
               minLot = allPositions[j].lots;
               minIndex = j;
            }
         }
      }
      
      if(minIndex >= 0) {
         sortedPositions[sortedCount++] = allPositions[minIndex];
      } else {
         break;
      }
   }
   
   // BUY側のリアルポジションをロット数の昇順にソート
   for(int i = 0; i < 100; i++) {
      double minLot = 999999.0;
      int minIndex = -1;
      
      for(int j = 0; j < totalPositions; j++) {
         bool isBuy = (allPositions[j].type == OP_BUY) || 
                      #ifdef __MQL5__
                         (allPositions[j].type == POSITION_TYPE_BUY)
                      #else
                         false
                      #endif
                      ;
         
         if(isBuy && !allPositions[j].isGhost && allPositions[j].lots < minLot) {
            bool alreadySorted = false;
            for(int k = 0; k < sortedCount; k++) {
               if(sortedPositions[k].ticket == allPositions[j].ticket && 
                  sortedPositions[k].openTime == allPositions[j].openTime &&
                  sortedPositions[k].price == allPositions[j].price &&
                  sortedPositions[k].type == allPositions[j].type) {
                  alreadySorted = true;
                  break;
               }
            }
            
            if(!alreadySorted) {
               minLot = allPositions[j].lots;
               minIndex = j;
            }
         }
      }
      
      if(minIndex >= 0) {
         sortedPositions[sortedCount++] = allPositions[minIndex];
      } else {
         break;
      }
   }
   
   // SELL側のゴーストポジションをロット数の昇順にソート
   for(int i = 0; i < 100; i++) {
      double minLot = 999999.0;
      int minIndex = -1;
      
      for(int j = 0; j < totalPositions; j++) {
         bool isSell = (allPositions[j].type == OP_SELL) || 
                       #ifdef __MQL5__
                          (allPositions[j].type == POSITION_TYPE_SELL)
                       #else
                          false
                       #endif
                       ;
         
         if(isSell && allPositions[j].isGhost && allPositions[j].lots < minLot) {
            bool alreadySorted = false;
            for(int k = 0; k < sortedCount; k++) {
               if(sortedPositions[k].ticket == allPositions[j].ticket && 
                  sortedPositions[k].openTime == allPositions[j].openTime &&
                  sortedPositions[k].price == allPositions[j].price &&
                  sortedPositions[k].type == allPositions[j].type) {
                  alreadySorted = true;
                  break;
               }
            }
            
            if(!alreadySorted) {
               minLot = allPositions[j].lots;
               minIndex = j;
            }
         }
      }
      
      if(minIndex >= 0) {
         sortedPositions[sortedCount++] = allPositions[minIndex];
      } else {
         break;
      }
   }
   
   // SELL側のリアルポジションをロット数の昇順にソート
   for(int i = 0; i < 100; i++) {
      double minLot = 999999.0;
      int minIndex = -1;
      
      for(int j = 0; j < totalPositions; j++) {
         bool isSell = (allPositions[j].type == OP_SELL) || 
                       #ifdef __MQL5__
                          (allPositions[j].type == POSITION_TYPE_SELL)
                       #else
                          false
                       #endif
                       ;
         
         if(isSell && !allPositions[j].isGhost && allPositions[j].lots < minLot) {
            bool alreadySorted = false;
            for(int k = 0; k < sortedCount; k++) {
               if(sortedPositions[k].ticket == allPositions[j].ticket && 
                  sortedPositions[k].openTime == allPositions[j].openTime &&
                  sortedPositions[k].price == allPositions[j].price &&
                  sortedPositions[k].type == allPositions[j].type) {
                  alreadySorted = true;
                  break;
               }
            }
            
            if(!alreadySorted) {
               minLot = allPositions[j].lots;
               minIndex = j;
            }
         }
      }
      
      if(minIndex >= 0) {
         sortedPositions[sortedCount++] = allPositions[minIndex];
      } else {
         break;
      }
   }
   
   // ArrayCopyの代わりに手動でコピー
   if(sortedCount > 0) {
      for(int i = 0; i < sortedCount; i++) {
         allPositions[i] = sortedPositions[i];
      }
   }
   
   // データがない場合のメッセージ
   if(totalPositions == 0)
   {
      string noDataName = tablePrefix + "Row_NoData";
      ObjectCreateMQL4(noDataName, OBJ_LABEL, 0, 0, 0);
      ObjectSetMQL4(noDataName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
      ObjectSetMQL4(noDataName, OBJPROP_XDISTANCE_MQL4, adjustedTableX + 10);
      ObjectSetMQL4(noDataName, OBJPROP_YDISTANCE_MQL4, adjustedTableY + TITLE_HEIGHT + TABLE_ROW_HEIGHT + 10);
      ObjectSetTextMQL4(noDataName, "No positions", 8, "MS Gothic", TABLE_TEXT_COLOR);
      ObjectSetMQL4(noDataName, OBJPROP_SELECTABLE_MQL4, false);
      #ifdef __MQL5__
         ObjectSetInteger(0, noDataName, OBJPROP_ZORDER, 2);
      #else
         ObjectSetInteger(0, noDataName, OBJPROP_ZORDER, 2);
      #endif
      
      SaveObjectName(noDataName, g_TableNames, g_TableObjectCount);
      
      // 背景のサイズを最小化
      string bgName = tablePrefix + "BG";
      if(ObjectFindMQL4(bgName) >= 0)
      {
         ObjectSetMQL4(bgName, OBJPROP_YSIZE_MQL4, TITLE_HEIGHT + TABLE_ROW_HEIGHT * 2);
      }
      
      ChartRedraw();
      return;
   }
   
   // 表示する最大行数を計算
   int visibleRows = MathMin(totalPositions, MAX_VISIBLE_ROWS);
   
   // 各行のテーブルデータを表示
   for(int i = 0; i < visibleRows; i++)
   {
      // 行の位置計算
      int rowY = adjustedTableY + TITLE_HEIGHT + TABLE_ROW_HEIGHT * (i + 1);
      color rowBg = (i % 2 == 0) ? TABLE_ROW_BG1 : TABLE_ROW_BG2;
      
      // 行の背景
      string rowBgName = tablePrefix + "Row_" + IntegerToString(i) + "_BG";
      ObjectCreateMQL4(rowBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetMQL4(rowBgName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
      ObjectSetMQL4(rowBgName, OBJPROP_XDISTANCE_MQL4, adjustedTableX);
      ObjectSetMQL4(rowBgName, OBJPROP_YDISTANCE_MQL4, rowY);
      ObjectSetMQL4(rowBgName, OBJPROP_XSIZE_MQL4, TABLE_WIDTH);
      ObjectSetMQL4(rowBgName, OBJPROP_YSIZE_MQL4, TABLE_ROW_HEIGHT);
      ObjectSetMQL4(rowBgName, OBJPROP_BGCOLOR_MQL4, rowBg);
      ObjectSetMQL4(rowBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetMQL4(rowBgName, OBJPROP_COLOR_MQL4, rowBg);
      ObjectSetMQL4(rowBgName, OBJPROP_WIDTH_MQL4, 1);
      ObjectSetMQL4(rowBgName, OBJPROP_BACK_MQL4, false);
      ObjectSetMQL4(rowBgName, OBJPROP_SELECTABLE_MQL4, false);
      #ifdef __MQL5__
         ObjectSetInteger(0, rowBgName, OBJPROP_ZORDER, 1);
      #else
         ObjectSetInteger(0, rowBgName, OBJPROP_ZORDER, 1);
      #endif
      
      // ゴーストかリアルかで文字色を決定
      color textColorToUse = allPositions[i].isGhost ? TABLE_GHOST_COLOR : TABLE_TEXT_COLOR;
      
      // No.
      string noName = tablePrefix + "Row_" + IntegerToString(i) + "_No";
      ObjectCreateMQL4(noName, OBJ_LABEL, 0, 0, 0);
      ObjectSetMQL4(noName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
      ObjectSetMQL4(noName, OBJPROP_XDISTANCE_MQL4, adjustedTableX + positions[0]);
      ObjectSetMQL4(noName, OBJPROP_YDISTANCE_MQL4, rowY + 4);
      ObjectSetTextMQL4(noName, IntegerToString(i+1), 8, "MS Gothic", textColorToUse);
      ObjectSetMQL4(noName, OBJPROP_SELECTABLE_MQL4, false);
      #ifdef __MQL5__
         ObjectSetInteger(0, noName, OBJPROP_ZORDER, 3);
      #else
         ObjectSetInteger(0, noName, OBJPROP_ZORDER, 3);
      #endif
      
      // Type
      string typeText = "";
      bool isBuy = (allPositions[i].type == OP_BUY) || 
                   #ifdef __MQL5__
                      (allPositions[i].type == POSITION_TYPE_BUY)
                   #else
                      false
                   #endif
                   ;
      
      typeText = isBuy ? "Buy" : "Sell";
      
      if(allPositions[i].isGhost) {
         typeText = "G " + typeText;
      }
      
      color typeColor = isBuy ? TABLE_BUY_COLOR : TABLE_SELL_COLOR;
      if(allPositions[i].isGhost) {
         typeColor = isBuy ? 
                     ColorDarken(TABLE_BUY_COLOR, 60) : ColorDarken(TABLE_SELL_COLOR, 60);
      }
      
      string typeName = tablePrefix + "Row_" + IntegerToString(i) + "_Type";
      ObjectCreateMQL4(typeName, OBJ_LABEL, 0, 0, 0);
      ObjectSetMQL4(typeName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
      ObjectSetMQL4(typeName, OBJPROP_XDISTANCE_MQL4, adjustedTableX + positions[1]);
      ObjectSetMQL4(typeName, OBJPROP_YDISTANCE_MQL4, rowY + 4);
      ObjectSetTextMQL4(typeName, typeText, 8, "MS Gothic", typeColor);
      ObjectSetMQL4(typeName, OBJPROP_SELECTABLE_MQL4, false);
      #ifdef __MQL5__
         ObjectSetInteger(0, typeName, OBJPROP_ZORDER, 3);
      #else
         ObjectSetInteger(0, typeName, OBJPROP_ZORDER, 3);
      #endif
      
      // Lots
      string lotsName = tablePrefix + "Row_" + IntegerToString(i) + "_Lots";
      ObjectCreateMQL4(lotsName, OBJ_LABEL, 0, 0, 0);
      ObjectSetMQL4(lotsName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
      ObjectSetMQL4(lotsName, OBJPROP_XDISTANCE_MQL4, adjustedTableX + positions[2]);
      ObjectSetMQL4(lotsName, OBJPROP_YDISTANCE_MQL4, rowY + 4);
      ObjectSetTextMQL4(lotsName, DoubleToString(allPositions[i].lots, 2), 8, "MS Gothic", textColorToUse);
      ObjectSetMQL4(lotsName, OBJPROP_SELECTABLE_MQL4, false);
      #ifdef __MQL5__
         ObjectSetInteger(0, lotsName, OBJPROP_ZORDER, 3);
      #else
         ObjectSetInteger(0, lotsName, OBJPROP_ZORDER, 3);
      #endif
      
      // Symbol
      string symbolName = tablePrefix + "Row_" + IntegerToString(i) + "_Symbol";
      ObjectCreateMQL4(symbolName, OBJ_LABEL, 0, 0, 0);
      ObjectSetMQL4(symbolName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
      ObjectSetMQL4(symbolName, OBJPROP_XDISTANCE_MQL4, adjustedTableX + positions[3]);
      ObjectSetMQL4(symbolName, OBJPROP_YDISTANCE_MQL4, rowY + 4);
      ObjectSetTextMQL4(symbolName, allPositions[i].symbol, 8, "MS Gothic", textColorToUse);
      ObjectSetMQL4(symbolName, OBJPROP_SELECTABLE_MQL4, false);
      #ifdef __MQL5__
         ObjectSetInteger(0, symbolName, OBJPROP_ZORDER, 3);
      #else
         ObjectSetInteger(0, symbolName, OBJPROP_ZORDER, 3);
      #endif
      
      // Price
      string priceStr = "";
      if(StringFind(allPositions[i].symbol, "JPY") >= 0)
         priceStr = DoubleToString(allPositions[i].price, 3);
      else if(StringFind(allPositions[i].symbol, "XAU") >= 0)
         priceStr = DoubleToString(allPositions[i].price, 2);
      else
         priceStr = DoubleToString(allPositions[i].price, 5);
         
      string priceName = tablePrefix + "Row_" + IntegerToString(i) + "_Price";
      ObjectCreateMQL4(priceName, OBJ_LABEL, 0, 0, 0);
      ObjectSetMQL4(priceName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
      ObjectSetMQL4(priceName, OBJPROP_XDISTANCE_MQL4, adjustedTableX + positions[4]);
      ObjectSetMQL4(priceName, OBJPROP_YDISTANCE_MQL4, rowY + 4);
      ObjectSetTextMQL4(priceName, priceStr, 8, "MS Gothic", textColorToUse);
      ObjectSetMQL4(priceName, OBJPROP_SELECTABLE_MQL4, false);
      #ifdef __MQL5__
         ObjectSetInteger(0, priceName, OBJPROP_ZORDER, 3);
      #else
         ObjectSetInteger(0, priceName, OBJPROP_ZORDER, 3);
      #endif
      
      // OpenTime
      string timeStr = TimeToString(allPositions[i].openTime, TIME_DATE|TIME_MINUTES);
      string timeName = tablePrefix + "Row_" + IntegerToString(i) + "_OpenTime";
      ObjectCreateMQL4(timeName, OBJ_LABEL, 0, 0, 0);
      ObjectSetMQL4(timeName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
      ObjectSetMQL4(timeName, OBJPROP_XDISTANCE_MQL4, adjustedTableX + positions[5]);
      ObjectSetMQL4(timeName, OBJPROP_YDISTANCE_MQL4, rowY + 4);
      ObjectSetTextMQL4(timeName, timeStr, 8, "MS Gothic", textColorToUse);
      ObjectSetMQL4(timeName, OBJPROP_SELECTABLE_MQL4, false);
      #ifdef __MQL5__
         ObjectSetInteger(0, timeName, OBJPROP_ZORDER, 3);
      #else
         ObjectSetInteger(0, timeName, OBJPROP_ZORDER, 3);
      #endif
      
      // Level
      string levelName = tablePrefix + "Row_" + IntegerToString(i) + "_Level";
      ObjectCreateMQL4(levelName, OBJ_LABEL, 0, 0, 0);
      ObjectSetMQL4(levelName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
      ObjectSetMQL4(levelName, OBJPROP_XDISTANCE_MQL4, adjustedTableX + positions[6]);
      ObjectSetMQL4(levelName, OBJPROP_YDISTANCE_MQL4, rowY + 4);
      ObjectSetTextMQL4(levelName, IntegerToString(allPositions[i].level + 1), 8, "MS Gothic", textColorToUse);
      ObjectSetMQL4(levelName, OBJPROP_SELECTABLE_MQL4, false);
      #ifdef __MQL5__
         ObjectSetInteger(0, levelName, OBJPROP_ZORDER, 3);
      #else
         ObjectSetInteger(0, levelName, OBJPROP_ZORDER, 3);
      #endif
      
      // Profit
      string profitName = tablePrefix + "Row_" + IntegerToString(i) + "_Profit";
      ObjectCreateMQL4(profitName, OBJ_LABEL, 0, 0, 0);
      ObjectSetMQL4(profitName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
      ObjectSetMQL4(profitName, OBJPROP_XDISTANCE_MQL4, adjustedTableX + positions[7]);
      ObjectSetMQL4(profitName, OBJPROP_YDISTANCE_MQL4, rowY + 4);
      
      // 損益の計算
      double profit = 0;
      if(allPositions[i].isGhost) {
         // ゴーストの場合は仮想損益を計算
         bool isGhostBuy = (allPositions[i].type == OP_BUY) || 
                          #ifdef __MQL5__
                             (allPositions[i].type == POSITION_TYPE_BUY)
                          #else
                             false
                          #endif
                          ;
         
         if(isGhostBuy) {
            profit = (GetBidPrice() - allPositions[i].price) * allPositions[i].lots * MarketInfo(Symbol(), MODE_TICKVALUE) / Point;
         } else {
            profit = (allPositions[i].price - GetAskPrice()) * allPositions[i].lots * MarketInfo(Symbol(), MODE_TICKVALUE) / Point;
         }
      } else {
         // リアルポジションの場合は実際の損益を取得
         #ifdef __MQL5__
            if(PositionSelectByTicket(allPositions[i].ticket)) {
               profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            }
         #else
            for(int j = OrdersTotal() - 1; j >= 0; j--) {
               if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
                  if(OrderTicket() == allPositions[i].ticket) {
                     profit = OrderProfit() + OrderSwap() + OrderCommission();
                     break;
                  }
               }
            }
         #endif
      }
      
      // 損益表示の色
      color profitColor = profit >= 0 ? clrLime : clrRed;
      if(allPositions[i].isGhost) {
         profitColor = profit >= 0 ? clrForestGreen : clrFireBrick;
      }
      
      #ifdef __MQL5__
         ObjectSetTextMQL4(profitName, DoubleToString(profit, 2) + "", 8, "MS Gothic", profitColor);
      #else
         ObjectSetTextMQL4(profitName, DoubleToStr(profit, 2) + "", 8, "MS Gothic", profitColor);
      #endif
      ObjectSetMQL4(profitName, OBJPROP_SELECTABLE_MQL4, false);
      #ifdef __MQL5__
         ObjectSetInteger(0, profitName, OBJPROP_ZORDER, 3);
      #else
         ObjectSetInteger(0, profitName, OBJPROP_ZORDER, 3);
      #endif
      
      // オブジェクト名を保存
      SaveObjectName(rowBgName, g_TableNames, g_TableObjectCount);
      SaveObjectName(noName, g_TableNames, g_TableObjectCount);
      SaveObjectName(typeName, g_TableNames, g_TableObjectCount);
      SaveObjectName(lotsName, g_TableNames, g_TableObjectCount);
      SaveObjectName(symbolName, g_TableNames, g_TableObjectCount);
      SaveObjectName(priceName, g_TableNames, g_TableObjectCount);
      SaveObjectName(timeName, g_TableNames, g_TableObjectCount);
      SaveObjectName(levelName, g_TableNames, g_TableObjectCount);
      SaveObjectName(profitName, g_TableNames, g_TableObjectCount);
   }
   
   // 合計損益の計算と表示
   double totalBuyProfit = CalculateCombinedProfit(OP_BUY);
   double totalSellProfit = CalculateCombinedProfit(OP_SELL);
   double totalProfit = totalBuyProfit + totalSellProfit;
   
   // 合計損益行の背景
   string totalRowBgName = tablePrefix + "Row_Total_BG";
   ObjectCreateMQL4(totalRowBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetMQL4(totalRowBgName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
   ObjectSetMQL4(totalRowBgName, OBJPROP_XDISTANCE_MQL4, adjustedTableX);
   ObjectSetMQL4(totalRowBgName, OBJPROP_YDISTANCE_MQL4, adjustedTableY + TITLE_HEIGHT + TABLE_ROW_HEIGHT * (visibleRows + 1));
   ObjectSetMQL4(totalRowBgName, OBJPROP_XSIZE_MQL4, TABLE_WIDTH);
   ObjectSetMQL4(totalRowBgName, OBJPROP_YSIZE_MQL4, TABLE_ROW_HEIGHT);
   ObjectSetMQL4(totalRowBgName, OBJPROP_BGCOLOR_MQL4, C'48,48,64');
   ObjectSetMQL4(totalRowBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetMQL4(totalRowBgName, OBJPROP_COLOR_MQL4, C'48,48,64');
   ObjectSetMQL4(totalRowBgName, OBJPROP_WIDTH_MQL4, 1);
   ObjectSetMQL4(totalRowBgName, OBJPROP_BACK_MQL4, false);
   ObjectSetMQL4(totalRowBgName, OBJPROP_SELECTABLE_MQL4, false);
   #ifdef __MQL5__
      ObjectSetInteger(0, totalRowBgName, OBJPROP_ZORDER, 1);
   #else
      ObjectSetInteger(0, totalRowBgName, OBJPROP_ZORDER, 1);
   #endif
   
   // 合計テキスト
   string totalTextName = tablePrefix + "Row_Total_Text";
   ObjectCreateMQL4(totalTextName, OBJ_LABEL, 0, 0, 0);
   ObjectSetMQL4(totalTextName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
   ObjectSetMQL4(totalTextName, OBJPROP_XDISTANCE_MQL4, adjustedTableX + positions[0]);
   ObjectSetMQL4(totalTextName, OBJPROP_YDISTANCE_MQL4, adjustedTableY + TITLE_HEIGHT + TABLE_ROW_HEIGHT * (visibleRows + 1) + 4);
   ObjectSetTextMQL4(totalTextName, "TOTAL:", 8, "MS Gothic Bold", TABLE_TEXT_COLOR);
   ObjectSetMQL4(totalTextName, OBJPROP_SELECTABLE_MQL4, false);
   #ifdef __MQL5__
      ObjectSetInteger(0, totalTextName, OBJPROP_ZORDER, 3);
   #else
      ObjectSetInteger(0, totalTextName, OBJPROP_ZORDER, 3);
   #endif
   
   // Buy合計
   string buyTotalName = tablePrefix + "Row_BuyTotal";
   ObjectCreateMQL4(buyTotalName, OBJ_LABEL, 0, 0, 0);
   ObjectSetMQL4(buyTotalName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
   ObjectSetMQL4(buyTotalName, OBJPROP_XDISTANCE_MQL4, adjustedTableX + positions[2]);
   ObjectSetMQL4(buyTotalName, OBJPROP_YDISTANCE_MQL4, adjustedTableY + TITLE_HEIGHT + TABLE_ROW_HEIGHT * (visibleRows + 1) + 4);
   color buyColor = totalBuyProfit >= 0 ? clrLime : clrRed;
   #ifdef __MQL5__
      ObjectSetTextMQL4(buyTotalName, "BUY: " + DoubleToString(totalBuyProfit, 2) + "", 8, "MS Gothic", buyColor);
   #else
      ObjectSetTextMQL4(buyTotalName, "BUY: " + DoubleToStr(totalBuyProfit, 2) + "", 8, "MS Gothic", buyColor);
   #endif
   ObjectSetMQL4(buyTotalName, OBJPROP_SELECTABLE_MQL4, false);
   #ifdef __MQL5__
      ObjectSetInteger(0, buyTotalName, OBJPROP_ZORDER, 3);
   #else
      ObjectSetInteger(0, buyTotalName, OBJPROP_ZORDER, 3);
   #endif
   
   // Sell合計
   string sellTotalName = tablePrefix + "Row_SellTotal";
   ObjectCreateMQL4(sellTotalName, OBJ_LABEL, 0, 0, 0);
   ObjectSetMQL4(sellTotalName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
   ObjectSetMQL4(sellTotalName, OBJPROP_XDISTANCE_MQL4, adjustedTableX + positions[4]);
   ObjectSetMQL4(sellTotalName, OBJPROP_YDISTANCE_MQL4, adjustedTableY + TITLE_HEIGHT + TABLE_ROW_HEIGHT * (visibleRows + 1) + 4);
   color sellColor = totalSellProfit >= 0 ? clrLime : clrRed;
   #ifdef __MQL5__
      ObjectSetTextMQL4(sellTotalName, "SELL: " + DoubleToString(totalSellProfit, 2) + "", 8, "MS Gothic", sellColor);
   #else
      ObjectSetTextMQL4(sellTotalName, "SELL: " + DoubleToStr(totalSellProfit, 2) + "", 8, "MS Gothic", sellColor);
   #endif
   ObjectSetMQL4(sellTotalName, OBJPROP_SELECTABLE_MQL4, false);
   #ifdef __MQL5__
      ObjectSetInteger(0, sellTotalName, OBJPROP_ZORDER, 3);
   #else
      ObjectSetInteger(0, sellTotalName, OBJPROP_ZORDER, 3);
   #endif
   
   // 総合計
   string netTotalName = tablePrefix + "Row_NetTotal";
   ObjectCreateMQL4(netTotalName, OBJ_LABEL, 0, 0, 0);
   ObjectSetMQL4(netTotalName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
   ObjectSetMQL4(netTotalName, OBJPROP_XDISTANCE_MQL4, adjustedTableX + positions[7]);
   ObjectSetMQL4(netTotalName, OBJPROP_YDISTANCE_MQL4, adjustedTableY + TITLE_HEIGHT + TABLE_ROW_HEIGHT * (visibleRows + 1) + 4);
   color totalColor = totalProfit >= 0 ? clrLime : clrRed;
   #ifdef __MQL5__
      ObjectSetTextMQL4(netTotalName, "NET: " + DoubleToString(totalProfit, 2) + "", 8, "MS Gothic Bold", totalColor);
   #else
      ObjectSetTextMQL4(netTotalName, "NET: " + DoubleToStr(totalProfit, 2) + "", 8, "MS Gothic Bold", totalColor);
   #endif
   ObjectSetMQL4(netTotalName, OBJPROP_SELECTABLE_MQL4, false);
   #ifdef __MQL5__
      ObjectSetInteger(0, netTotalName, OBJPROP_ZORDER, 3);
   #else
      ObjectSetInteger(0, netTotalName, OBJPROP_ZORDER, 3);
   #endif
   
   // オブジェクト名を保存
   SaveObjectName(totalRowBgName, g_TableNames, g_TableObjectCount);
   SaveObjectName(totalTextName, g_TableNames, g_TableObjectCount);
   SaveObjectName(buyTotalName, g_TableNames, g_TableObjectCount);
   SaveObjectName(sellTotalName, g_TableNames, g_TableObjectCount);
   SaveObjectName(netTotalName, g_TableNames, g_TableObjectCount);
   
   // 背景のサイズを調整
   string bgName = tablePrefix + "BG";
   if(ObjectFindMQL4(bgName) >= 0)
   {
      int bgHeight = TITLE_HEIGHT + TABLE_ROW_HEIGHT * (visibleRows + 2);
      ObjectSetMQL4(bgName, OBJPROP_YSIZE_MQL4, bgHeight);
   }
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| ポジションテーブルを削除する                                       |
//+------------------------------------------------------------------+
void DeletePositionTable()
{
   for(int i = 0; i < g_TableObjectCount; i++)
   {
      if(ObjectFindMQL4(g_TableNames[i]) >= 0)
         ObjectDeleteMQL4(g_TableNames[i]);
   }
   
   g_TableObjectCount = 0;
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| カスタム色テーブルを表示するための補助関数                         |
//+------------------------------------------------------------------+
void ShowColorLegend()
{
   string tablePrefix = g_ObjectPrefix + "Legend_";
   int legendX = PanelX + PANEL_WIDTH + 10;
   int legendY = PanelY;
   int legendWidth = 150;
   int legendHeight = 120;
   int rowHeight = 20;

   // 背景
   string bgName = tablePrefix + "BG";
   ObjectCreateMQL4(bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetMQL4(bgName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
   ObjectSetMQL4(bgName, OBJPROP_XDISTANCE_MQL4, legendX);
   ObjectSetMQL4(bgName, OBJPROP_YDISTANCE_MQL4, legendY);
   ObjectSetMQL4(bgName, OBJPROP_XSIZE_MQL4, legendWidth);
   ObjectSetMQL4(bgName, OBJPROP_YSIZE_MQL4, legendHeight);
   ObjectSetMQL4(bgName, OBJPROP_BGCOLOR_MQL4, C'16,16,24');
   ObjectSetMQL4(bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetMQL4(bgName, OBJPROP_COLOR_MQL4, C'64,64,96');
   ObjectSetMQL4(bgName, OBJPROP_WIDTH_MQL4, 1);
   ObjectSetMQL4(bgName, OBJPROP_BACK_MQL4, false);
   ObjectSetMQL4(bgName, OBJPROP_SELECTABLE_MQL4, false);

   // タイトル背景
   string titleBgName = tablePrefix + "TitleBG";
   ObjectCreateMQL4(titleBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetMQL4(titleBgName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
   ObjectSetMQL4(titleBgName, OBJPROP_XDISTANCE_MQL4, legendX);
   ObjectSetMQL4(titleBgName, OBJPROP_YDISTANCE_MQL4, legendY);
   ObjectSetMQL4(titleBgName, OBJPROP_XSIZE_MQL4, legendWidth);
   ObjectSetMQL4(titleBgName, OBJPROP_YSIZE_MQL4, rowHeight);
   ObjectSetMQL4(titleBgName, OBJPROP_BGCOLOR_MQL4, C'32,32,48');
   ObjectSetMQL4(titleBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetMQL4(titleBgName, OBJPROP_COLOR_MQL4, C'32,32,48');
   ObjectSetMQL4(titleBgName, OBJPROP_WIDTH_MQL4, 1);
   ObjectSetMQL4(titleBgName, OBJPROP_BACK_MQL4, false);
   ObjectSetMQL4(titleBgName, OBJPROP_SELECTABLE_MQL4, false);

   // タイトルテキスト
   string titleName = tablePrefix + "Title";
   ObjectCreateMQL4(titleName, OBJ_LABEL, 0, 0, 0);
   ObjectSetMQL4(titleName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
   ObjectSetMQL4(titleName, OBJPROP_XDISTANCE_MQL4, legendX + 10);
   ObjectSetMQL4(titleName, OBJPROP_YDISTANCE_MQL4, legendY + 4);
   ObjectSetTextMQL4(titleName, "Legend", 8, "Arial Bold", TABLE_TEXT_COLOR);
   ObjectSetMQL4(titleName, OBJPROP_SELECTABLE_MQL4, false);

   // 凡例項目
   string items[4];
   color itemColors[4];

   // 配列の初期化
   items[0] = "リアル Buy";
   items[1] = "リアル Sell";
   items[2] = "ゴースト Buy";
   items[3] = "ゴースト Sell";

   itemColors[0] = TABLE_BUY_COLOR;
   itemColors[1] = TABLE_SELL_COLOR;
   itemColors[2] = ColorDarken(TABLE_BUY_COLOR, 60);
   itemColors[3] = ColorDarken(TABLE_SELL_COLOR, 60);

   for(int i = 0; i < 4; i++)
   {
      // 行背景
      string rowBgName = tablePrefix + "Row" + IntegerToString(i) + "_BG";
      ObjectCreateMQL4(rowBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetMQL4(rowBgName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
      ObjectSetMQL4(rowBgName, OBJPROP_XDISTANCE_MQL4, legendX);
      ObjectSetMQL4(rowBgName, OBJPROP_YDISTANCE_MQL4, legendY + rowHeight * (i + 1));
      ObjectSetMQL4(rowBgName, OBJPROP_XSIZE_MQL4, legendWidth);
      ObjectSetMQL4(rowBgName, OBJPROP_YSIZE_MQL4, rowHeight);
      ObjectSetMQL4(rowBgName, OBJPROP_BGCOLOR_MQL4, (i % 2 == 0) ? TABLE_ROW_BG1 : TABLE_ROW_BG2);
      ObjectSetMQL4(rowBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetMQL4(rowBgName, OBJPROP_COLOR_MQL4, (i % 2 == 0) ? TABLE_ROW_BG1 : TABLE_ROW_BG2);
      ObjectSetMQL4(rowBgName, OBJPROP_WIDTH_MQL4, 1);
      ObjectSetMQL4(rowBgName, OBJPROP_BACK_MQL4, false);
      ObjectSetMQL4(rowBgName, OBJPROP_SELECTABLE_MQL4, false);
      
      // 色サンプル
      string colorBoxName = tablePrefix + "Row" + IntegerToString(i) + "_Color";
      ObjectCreateMQL4(colorBoxName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetMQL4(colorBoxName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
      ObjectSetMQL4(colorBoxName, OBJPROP_XDISTANCE_MQL4, legendX + 10);
      ObjectSetMQL4(colorBoxName, OBJPROP_YDISTANCE_MQL4, legendY + rowHeight * (i + 1) + 4);
      ObjectSetMQL4(colorBoxName, OBJPROP_XSIZE_MQL4, 12);
      ObjectSetMQL4(colorBoxName, OBJPROP_YSIZE_MQL4, 12);
      ObjectSetMQL4(colorBoxName, OBJPROP_BGCOLOR_MQL4, itemColors[i]);
      ObjectSetMQL4(colorBoxName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetMQL4(colorBoxName, OBJPROP_COLOR_MQL4, itemColors[i]);
      ObjectSetMQL4(colorBoxName, OBJPROP_WIDTH_MQL4, 1);
      ObjectSetMQL4(colorBoxName, OBJPROP_BACK_MQL4, false);
      ObjectSetMQL4(colorBoxName, OBJPROP_SELECTABLE_MQL4, false);
      
      // テキスト
      string textName = tablePrefix + "Row" + IntegerToString(i) + "_Text";
      ObjectCreateMQL4(textName, OBJ_LABEL, 0, 0, 0);
      ObjectSetMQL4(textName, OBJPROP_CORNER_MQL4, CORNER_LEFT_UPPER);
      ObjectSetMQL4(textName, OBJPROP_XDISTANCE_MQL4, legendX + 30);
      ObjectSetMQL4(textName, OBJPROP_YDISTANCE_MQL4, legendY + rowHeight * (i + 1) + 4);
      ObjectSetTextMQL4(textName, items[i], 8, "Arial", TABLE_TEXT_COLOR);
      ObjectSetMQL4(textName, OBJPROP_SELECTABLE_MQL4, false);
      
      // オブジェクト名を保存
      SaveObjectName(rowBgName, g_TableNames, g_TableObjectCount);
      SaveObjectName(colorBoxName, g_TableNames, g_TableObjectCount);
      SaveObjectName(textName, g_TableNames, g_TableObjectCount);
   }

   // 凡例オブジェクト名を保存
   SaveObjectName(bgName, g_TableNames, g_TableObjectCount);
   SaveObjectName(titleBgName, g_TableNames, g_TableObjectCount);
   SaveObjectName(titleName, g_TableNames, g_TableObjectCount);
}

//+------------------------------------------------------------------+
//| ポジション情報表示のための補助関数 - ポップアップスタイル          |
//+------------------------------------------------------------------+
void ShowPositionDetails(int index, PositionInfo &pos)
{
   string tablePrefix = g_ObjectPrefix + "Details_";
   int detailsX = 200;
   int detailsY = 200;
   int detailsWidth = 300;
   int rowHeight = 20;
   int padding = 10;

   // 詳細情報を構築
   string details = "";
   string typeStr = "";
   
   bool isBuy = (pos.type == OP_BUY) || 
                #ifdef __MQL5__
                   (pos.type == POSITION_TYPE_BUY)
                #else
                   false
                #endif
                ;
   
   typeStr = isBuy ? "Buy" : "Sell";
   
   details += "Type: " + typeStr + (pos.isGhost ? " (Ghost)" : " (Real)") + "\n";
   details += "Symbol: " + pos.symbol + "\n";
   details += "Lots: " + DoubleToString(pos.lots, 2) + "\n";
   details += "Price: " + DoubleToString(pos.price, Digits) + "\n";
   details += "Open Time: " + TimeToString(pos.openTime, TIME_DATE|TIME_SECONDS) + "\n";
   details += "Level: " + IntegerToString(pos.level + 1) + "\n";

   // 現在値と損益を計算
   double currentPrice = isBuy ? GetBidPrice() : GetAskPrice();
   double profit = 0;

   if(pos.isGhost) {
      // ゴーストの場合は仮想損益を計算
      if(isBuy) {
         profit = (GetBidPrice() - pos.price) * pos.lots * MarketInfo(Symbol(), MODE_TICKVALUE) / Point;
      } else {
         profit = (pos.price - GetAskPrice()) * pos.lots * MarketInfo(Symbol(), MODE_TICKVALUE) / Point;
      }
   } else {
      // リアルポジションの場合は実際の損益を取得
      #ifdef __MQL5__
         if(PositionSelectByTicket(pos.ticket)) {
            profit = PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
            details += "Swap: " + DoubleToString(PositionGetDouble(POSITION_SWAP), 2) + "\n";
         }
      #else
         if(OrderSelect(pos.ticket, SELECT_BY_TICKET)) {
            profit = OrderProfit() + OrderSwap() + OrderCommission();
            details += "Swap: " + DoubleToString(OrderSwap(), 2) + "\n";
            details += "Commission: " + DoubleToString(OrderCommission(), 2) + "\n";
         }
      #endif
   }

   details += "Current Price: " + DoubleToString(currentPrice, Digits) + "\n";
   details += "Profit: " + DoubleToString(profit, 2) + "\n";

   // ポップアップウィンドウを表示
   string title = "Position Details - " + typeStr + " #" + IntegerToString(index + 1);
   
   MessageBox(details, title, MB_ICONINFORMATION);
}

//+------------------------------------------------------------------+
//| 文字列内の特定の文字のカウント - 補助関数                        |
//+------------------------------------------------------------------+
int StringFindCount(string str, string find)
{
   int count = 0;
   int pos = 0;

   while((pos = StringFind(str, find, pos)) != -1)
   {
      count++;
      pos++;
   }

   return count;
}

//+------------------------------------------------------------------+
//| Hosopi 3のテーブル設定ダイアログを表示                            |
//+------------------------------------------------------------------+
void ShowTableSettingsDialog()
{
   // ダイアログタイトル
   string title = "Hosopi 3 - テーブル設定";

   // ダイアログ内容を構築
   string message = "現在のテーブル設定:\n\n";

   message += "テーブルタイトル: " + GhostTableTitle + "\n";
   message += "テーブルX座標: " + IntegerToString(GhostTableX) + "\n";
   message += "テーブルY座標: " + IntegerToString(GhostTableY) + "\n";
   message += "更新間隔: " + IntegerToString(UpdateInterval) + "秒\n\n";

   message += "表示設定:\n";
   message += "Ghost情報表示: " + (GhostInfoDisplay == ON_MODE ? "ON" : "OFF") + "\n";
   message += "ポジションサイン表示: " + (PositionSignDisplay == ON_MODE ? "ON" : "OFF") + "\n";
   message += "平均取得価格ライン表示: " + (AveragePriceLine == ON_MODE ? "ON" : "OFF") + "\n";

   // メッセージボックスを表示
   MessageBox(message, title, MB_ICONINFORMATION);
}