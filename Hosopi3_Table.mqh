//+------------------------------------------------------------------+
//|                Hosopi 3 - テーブル表示関数 (MQL4/MQL5共通)        |
//|                       Copyright 2025                             |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_Ghost.mqh"

//+------------------------------------------------------------------+
//| ポジションテーブルを作成する (MQL4/MQL5共通)                     |
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
   CreateTableBackground(tablePrefix, adjustedTableX, adjustedTableY);
   
   // タイトルバーの作成
   CreateTableTitle(tablePrefix, adjustedTableX, adjustedTableY);
   
   // ヘッダーの作成
   CreateTableHeader(tablePrefix, adjustedTableX, adjustedTableY, headers, positions);
   
   // テーブルを更新
   UpdatePositionTable();
}

//+------------------------------------------------------------------+
//| テーブル背景を作成 (MQL4/MQL5共通)                               |
//+------------------------------------------------------------------+
void CreateTableBackground(string tablePrefix, int x, int y)
{
   string bgName = tablePrefix + "BG";
   
#ifdef __MQL5__
   ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, bgName, OBJPROP_XSIZE, TABLE_WIDTH);
   ObjectSetInteger(0, bgName, OBJPROP_YSIZE, TITLE_HEIGHT + TABLE_ROW_HEIGHT * 2);
   ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, C'16,16,24');
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, bgName, OBJPROP_COLOR, C'64,64,96');
   ObjectSetInteger(0, bgName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, bgName, OBJPROP_BACK, false);
   ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, bgName, OBJPROP_ZORDER, 0);
#else
   ObjectCreate(bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(bgName, OBJPROP_XDISTANCE, x);
   ObjectSet(bgName, OBJPROP_YDISTANCE, y);
   ObjectSet(bgName, OBJPROP_XSIZE, TABLE_WIDTH);
   ObjectSet(bgName, OBJPROP_YSIZE, TITLE_HEIGHT + TABLE_ROW_HEIGHT * 2);
   ObjectSet(bgName, OBJPROP_BGCOLOR, C'16,16,24');
   ObjectSet(bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(bgName, OBJPROP_COLOR, C'64,64,96');
   ObjectSet(bgName, OBJPROP_WIDTH, 1);
   ObjectSet(bgName, OBJPROP_BACK, false);
   ObjectSet(bgName, OBJPROP_SELECTABLE, false);
#endif
   
   SaveObjectName(bgName, g_TableNames, g_TableObjectCount);
}

//+------------------------------------------------------------------+
//| テーブルタイトルを作成 (MQL4/MQL5共通)                           |
//+------------------------------------------------------------------+
void CreateTableTitle(string tablePrefix, int x, int y)
{
   // タイトル背景
   string titleBgName = tablePrefix + "TitleBG";
   
#ifdef __MQL5__
   ObjectCreate(0, titleBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, titleBgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, titleBgName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, titleBgName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, titleBgName, OBJPROP_XSIZE, TABLE_WIDTH);
   ObjectSetInteger(0, titleBgName, OBJPROP_YSIZE, TITLE_HEIGHT);
   ObjectSetInteger(0, titleBgName, OBJPROP_BGCOLOR, C'32,32,48');
   ObjectSetInteger(0, titleBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, titleBgName, OBJPROP_COLOR, C'32,32,48');
   ObjectSetInteger(0, titleBgName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, titleBgName, OBJPROP_BACK, false);
   ObjectSetInteger(0, titleBgName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, titleBgName, OBJPROP_ZORDER, 1);
#else
   ObjectCreate(titleBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(titleBgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(titleBgName, OBJPROP_XDISTANCE, x);
   ObjectSet(titleBgName, OBJPROP_YDISTANCE, y);
   ObjectSet(titleBgName, OBJPROP_XSIZE, TABLE_WIDTH);
   ObjectSet(titleBgName, OBJPROP_YSIZE, TITLE_HEIGHT);
   ObjectSet(titleBgName, OBJPROP_BGCOLOR, C'32,32,48');
   ObjectSet(titleBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(titleBgName, OBJPROP_COLOR, C'32,32,48');
   ObjectSet(titleBgName, OBJPROP_WIDTH, 1);
   ObjectSet(titleBgName, OBJPROP_BACK, false);
   ObjectSet(titleBgName, OBJPROP_SELECTABLE, false);
#endif
   
   // タイトルテキスト
   string titleName = tablePrefix + "Title";
   
#ifdef __MQL5__
   ObjectCreate(0, titleName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, titleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, titleName, OBJPROP_XDISTANCE, x + 10);
   ObjectSetInteger(0, titleName, OBJPROP_YDISTANCE, y + 3);
   ObjectSetString(0, titleName, OBJPROP_TEXT, GhostTableTitle);
   ObjectSetString(0, titleName, OBJPROP_FONT, "MS Gothic");
   ObjectSetInteger(0, titleName, OBJPROP_FONTSIZE, 7);
   ObjectSetInteger(0, titleName, OBJPROP_COLOR, TABLE_TEXT_COLOR);
   ObjectSetInteger(0, titleName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, titleName, OBJPROP_ZORDER, 2);
#else
   ObjectCreate(titleName, OBJ_LABEL, 0, 0, 0);
   ObjectSet(titleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(titleName, OBJPROP_XDISTANCE, x + 10);
   ObjectSet(titleName, OBJPROP_YDISTANCE, y + 3);
   ObjectSetText(titleName, GhostTableTitle, 7, "MS Gothic", TABLE_TEXT_COLOR);
   ObjectSet(titleName, OBJPROP_SELECTABLE, false);
#endif
   
   SaveObjectName(titleBgName, g_TableNames, g_TableObjectCount);
   SaveObjectName(titleName, g_TableNames, g_TableObjectCount);
}

//+------------------------------------------------------------------+
//| テーブルヘッダーを作成 (MQL4/MQL5共通)                           |
//+------------------------------------------------------------------+
void CreateTableHeader(string tablePrefix, int x, int y, string &headers[], int &positions[])
{
   // ヘッダー背景
   string headerBgName = tablePrefix + "HeaderBG";
   
#ifdef __MQL5__
   ObjectCreate(0, headerBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, headerBgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, headerBgName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, headerBgName, OBJPROP_YDISTANCE, y + TITLE_HEIGHT);
   ObjectSetInteger(0, headerBgName, OBJPROP_XSIZE, TABLE_WIDTH);
   ObjectSetInteger(0, headerBgName, OBJPROP_YSIZE, TABLE_ROW_HEIGHT);
   ObjectSetInteger(0, headerBgName, OBJPROP_BGCOLOR, TABLE_HEADER_BG);
   ObjectSetInteger(0, headerBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, headerBgName, OBJPROP_COLOR, TABLE_HEADER_BG);
   ObjectSetInteger(0, headerBgName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, headerBgName, OBJPROP_BACK, false);
   ObjectSetInteger(0, headerBgName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, headerBgName, OBJPROP_ZORDER, 1);
#else
   ObjectCreate(headerBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(headerBgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(headerBgName, OBJPROP_XDISTANCE, x);
   ObjectSet(headerBgName, OBJPROP_YDISTANCE, y + TITLE_HEIGHT);
   ObjectSet(headerBgName, OBJPROP_XSIZE, TABLE_WIDTH);
   ObjectSet(headerBgName, OBJPROP_YSIZE, TABLE_ROW_HEIGHT);
   ObjectSet(headerBgName, OBJPROP_BGCOLOR, TABLE_HEADER_BG);
   ObjectSet(headerBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(headerBgName, OBJPROP_COLOR, TABLE_HEADER_BG);
   ObjectSet(headerBgName, OBJPROP_WIDTH, 1);
   ObjectSet(headerBgName, OBJPROP_BACK, false);
   ObjectSet(headerBgName, OBJPROP_SELECTABLE, false);
#endif
   
   // ヘッダー列のラベルを作成
   for(int i = 0; i < 8; i++)
   {
      string name = tablePrefix + "Header_" + headers[i];
      
#ifdef __MQL5__
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x + positions[i]);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y + TITLE_HEIGHT + 4);
      ObjectSetString(0, name, OBJPROP_TEXT, headers[i]);
      ObjectSetString(0, name, OBJPROP_FONT, "MS Gothic");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, name, OBJPROP_COLOR, TABLE_TEXT_COLOR);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 2);
#else
      ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
      ObjectSet(name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(name, OBJPROP_XDISTANCE, x + positions[i]);
      ObjectSet(name, OBJPROP_YDISTANCE, y + TITLE_HEIGHT + 4);
      ObjectSetText(name, headers[i], 8, "MS Gothic", TABLE_TEXT_COLOR);
      ObjectSet(name, OBJPROP_SELECTABLE, false);
#endif
      
      SaveObjectName(name, g_TableNames, g_TableObjectCount);
   }
   
   SaveObjectName(headerBgName, g_TableNames, g_TableObjectCount);
}

//+------------------------------------------------------------------+
//| ポジションテーブルを更新する (MQL4/MQL5共通)                     |
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
   
   // オブジェクト名にプレフィックスを追加
   string tablePrefix = g_ObjectPrefix + "GhostTable_";
   
   // 列の位置を定義
   int columnWidths[8] = {25, 45, 45, 90, 95, 140, 45, 90};
   int positions[8];
   
   // 各列の開始位置を計算
   positions[0] = 5;
   for(int i = 1; i < 8; i++) {
      positions[i] = positions[i-1] + columnWidths[i-1];
   }
   
   // 既存の行を削除
   DeleteTableRows(tablePrefix);
   
   // ポジション情報を収集して表示
   PositionInfo allPositions[];
   int totalPositions = CollectAllPositions(allPositions);
   
   // データがない場合の処理
   if(totalPositions == 0)
   {
      DisplayNoDataMessage(tablePrefix, adjustedTableX, adjustedTableY);
      UpdateTableBackground(tablePrefix, TITLE_HEIGHT + TABLE_ROW_HEIGHT * 2);
      ChartRedraw();
      return;
   }
   
   // ポジションを表示
   int visibleRows = MathMin(totalPositions, MAX_VISIBLE_ROWS);
   DisplayPositionRows(tablePrefix, adjustedTableX, adjustedTableY, allPositions, visibleRows, positions);
   
   // 合計損益を表示
   DisplayTotalProfit(tablePrefix, adjustedTableX, adjustedTableY, visibleRows, positions);
   
   // 背景のサイズを調整
   UpdateTableBackground(tablePrefix, TITLE_HEIGHT + TABLE_ROW_HEIGHT * (visibleRows + 2));
   
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| 既存の行を削除 (MQL4/MQL5共通)                                   |
//+------------------------------------------------------------------+
void DeleteTableRows(string tablePrefix)
{
   int total = ObjectsTotal();
   for(int i = total - 1; i >= 0; i--)
   {
      if(i >= ObjectsTotal()) continue; // 安全チェック
      
      string name = ObjectName(i);
      if(StringFind(name, tablePrefix + "Row_") == 0)
      {
         ObjectDelete(name);
      }
   }
}

//+------------------------------------------------------------------+
//| すべてのポジション情報を収集 (MQL4/MQL5共通)                     |
//+------------------------------------------------------------------+
int CollectAllPositions(PositionInfo &allPositions[])
{
   // ゴーストポジションの数
   int totalGhostPositions = g_GhostBuyCount + g_GhostSellCount;
   
   // リアル注文の数をカウント
   int realBuyCount = 0;
   int realSellCount = 0;
   
   // リアル注文を数える
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(PositionSelectByTicket(PositionGetTicket(i)))
      {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) realBuyCount++;
            if(PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) realSellCount++;
         }
      }
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
            if(OrderType() == OP_BUY) realBuyCount++;
            if(OrderType() == OP_SELL) realSellCount++;
         }
      }
   }
#endif
   
   // 全ポジション数を計算
   int totalPositions = totalGhostPositions + realBuyCount + realSellCount;
   ArrayResize(allPositions, totalPositions);
   
   int index = 0;
   
   // Buy ゴーストポジションをコピー
   for(int i = 0; i < g_GhostBuyCount; i++)
   {
      allPositions[index] = g_GhostBuyPositions[i];
      index++;
   }
   
   // Sell ゴーストポジションをコピー
   for(int i = 0; i < g_GhostSellCount; i++)
   {
      allPositions[index] = g_GhostSellPositions[i];
      index++;
   }
   
   // リアル注文を追加
   AddRealPositions(allPositions, index);
   
   // ポジションをソート
   SortPositions(allPositions, totalPositions);
   
   return totalPositions;
}

//+------------------------------------------------------------------+
//| リアルポジションを追加 (MQL4/MQL5共通)                           |
//+------------------------------------------------------------------+
void AddRealPositions(PositionInfo &allPositions[], int &index)
{
#ifdef __MQL5__
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(PositionSelectByTicket(ticket))
      {
         if(PositionGetString(POSITION_SYMBOL) == Symbol() && 
            PositionGetInteger(POSITION_MAGIC) == MagicNumber)
         {
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
            
            allPositions[index++] = pos;
         }
      }
   }
#else
   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
      {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber)
         {
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
            
            allPositions[index++] = pos;
         }
      }
   }
#endif
}

//+------------------------------------------------------------------+
//| ポジションをソート (MQL4/MQL5共通)                               |
//+------------------------------------------------------------------+
void SortPositions(PositionInfo &positions[], int count)
{
   // レベルを計算
   CalculatePositionLevels(positions, count);
   
   // ロット数でソート（バブルソート）
   for(int i = 0; i < count - 1; i++)
   {
      for(int j = 0; j < count - i - 1; j++)
      {
         bool swap = false;
         
         // まずタイプでグループ化（Buy -> Sell）
         if(positions[j].type > positions[j+1].type)
         {
            swap = true;
         }
         // 同じタイプ内では、ゴースト -> リアルの順
         else if(positions[j].type == positions[j+1].type)
         {
            if(!positions[j].isGhost && positions[j+1].isGhost)
            {
               swap = true;
            }
            // 同じカテゴリ内ではロット数の昇順
            else if(positions[j].isGhost == positions[j+1].isGhost)
            {
               if(positions[j].lots > positions[j+1].lots)
               {
                  swap = true;
               }
            }
         }
         
         if(swap)
         {
            PositionInfo temp = positions[j];
            positions[j] = positions[j+1];
            positions[j+1] = temp;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| ポジションレベルを計算 (MQL4/MQL5共通)                           |
//+------------------------------------------------------------------+
void CalculatePositionLevels(PositionInfo &positions[], int count)
{
   for(int i = 0; i < count; i++)
   {
      if(positions[i].type == OP_BUY)
      {
         int orderRank = 1;
         for(int j = 0; j < count; j++)
         {
            if(positions[j].type == OP_BUY)
            {
               if(positions[j].openTime < positions[i].openTime)
               {
                  orderRank++;
               }
            }
         }
         positions[i].level = orderRank - 1;
      }
      else
      {
         int orderRank = 1;
         for(int j = 0; j < count; j++)
         {
            if(positions[j].type == OP_SELL)
            {
               if(positions[j].openTime < positions[i].openTime)
               {
                  orderRank++;
               }
            }
         }
         positions[i].level = orderRank - 1;
      }
   }
}

//+------------------------------------------------------------------+
//| データなしメッセージを表示 (MQL4/MQL5共通)                       |
//+------------------------------------------------------------------+
void DisplayNoDataMessage(string tablePrefix, int x, int y)
{
   string noDataName = tablePrefix + "Row_NoData";
   
#ifdef __MQL5__
   ObjectCreate(0, noDataName, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, noDataName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, noDataName, OBJPROP_XDISTANCE, x + 10);
   ObjectSetInteger(0, noDataName, OBJPROP_YDISTANCE, y + TITLE_HEIGHT + TABLE_ROW_HEIGHT + 10);
   ObjectSetString(0, noDataName, OBJPROP_TEXT, "No positions");
   ObjectSetString(0, noDataName, OBJPROP_FONT, "MS Gothic");
   ObjectSetInteger(0, noDataName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, noDataName, OBJPROP_COLOR, TABLE_TEXT_COLOR);
   ObjectSetInteger(0, noDataName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, noDataName, OBJPROP_ZORDER, 2);
#else
   ObjectCreate(noDataName, OBJ_LABEL, 0, 0, 0);
   ObjectSet(noDataName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(noDataName, OBJPROP_XDISTANCE, x + 10);
   ObjectSet(noDataName, OBJPROP_YDISTANCE, y + TITLE_HEIGHT + TABLE_ROW_HEIGHT + 10);
   ObjectSetText(noDataName, "No positions", 8, "MS Gothic", TABLE_TEXT_COLOR);
   ObjectSet(noDataName, OBJPROP_SELECTABLE, false);
#endif
   
   SaveObjectName(noDataName, g_TableNames, g_TableObjectCount);
}

//+------------------------------------------------------------------+
//| ポジション行を表示 (MQL4/MQL5共通)                               |
//+------------------------------------------------------------------+
void DisplayPositionRows(string tablePrefix, int x, int y, PositionInfo &positions[], 
                        int visibleRows, int &columnPositions[])
{
   for(int i = 0; i < visibleRows; i++)
   {
      int rowY = y + TITLE_HEIGHT + TABLE_ROW_HEIGHT * (i + 1);
      color rowBg = (i % 2 == 0) ? TABLE_ROW_BG1 : TABLE_ROW_BG2;
      
      // 行の背景
      CreateRowBackground(tablePrefix, i, x, rowY, rowBg);
      
      // 行のデータ
      DisplayRowData(tablePrefix, i, x, rowY, positions[i], columnPositions);
   }
}

//+------------------------------------------------------------------+
//| 行の背景を作成 (MQL4/MQL5共通)                                   |
//+------------------------------------------------------------------+
void CreateRowBackground(string tablePrefix, int row, int x, int y, color bgColor)
{
   string rowBgName = tablePrefix + "Row_" + IntegerToString(row) + "_BG";
   
#ifdef __MQL5__
   ObjectCreate(0, rowBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, rowBgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, rowBgName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, rowBgName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, rowBgName, OBJPROP_XSIZE, TABLE_WIDTH);
   ObjectSetInteger(0, rowBgName, OBJPROP_YSIZE, TABLE_ROW_HEIGHT);
   ObjectSetInteger(0, rowBgName, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, rowBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, rowBgName, OBJPROP_COLOR, bgColor);
   ObjectSetInteger(0, rowBgName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, rowBgName, OBJPROP_BACK, false);
   ObjectSetInteger(0, rowBgName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, rowBgName, OBJPROP_ZORDER, 1);
#else
   ObjectCreate(rowBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(rowBgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(rowBgName, OBJPROP_XDISTANCE, x);
   ObjectSet(rowBgName, OBJPROP_YDISTANCE, y);
   ObjectSet(rowBgName, OBJPROP_XSIZE, TABLE_WIDTH);
   ObjectSet(rowBgName, OBJPROP_YSIZE, TABLE_ROW_HEIGHT);
   ObjectSet(rowBgName, OBJPROP_BGCOLOR, bgColor);
   ObjectSet(rowBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(rowBgName, OBJPROP_COLOR, bgColor);
   ObjectSet(rowBgName, OBJPROP_WIDTH, 1);
   ObjectSet(rowBgName, OBJPROP_BACK, false);
   ObjectSet(rowBgName, OBJPROP_SELECTABLE, false);
#endif
   
   SaveObjectName(rowBgName, g_TableNames, g_TableObjectCount);
}

//+------------------------------------------------------------------+
//| 行のデータを表示 (MQL4/MQL5共通)                                 |
//+------------------------------------------------------------------+
void DisplayRowData(string tablePrefix, int row, int x, int y, PositionInfo &pos, int &positions[])
{
   string rowPrefix = tablePrefix + "Row_" + IntegerToString(row);
   color textColorToUse = pos.isGhost ? TABLE_GHOST_COLOR : TABLE_TEXT_COLOR;
   
   // No.
   CreateTableCell(rowPrefix + "_No", IntegerToString(row + 1), x + positions[0], y + 4, textColorToUse);
   
   // Type
   string typeText = (pos.type == OP_BUY) ? "Buy" : "Sell";
   if(pos.isGhost) typeText = "G " + typeText;
   
   color typeColor = (pos.type == OP_BUY) ? TABLE_BUY_COLOR : TABLE_SELL_COLOR;
   if(pos.isGhost)
   {
      typeColor = (pos.type == OP_BUY) ? 
                  ColorDarken(TABLE_BUY_COLOR, 60) : ColorDarken(TABLE_SELL_COLOR, 60);
   }
   
   CreateTableCell(rowPrefix + "_Type", typeText, x + positions[1], y + 4, typeColor);
   
   // Lots
   CreateTableCell(rowPrefix + "_Lots", DoubleToString(pos.lots, 2), x + positions[2], y + 4, textColorToUse);
   
   // Symbol
   CreateTableCell(rowPrefix + "_Symbol", pos.symbol, x + positions[3], y + 4, textColorToUse);
   
   // Price
   string priceStr = FormatPrice(pos.symbol, pos.price);
   CreateTableCell(rowPrefix + "_Price", priceStr, x + positions[4], y + 4, textColorToUse);
   
   // OpenTime
   string timeStr = TimeToString(pos.openTime, TIME_DATE|TIME_MINUTES);
   CreateTableCell(rowPrefix + "_OpenTime", timeStr, x + positions[5], y + 4, textColorToUse);
   
   // Level
   CreateTableCell(rowPrefix + "_Level", IntegerToString(pos.level + 1), x + positions[6], y + 4, textColorToUse);
   
   // Profit
   double profit = CalculatePositionProfit(pos);
   color profitColor = profit >= 0 ? clrLime : clrRed;
   if(pos.isGhost)
   {
      profitColor = profit >= 0 ? clrForestGreen : clrFireBrick;
   }
   
   CreateTableCell(rowPrefix + "_Profit", DoubleToStr(profit, 2), x + positions[7], y + 4, profitColor);
}

//+------------------------------------------------------------------+
//| テーブルセルを作成 (MQL4/MQL5共通)                               |
//+------------------------------------------------------------------+
void CreateTableCell(string name, string text, int x, int y, color textColor)
{
#ifdef __MQL5__
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "MS Gothic");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 3);
#else
   ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
   ObjectSet(name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(name, OBJPROP_XDISTANCE, x);
   ObjectSet(name, OBJPROP_YDISTANCE, y);
   ObjectSetText(name, text, 8, "MS Gothic", textColor);
   ObjectSet(name, OBJPROP_SELECTABLE, false);
#endif
   
   SaveObjectName(name, g_TableNames, g_TableObjectCount);
}

//+------------------------------------------------------------------+
//| 価格をフォーマット (MQL4/MQL5共通)                               |
//+------------------------------------------------------------------+
string FormatPrice(string symbol, double price)
{
   if(StringFind(symbol, "JPY") >= 0)
      return DoubleToString(price, 3);
   else if(StringFind(symbol, "XAU") >= 0)
      return DoubleToString(price, 2);
   else
      return DoubleToString(price, 5);
}

//+------------------------------------------------------------------+
//| ポジション損益を計算 (MQL4/MQL5共通)                             |
//+------------------------------------------------------------------+
double CalculatePositionProfit(PositionInfo &pos)
{
   if(pos.isGhost)
   {
      // ゴーストの場合は仮想損益を計算
      double currentPrice = (pos.type == OP_BUY) ? GetBidPrice() : GetAskPrice();
      double tickValue = 0;
      
#ifdef __MQL5__
      tickValue = SymbolInfoDouble(Symbol(), SYMBOL_TRADE_TICK_VALUE);
#else
      tickValue = MarketInfo(Symbol(), MODE_TICKVALUE);
#endif
      
      if(pos.type == OP_BUY)
      {
         return (currentPrice - pos.price) * pos.lots * tickValue / Point;
      }
      else
      {
         return (pos.price - currentPrice) * pos.lots * tickValue / Point;
      }
   }
   else
   {
      // リアルポジションの場合は実際の損益を取得
#ifdef __MQL5__
      if(PositionSelectByTicket(pos.ticket))
      {
         return PositionGetDouble(POSITION_PROFIT) + PositionGetDouble(POSITION_SWAP);
      }
#else
      for(int i = OrdersTotal() - 1; i >= 0; i--)
      {
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES))
         {
            if(OrderTicket() == pos.ticket)
            {
               return OrderProfit() + OrderSwap() + OrderCommission();
            }
         }
      }
#endif
   }
   
   return 0;
}

//+------------------------------------------------------------------+
//| 合計損益を表示 (MQL4/MQL5共通)                                   |
//+------------------------------------------------------------------+
void DisplayTotalProfit(string tablePrefix, int x, int y, int visibleRows, int &positions[])
{
   // 合計損益の計算
   double totalBuyProfit = CalculateCombinedProfit(OP_BUY);
   double totalSellProfit = CalculateCombinedProfit(OP_SELL);
   double totalProfit = totalBuyProfit + totalSellProfit;
   
   int totalRowY = y + TITLE_HEIGHT + TABLE_ROW_HEIGHT * (visibleRows + 1);
   
   // 合計行の背景
   CreateRowBackground(tablePrefix + "_Total", 0, x, totalRowY, C'48,48,64');
   
   // 合計テキスト
   CreateTableCell(tablePrefix + "Row_Total_Text", "TOTAL:", x + positions[0], totalRowY + 4, TABLE_TEXT_COLOR);
   
   // Buy合計
   color buyColor = totalBuyProfit >= 0 ? clrLime : clrRed;
   CreateTableCell(tablePrefix + "Row_BuyTotal", "BUY: " + DoubleToStr(totalBuyProfit, 2), 
                   x + positions[2], totalRowY + 4, buyColor);
   
   // Sell合計
   color sellColor = totalSellProfit >= 0 ? clrLime : clrRed;
   CreateTableCell(tablePrefix + "Row_SellTotal", "SELL: " + DoubleToStr(totalSellProfit, 2),
                   x + positions[4], totalRowY + 4, sellColor);
   
   // 総合計
   color totalColor = totalProfit >= 0 ? clrLime : clrRed;
   CreateTableCell(tablePrefix + "Row_NetTotal", "NET: " + DoubleToStr(totalProfit, 2),
                   x + positions[7], totalRowY + 4, totalColor);
}

//+------------------------------------------------------------------+
//| テーブル背景を更新 (MQL4/MQL5共通)                               |
//+------------------------------------------------------------------+
void UpdateTableBackground(string tablePrefix, int height)
{
   string bgName = tablePrefix + "BG";
   
   if(ObjectFind(bgName) >= 0)
   {
#ifdef __MQL5__
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE, height);
#else
      ObjectSet(bgName, OBJPROP_YSIZE, height);
#endif
   }
}

//+------------------------------------------------------------------+
//| ポジションテーブルを削除する (MQL4/MQL5共通)                     |
//+------------------------------------------------------------------+
void DeletePositionTable()
{
   for(int i = 0; i < g_TableObjectCount; i++)
   {
      if(ObjectFind(g_TableNames[i]) >= 0)
         ObjectDelete(g_TableNames[i]);
   }
   
   g_TableObjectCount = 0;
   ChartRedraw();
}