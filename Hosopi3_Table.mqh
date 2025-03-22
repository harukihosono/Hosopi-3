//+------------------------------------------------------------------+
//|                Hosopi 3 - テーブル表示関数                        |
//|                       Copyright 2025                             |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_Ghost.mqh"

//+------------------------------------------------------------------+
//| ポジションテーブルを作成する - テーブルセル位置修正版              |
//+------------------------------------------------------------------+
void CreatePositionTable()
{
   DeletePositionTable(); // 既存のテーブルを削除
   g_TableObjectCount = 0;
   
   // ヘッダー列のラベルと位置の修正
   // 列の幅を明確に定義し、一貫した間隔で配置
   string headers[8] = {"No", "Type", "Lots", "Symbol", "Price", "OpenTime", "Level", "Profit"};
   int columnWidths[8] = {25, 45, 45, 90, 95, 140, 45, 90}; // 各列の幅
   int positions[8]; // 各列の開始位置
   
   // 各列の開始位置を計算
   positions[0] = 5; // 最初の列は少し余白を取る
   for(int i = 1; i < 8; i++) {
      positions[i] = positions[i-1] + columnWidths[i-1];
   }
   
   // パネル位置の調整を考慮したテーブル位置
   int adjustedPanelY = PanelY;
   int adjustedGhostTableX = PanelX;
   int adjustedGhostTableY = adjustedPanelY + 600; // テーブル位置をさらに下げる
   
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string tablePrefix = g_ObjectPrefix + "GhostTable_";
   
   // 背景の作成
   string bgName = tablePrefix + "BG";
   ObjectCreate(bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(bgName, OBJPROP_XDISTANCE, adjustedGhostTableX);
   ObjectSet(bgName, OBJPROP_YDISTANCE, adjustedGhostTableY);
   ObjectSet(bgName, OBJPROP_XSIZE, TABLE_WIDTH);
   // 最小サイズ（タイトル + ヘッダー + 「No positions」行）
   ObjectSet(bgName, OBJPROP_YSIZE, TITLE_HEIGHT + TABLE_ROW_HEIGHT * 2);
   ObjectSet(bgName, OBJPROP_BGCOLOR, C'16,16,24');
   ObjectSet(bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(bgName, OBJPROP_COLOR, C'64,64,96');
   ObjectSet(bgName, OBJPROP_WIDTH, 1);
   ObjectSet(bgName, OBJPROP_BACK, false);
   ObjectSet(bgName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, bgName, OBJPROP_ZORDER, 0);
   
   // タイトル背景
   string titleBgName = tablePrefix + "TitleBG";
   ObjectCreate(titleBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(titleBgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(titleBgName, OBJPROP_XDISTANCE, adjustedGhostTableX);
   ObjectSet(titleBgName, OBJPROP_YDISTANCE, adjustedGhostTableY);
   ObjectSet(titleBgName, OBJPROP_XSIZE, TABLE_WIDTH);
   ObjectSet(titleBgName, OBJPROP_YSIZE, TITLE_HEIGHT);
   ObjectSet(titleBgName, OBJPROP_BGCOLOR, C'32,32,48');
   ObjectSet(titleBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(titleBgName, OBJPROP_COLOR, C'32,32,48');
   ObjectSet(titleBgName, OBJPROP_WIDTH, 1);
   ObjectSet(titleBgName, OBJPROP_BACK, false);
   ObjectSet(titleBgName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, titleBgName, OBJPROP_ZORDER, 1);
   
   // タイトルテキスト
   string titleName = tablePrefix + "Title";
   ObjectCreate(titleName, OBJ_LABEL, 0, 0, 0);
   ObjectSet(titleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(titleName, OBJPROP_XDISTANCE, adjustedGhostTableX + 10);
   ObjectSet(titleName, OBJPROP_YDISTANCE, adjustedGhostTableY + 3);
   ObjectSetText(titleName, GhostTableTitle, 7, "MS Gothic", TABLE_TEXT_COLOR);
   ObjectSet(titleName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, titleName, OBJPROP_ZORDER, 2);
   
   // ヘッダー背景
   string headerBgName = tablePrefix + "HeaderBG";
   ObjectCreate(headerBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(headerBgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(headerBgName, OBJPROP_XDISTANCE, adjustedGhostTableX);
   ObjectSet(headerBgName, OBJPROP_YDISTANCE, adjustedGhostTableY + TITLE_HEIGHT);
   ObjectSet(headerBgName, OBJPROP_XSIZE, TABLE_WIDTH);
   ObjectSet(headerBgName, OBJPROP_YSIZE, TABLE_ROW_HEIGHT);
   ObjectSet(headerBgName, OBJPROP_BGCOLOR, TABLE_HEADER_BG);
   ObjectSet(headerBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(headerBgName, OBJPROP_COLOR, TABLE_HEADER_BG);
   ObjectSet(headerBgName, OBJPROP_WIDTH, 1);
   ObjectSet(headerBgName, OBJPROP_BACK, false);
   ObjectSet(headerBgName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, headerBgName, OBJPROP_ZORDER, 1);
   
   // ヘッダー列のラベルを作成
   for(int i = 0; i < 8; i++)
   {
      string name = tablePrefix + "Header_" + headers[i];
      ObjectCreate(name, OBJ_LABEL, 0, 0, 0);
      ObjectSet(name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(name, OBJPROP_XDISTANCE, adjustedGhostTableX + positions[i]);
      ObjectSet(name, OBJPROP_YDISTANCE, adjustedGhostTableY + TITLE_HEIGHT + 4);
      ObjectSetText(name, headers[i], 8, "MS Gothic", TABLE_TEXT_COLOR);
      ObjectSet(name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 2);
      
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
//| ポジションテーブルを削除する                                       |
//+------------------------------------------------------------------+
void DeletePositionTable()
{
   for(int i = 0; i < g_TableObjectCount; i++)
   {
      if(ObjectFind(g_TableNames[i]) >= 0)
         ObjectDelete(g_TableNames[i]);
   }
   
   g_TableObjectCount = 0;
   ChartRedraw(); // チャートを再描画
}

//+------------------------------------------------------------------+
//| ポジションテーブルを更新する                                       |
//+------------------------------------------------------------------+
void UpdatePositionTable()
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string tablePrefix = g_ObjectPrefix + "GhostTable_";
   
   // 修正: テーブル位置の調整
   int adjustedPanelY = PanelY;
   int adjustedGhostTableX = PanelX;
   int adjustedGhostTableY = adjustedPanelY + 600; // テーブル位置をさらに下げる
   
   // 列の位置を定義
   int columnWidths[8] = {25, 45, 45, 90, 95, 140, 45, 90}; // 各列の幅
   int positions[8]; // 各列の開始位置
   
   // 各列の開始位置を計算
   positions[0] = 5; // 最初の列は少し余白を取る
   for(int i = 1; i < 8; i++) {
      positions[i] = positions[i-1] + columnWidths[i-1];
   }
   
   // 行オブジェクトをクリア（ヘッダーと背景は残す）
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
   
   // ゴーストポジションの表示
   int totalGhostPositions = g_GhostBuyCount + g_GhostSellCount;
   
   // 一時配列にすべてのポジション(ゴースト+リアル)を結合
   PositionInfo allPositions[];
   
   // リアル注文の数をカウント
   int realBuyCount = 0;
   int realSellCount = 0;
   
   // リアル注文を数える
   for(int i = OrdersTotal() - 1; i >= 0; i--) {
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) {
         if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber) {
            if(OrderType() == OP_BUY) realBuyCount++;
            if(OrderType() == OP_SELL) realSellCount++;
         }
      }
   }
   
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
            
            // レベルを計算（単純にリアル注文の順番）
            int orderCount = 0;
            for(int j = OrdersTotal() - 1; j >= 0; j--) {
               if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
                  if(OrderSymbol() == Symbol() && OrderMagicNumber() == MagicNumber && OrderType() == pos.type) {
                     if(OrderOpenTime() <= pos.openTime) orderCount++;
                  }
               }
            }
            pos.level = orderCount - 1;
            
            allPositions[nextIndex++] = pos;
         }
      }
   }
   
   // データがない場合のメッセージ
   if(totalPositions == 0)
   {
      string noDataName = tablePrefix + "Row_NoData";
      ObjectCreate(noDataName, OBJ_LABEL, 0, 0, 0);
      ObjectSet(noDataName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(noDataName, OBJPROP_XDISTANCE, adjustedGhostTableX + 10);
      ObjectSet(noDataName, OBJPROP_YDISTANCE, adjustedGhostTableY + TITLE_HEIGHT + TABLE_ROW_HEIGHT + 10);
      ObjectSetText(noDataName, "No positions", 8, "MS Gothic", TABLE_TEXT_COLOR);
      ObjectSet(noDataName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, noDataName, OBJPROP_ZORDER, 2);
      
      // オブジェクト名を保存
      SaveObjectName(noDataName, g_TableNames, g_TableObjectCount);
      
      // 背景のサイズを最小化
      string bgName = tablePrefix + "BG";
      if(ObjectFind(bgName) >= 0)
      {
         ObjectSet(bgName, OBJPROP_YSIZE, TITLE_HEIGHT + TABLE_ROW_HEIGHT * 2);
      }
      
      ChartRedraw();
      return;
   }
   
   // 表示する最大行数を計算
   int visibleRows = MathMin(totalPositions, MAX_VISIBLE_ROWS);
   
   // 各行のテーブルデータを表示
   for(int i = 0; i < visibleRows; i++)
   {
      // 行の位置計算 - ヘッダーの下から順に配置
      int rowY = adjustedGhostTableY + TITLE_HEIGHT + TABLE_ROW_HEIGHT * (i + 1);
      color rowBg = (i % 2 == 0) ? TABLE_ROW_BG1 : TABLE_ROW_BG2;
      
      // 行の背景
      string rowBgName = tablePrefix + "Row_" + IntegerToString(i) + "_BG";
      ObjectCreate(rowBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSet(rowBgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(rowBgName, OBJPROP_XDISTANCE, adjustedGhostTableX);
      ObjectSet(rowBgName, OBJPROP_YDISTANCE, rowY);
      ObjectSet(rowBgName, OBJPROP_XSIZE, TABLE_WIDTH);
      ObjectSet(rowBgName, OBJPROP_YSIZE, TABLE_ROW_HEIGHT);
      ObjectSet(rowBgName, OBJPROP_BGCOLOR, rowBg);
      ObjectSet(rowBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSet(rowBgName, OBJPROP_COLOR, rowBg);
      ObjectSet(rowBgName, OBJPROP_WIDTH, 1);
      ObjectSet(rowBgName, OBJPROP_BACK, false);
      ObjectSet(rowBgName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, rowBgName, OBJPROP_ZORDER, 1);
      
      // ゴーストかリアルかで文字色を決定
      color textColorToUse = allPositions[i].isGhost ? TABLE_GHOST_COLOR : TABLE_TEXT_COLOR;
      
      // No.
      string noName = tablePrefix + "Row_" + IntegerToString(i) + "_No";
      ObjectCreate(noName, OBJ_LABEL, 0, 0, 0);
      ObjectSet(noName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(noName, OBJPROP_XDISTANCE, adjustedGhostTableX + positions[0]);
      ObjectSet(noName, OBJPROP_YDISTANCE, rowY + 4);
      ObjectSetText(noName, IntegerToString(i+1), 8, "MS Gothic", textColorToUse);
      ObjectSet(noName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, noName, OBJPROP_ZORDER, 3);
      
      // Type
      string typeText = (allPositions[i].type == OP_BUY) ? "Buy" : "Sell";
      
      // タイプがGhostの場合はGhostであることを示す
      if(allPositions[i].isGhost) {
         typeText = "G " + typeText; // G for Ghost
      }
      
      color typeColor = (allPositions[i].type == OP_BUY) ? TABLE_BUY_COLOR : TABLE_SELL_COLOR;
      if(allPositions[i].isGhost) {
         // ゴーストの場合は少し暗い色に
         typeColor = (allPositions[i].type == OP_BUY) ? 
                     ColorDarken(TABLE_BUY_COLOR, 60) : ColorDarken(TABLE_SELL_COLOR, 60);
      }
      
      string typeName = tablePrefix + "Row_" + IntegerToString(i) + "_Type";
      ObjectCreate(typeName, OBJ_LABEL, 0, 0, 0);
      ObjectSet(typeName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(typeName, OBJPROP_XDISTANCE, adjustedGhostTableX + positions[1]);
      ObjectSet(typeName, OBJPROP_YDISTANCE, rowY + 4);
      ObjectSetText(typeName, typeText, 8, "MS Gothic", typeColor);
      ObjectSet(typeName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, typeName, OBJPROP_ZORDER, 3);
      
      // Lots
      string lotsName = tablePrefix + "Row_" + IntegerToString(i) + "_Lots";
      ObjectCreate(lotsName, OBJ_LABEL, 0, 0, 0);
      ObjectSet(lotsName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(lotsName, OBJPROP_XDISTANCE, adjustedGhostTableX + positions[2]);
      ObjectSet(lotsName, OBJPROP_YDISTANCE, rowY + 4);
      ObjectSetText(lotsName, DoubleToString(allPositions[i].lots, 2), 8, "MS Gothic", textColorToUse);
      ObjectSet(lotsName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, lotsName, OBJPROP_ZORDER, 3);
      
      // Symbol
      string symbolName = tablePrefix + "Row_" + IntegerToString(i) + "_Symbol";
      ObjectCreate(symbolName, OBJ_LABEL, 0, 0, 0);
      ObjectSet(symbolName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(symbolName, OBJPROP_XDISTANCE, adjustedGhostTableX + positions[3]);
      ObjectSet(symbolName, OBJPROP_YDISTANCE, rowY + 4);
      ObjectSetText(symbolName, allPositions[i].symbol, 8, "MS Gothic", textColorToUse);
      ObjectSet(symbolName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, symbolName, OBJPROP_ZORDER, 3);
      
      // Price
      string priceStr = "";
      if(StringFind(allPositions[i].symbol, "JPY") >= 0)
         priceStr = DoubleToString(allPositions[i].price, 3);
      else if(StringFind(allPositions[i].symbol, "XAU") >= 0)
         priceStr = DoubleToString(allPositions[i].price, 2);
      else
         priceStr = DoubleToString(allPositions[i].price, 5);
         
      string priceName = tablePrefix + "Row_" + IntegerToString(i) + "_Price";
      ObjectCreate(priceName, OBJ_LABEL, 0, 0, 0);
      ObjectSet(priceName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(priceName, OBJPROP_XDISTANCE, adjustedGhostTableX + positions[4]);
      ObjectSet(priceName, OBJPROP_YDISTANCE, rowY + 4);
      ObjectSetText(priceName, priceStr, 8, "MS Gothic", textColorToUse);
      ObjectSet(priceName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, priceName, OBJPROP_ZORDER, 3);
      
      // OpenTime
      string timeStr = TimeToString(allPositions[i].openTime, TIME_DATE|TIME_MINUTES);
      string timeName = tablePrefix + "Row_" + IntegerToString(i) + "_OpenTime";
      ObjectCreate(timeName, OBJ_LABEL, 0, 0, 0);
      ObjectSet(timeName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(timeName, OBJPROP_XDISTANCE, adjustedGhostTableX + positions[5]);
      ObjectSet(timeName, OBJPROP_YDISTANCE, rowY + 4);
      ObjectSetText(timeName, timeStr, 8, "MS Gothic", textColorToUse);
      ObjectSet(timeName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, timeName, OBJPROP_ZORDER, 3);
      
      // Level
      string levelName = tablePrefix + "Row_" + IntegerToString(i) + "_Level";
      ObjectCreate(levelName, OBJ_LABEL, 0, 0, 0);
      ObjectSet(levelName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(levelName, OBJPROP_XDISTANCE, adjustedGhostTableX + positions[6]);
      ObjectSet(levelName, OBJPROP_YDISTANCE, rowY + 4);
      ObjectSetText(levelName, IntegerToString(allPositions[i].level + 1), 8, "MS Gothic", textColorToUse);
      ObjectSet(levelName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, levelName, OBJPROP_ZORDER, 3);
      
      // Profit
      string profitName = tablePrefix + "Row_" + IntegerToString(i) + "_Profit";
      ObjectCreate(profitName, OBJ_LABEL, 0, 0, 0);
      ObjectSet(profitName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(profitName, OBJPROP_XDISTANCE, adjustedGhostTableX + positions[7]);
      ObjectSet(profitName, OBJPROP_YDISTANCE, rowY + 4);
      
      // 損益の計算
      double profit = 0;
      if(allPositions[i].isGhost) {
         // ゴーストの場合は仮想損益を計算
         if(allPositions[i].type == OP_BUY) {
            profit = (GetBidPrice() - allPositions[i].price) * allPositions[i].lots * MarketInfo(Symbol(), MODE_TICKVALUE) / Point;
         } else {
            profit = (allPositions[i].price - GetAskPrice()) * allPositions[i].lots * MarketInfo(Symbol(), MODE_TICKVALUE) / Point;
         }
      } else {
         // リアルポジションの場合は実際の損益を取得
         for(int j = OrdersTotal() - 1; j >= 0; j--) {
            if(OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) {
               if(OrderTicket() == allPositions[i].ticket) {
                  profit = OrderProfit() + OrderSwap() + OrderCommission();
                  break;
               }
            }
         }
      }
      
      // 損益表示の色
      color profitColor = profit >= 0 ? clrLime : clrRed;
      if(allPositions[i].isGhost) {
         // ゴーストの場合は暗い色に
         profitColor = profit >= 0 ? clrForestGreen : clrFireBrick;
      }
      
      ObjectSetText(profitName, DoubleToStr(profit, 2) + "", 8, "MS Gothic", profitColor);
      ObjectSet(profitName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, profitName, OBJPROP_ZORDER, 3);
      
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
   ObjectCreate(totalRowBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(totalRowBgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(totalRowBgName, OBJPROP_XDISTANCE, adjustedGhostTableX);
   ObjectSet(totalRowBgName, OBJPROP_YDISTANCE, adjustedGhostTableY + TITLE_HEIGHT + TABLE_ROW_HEIGHT * (visibleRows + 1));
   ObjectSet(totalRowBgName, OBJPROP_XSIZE, TABLE_WIDTH);
   ObjectSet(totalRowBgName, OBJPROP_YSIZE, TABLE_ROW_HEIGHT);
   ObjectSet(totalRowBgName, OBJPROP_BGCOLOR, C'48,48,64');
   ObjectSet(totalRowBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(totalRowBgName, OBJPROP_COLOR, C'48,48,64');
   ObjectSet(totalRowBgName, OBJPROP_WIDTH, 1);
   ObjectSet(totalRowBgName, OBJPROP_BACK, false);
   ObjectSet(totalRowBgName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, totalRowBgName, OBJPROP_ZORDER, 1);
   
   // 合計テキスト
   string totalTextName = tablePrefix + "Row_Total_Text";
   ObjectCreate(totalTextName, OBJ_LABEL, 0, 0, 0);
   ObjectSet(totalTextName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(totalTextName, OBJPROP_XDISTANCE, adjustedGhostTableX + positions[0]);
   ObjectSet(totalTextName, OBJPROP_YDISTANCE, adjustedGhostTableY + TITLE_HEIGHT + TABLE_ROW_HEIGHT * (visibleRows + 1) + 4);
   ObjectSetText(totalTextName, "TOTAL:", 8, "MS Gothic Bold", TABLE_TEXT_COLOR);
// 合計テキストの続き
ObjectSet(totalTextName, OBJPROP_SELECTABLE, false);
ObjectSetInteger(0, totalTextName, OBJPROP_ZORDER, 3);

// Buy合計
string buyTotalName = tablePrefix + "Row_BuyTotal";
ObjectCreate(buyTotalName, OBJ_LABEL, 0, 0, 0);
ObjectSet(buyTotalName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
ObjectSet(buyTotalName, OBJPROP_XDISTANCE, adjustedGhostTableX + positions[2]);
ObjectSet(buyTotalName, OBJPROP_YDISTANCE, adjustedGhostTableY + TITLE_HEIGHT + TABLE_ROW_HEIGHT * (visibleRows + 1) + 4);
color buyColor = totalBuyProfit >= 0 ? clrLime : clrRed;
ObjectSetText(buyTotalName, "BUY: " + DoubleToStr(totalBuyProfit, 2) + "", 8, "MS Gothic", buyColor);
ObjectSet(buyTotalName, OBJPROP_SELECTABLE, false);
ObjectSetInteger(0, buyTotalName, OBJPROP_ZORDER, 3);

// Sell合計
string sellTotalName = tablePrefix + "Row_SellTotal";
ObjectCreate(sellTotalName, OBJ_LABEL, 0, 0, 0);
ObjectSet(sellTotalName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
ObjectSet(sellTotalName, OBJPROP_XDISTANCE, adjustedGhostTableX + positions[4]);
ObjectSet(sellTotalName, OBJPROP_YDISTANCE, adjustedGhostTableY + TITLE_HEIGHT + TABLE_ROW_HEIGHT * (visibleRows + 1) + 4);
color sellColor = totalSellProfit >= 0 ? clrLime : clrRed;
ObjectSetText(sellTotalName, "SELL: " +DoubleToStr(totalSellProfit, 2) + "", 8, "MS Gothic", sellColor);
ObjectSet(sellTotalName, OBJPROP_SELECTABLE, false);
ObjectSetInteger(0, sellTotalName, OBJPROP_ZORDER, 3);

// 総合計
string netTotalName = tablePrefix + "Row_NetTotal";
ObjectCreate(netTotalName, OBJ_LABEL, 0, 0, 0);
ObjectSet(netTotalName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
ObjectSet(netTotalName, OBJPROP_XDISTANCE, adjustedGhostTableX + positions[7]);
ObjectSet(netTotalName, OBJPROP_YDISTANCE, adjustedGhostTableY + TITLE_HEIGHT + TABLE_ROW_HEIGHT * (visibleRows + 1) + 4);
color totalColor = totalProfit >= 0 ? clrLime : clrRed;
ObjectSetText(netTotalName, "NET: " + DoubleToStr(totalProfit, 2) + "", 8, "MS Gothic Bold", totalColor);
ObjectSet(netTotalName, OBJPROP_SELECTABLE, false);
ObjectSetInteger(0, netTotalName, OBJPROP_ZORDER, 3);

// オブジェクト名を保存
SaveObjectName(totalRowBgName, g_TableNames, g_TableObjectCount);
SaveObjectName(totalTextName, g_TableNames, g_TableObjectCount);
SaveObjectName(buyTotalName, g_TableNames, g_TableObjectCount);
SaveObjectName(sellTotalName, g_TableNames, g_TableObjectCount);
SaveObjectName(netTotalName, g_TableNames, g_TableObjectCount);

// 背景のサイズを調整
string bgName = tablePrefix + "BG";
if(ObjectFind(bgName) >= 0)
{
   int bgHeight = TITLE_HEIGHT + TABLE_ROW_HEIGHT * (visibleRows + 2);
   ObjectSet(bgName, OBJPROP_YSIZE, bgHeight);
}

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
ObjectCreate(bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
ObjectSet(bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
ObjectSet(bgName, OBJPROP_XDISTANCE, legendX);
ObjectSet(bgName, OBJPROP_YDISTANCE, legendY);
ObjectSet(bgName, OBJPROP_XSIZE, legendWidth);
ObjectSet(bgName, OBJPROP_YSIZE, legendHeight);
ObjectSet(bgName, OBJPROP_BGCOLOR, C'16,16,24');
ObjectSet(bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
ObjectSet(bgName, OBJPROP_COLOR, C'64,64,96');
ObjectSet(bgName, OBJPROP_WIDTH, 1);
ObjectSet(bgName, OBJPROP_BACK, false);
ObjectSet(bgName, OBJPROP_SELECTABLE, false);

// タイトル背景
string titleBgName = tablePrefix + "TitleBG";
ObjectCreate(titleBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
ObjectSet(titleBgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
ObjectSet(titleBgName, OBJPROP_XDISTANCE, legendX);
ObjectSet(titleBgName, OBJPROP_YDISTANCE, legendY);
ObjectSet(titleBgName, OBJPROP_XSIZE, legendWidth);
ObjectSet(titleBgName, OBJPROP_YSIZE, rowHeight);
ObjectSet(titleBgName, OBJPROP_BGCOLOR, C'32,32,48');
ObjectSet(titleBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
ObjectSet(titleBgName, OBJPROP_COLOR, C'32,32,48');
ObjectSet(titleBgName, OBJPROP_WIDTH, 1);
ObjectSet(titleBgName, OBJPROP_BACK, false);
ObjectSet(titleBgName, OBJPROP_SELECTABLE, false);

// タイトルテキスト
string titleName = tablePrefix + "Title";
ObjectCreate(titleName, OBJ_LABEL, 0, 0, 0);
ObjectSet(titleName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
ObjectSet(titleName, OBJPROP_XDISTANCE, legendX + 10);
ObjectSet(titleName, OBJPROP_YDISTANCE, legendY + 4);
ObjectSetText(titleName, "Legend", 8, "Arial Bold", TABLE_TEXT_COLOR);
ObjectSet(titleName, OBJPROP_SELECTABLE, false);

// 凡例項目
string items[4];
color itemColors[4];

// 配列の初期化を別途行う（定数式による初期化ではなく、実行時に値を設定）
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
   ObjectCreate(rowBgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(rowBgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(rowBgName, OBJPROP_XDISTANCE, legendX);
   ObjectSet(rowBgName, OBJPROP_YDISTANCE, legendY + rowHeight * (i + 1));
   ObjectSet(rowBgName, OBJPROP_XSIZE, legendWidth);
   ObjectSet(rowBgName, OBJPROP_YSIZE, rowHeight);
   ObjectSet(rowBgName, OBJPROP_BGCOLOR, (i % 2 == 0) ? TABLE_ROW_BG1 : TABLE_ROW_BG2);
   ObjectSet(rowBgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(rowBgName, OBJPROP_COLOR, (i % 2 == 0) ? TABLE_ROW_BG1 : TABLE_ROW_BG2);
   ObjectSet(rowBgName, OBJPROP_WIDTH, 1);
   ObjectSet(rowBgName, OBJPROP_BACK, false);
   ObjectSet(rowBgName, OBJPROP_SELECTABLE, false);
   
   // 色サンプル
   string colorBoxName = tablePrefix + "Row" + IntegerToString(i) + "_Color";
   ObjectCreate(colorBoxName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(colorBoxName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(colorBoxName, OBJPROP_XDISTANCE, legendX + 10);
   ObjectSet(colorBoxName, OBJPROP_YDISTANCE, legendY + rowHeight * (i + 1) + 4);
   ObjectSet(colorBoxName, OBJPROP_XSIZE, 12);
   ObjectSet(colorBoxName, OBJPROP_YSIZE, 12);
   ObjectSet(colorBoxName, OBJPROP_BGCOLOR, itemColors[i]);
   ObjectSet(colorBoxName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(colorBoxName, OBJPROP_COLOR, itemColors[i]);
   ObjectSet(colorBoxName, OBJPROP_WIDTH, 1);
   ObjectSet(colorBoxName, OBJPROP_BACK, false);
   ObjectSet(colorBoxName, OBJPROP_SELECTABLE, false);
   
   // テキスト
   string textName = tablePrefix + "Row" + IntegerToString(i) + "_Text";
   ObjectCreate(textName, OBJ_LABEL, 0, 0, 0);
   ObjectSet(textName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(textName, OBJPROP_XDISTANCE, legendX + 30);
   ObjectSet(textName, OBJPROP_YDISTANCE, legendY + rowHeight * (i + 1) + 4);
   ObjectSetText(textName, items[i], 8, "Arial", TABLE_TEXT_COLOR);
   ObjectSet(textName, OBJPROP_SELECTABLE, false);
   
   // オブジェクト名を保存（必要に応じて）
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
details += "Type: " + (pos.type == OP_BUY ? "Buy" : "Sell") + (pos.isGhost ? " (Ghost)" : " (Real)") + "\n";
details += "Symbol: " + pos.symbol + "\n";
details += "Lots: " + DoubleToString(pos.lots, 2) + "\n";
details += "Price: " + DoubleToString(pos.price, Digits) + "\n";
details += "Open Time: " + TimeToString(pos.openTime, TIME_DATE|TIME_SECONDS) + "\n";
details += "Level: " + IntegerToString(pos.level + 1) + "\n";

// 現在値と損益を計算
double currentPrice = (pos.type == OP_BUY) ? GetBidPrice() : GetAskPrice();
double profit = 0;

if(pos.isGhost) {
   // ゴーストの場合は仮想損益を計算
   if(pos.type == OP_BUY) {
      profit = (GetBidPrice() - pos.price) * pos.lots * MarketInfo(Symbol(), MODE_TICKVALUE) / Point;
   } else {
      profit = (pos.price - GetAskPrice()) * pos.lots * MarketInfo(Symbol(), MODE_TICKVALUE) / Point;
   }
} else {
   // リアルポジションの場合は実際の損益を取得
   if(OrderSelect(pos.ticket, SELECT_BY_TICKET)) {
      profit = OrderProfit() + OrderSwap() + OrderCommission();
   }
}

details += "Current Price: " + DoubleToString(currentPrice, Digits) + "\n";
details += "Profit: " + DoubleToString(profit, 2) + "\n";

// 追加の詳細情報（必要に応じて）
if(!pos.isGhost && OrderSelect(pos.ticket, SELECT_BY_TICKET)) {
   details += "Swap: " + DoubleToString(OrderSwap(), 2) + "\n";
   details += "Commission: " + DoubleToString(OrderCommission(), 2) + "\n";
}

// ポップアップウィンドウを表示
string title = "Position Details - " + (pos.type == OP_BUY ? "Buy" : "Sell") + " #" + IntegerToString(index + 1);
int lines = StringFindCount(details, "\n") + 1;
int detailsHeight = lines * rowHeight + padding * 2;

// メッセージボックスとして表示
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