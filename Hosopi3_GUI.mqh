//+------------------------------------------------------------------+
//|                   Hosopi 3 - GUI関連関数                         |
//|                         Copyright 2025                           |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Compat.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_Trading.mqh"
#include "Hosopi3_InfoPanel.mqh"
#include "Hosopi3_Async.mqh"

// 前方宣言（#import不要）

// スタブ実装
void InitializeGhostPosition(int operationType, string comment) 
{
    // 正しい取引価格を設定（リアル取引と同じ価格を使用）
    double price = (operationType == OP_BUY) ? GetAskPrice() : GetBidPrice();
    double lot = InitialLot;
    
    // ゴーストポジション初期化
    
    // ExecuteGhostEntryを使用して矢印描画も実行
    ExecuteGhostEntry(operationType, price, lot, comment, -1);
}
string GetConstantEntryStrategyState()
{
    switch(ConstantEntryStrategy)
    {
        case CONSTANT_ENTRY_DISABLED: return "OFF";
        case CONSTANT_ENTRY_LONG: return "LONG";
        case CONSTANT_ENTRY_SHORT: return "SHORT";
        case CONSTANT_ENTRY_BOTH: return "BOTH";
        default: return "OFF";
    }
}
string GetEvenOddStrategyState() { return "OFF"; }
void UpdateAveragePriceLines(int operationType)
{
   string direction = (operationType == 0) ? "Buy" : "Sell";

   // ポジション・ゴーストカウントの取得
   int positionCount = position_count(operationType);
   int ghostCount = ghost_position_count(operationType);

   // ポジション・ゴーストどちらも無い場合はラインを削除
   if(positionCount <= 0 && ghostCount <= 0) {
      DeleteSpecificLine(operationType);
      return;
   }

   // 平均価格を計算
   double avgPrice = CalculateCombinedAveragePrice(operationType);
   if(avgPrice <= 0) return;

   // 平均価格ラインを表示
   string avgLineName = "AvgPrice" + direction;
   string avgLabelName = "AvgPriceLabel" + direction;

   // 既存ラインがあるかチェック
#ifdef __MQL5__
   bool avgLineExists = (ObjectFind(0, g_ObjectPrefix + avgLineName) >= 0);
#else
   bool avgLineExists = (ObjectFind(g_ObjectPrefix + avgLineName) >= 0);
#endif

   if(avgLineExists) {
      // 既存ラインの価格を更新
#ifdef __MQL5__
      ObjectSetDouble(0, g_ObjectPrefix + avgLineName, OBJPROP_PRICE, avgPrice);
#else
      ObjectSet(g_ObjectPrefix + avgLineName, OBJPROP_PRICE1, avgPrice);
#endif
   } else {
      // 新規ラインを作成
      CreateHorizontalLine(g_ObjectPrefix + avgLineName, avgPrice, AveragePriceLineColor, STYLE_SOLID, 1);
   }

   // 平均価格ラベルを更新/作成
   if(EnablePriceLabels) {
#ifdef __MQL5__
      bool avgLabelExists = (ObjectFind(0, g_ObjectPrefix + avgLabelName) >= 0);
#else
      bool avgLabelExists = (ObjectFind(g_ObjectPrefix + avgLabelName) >= 0);
#endif

      string avgText = "Avg: " + DoubleToString(avgPrice, GetDigitsValue());

      if(avgLabelExists) {
         // 既存ラベルの価格とテキストを更新
#ifdef __MQL5__
         ObjectSetDouble(0, g_ObjectPrefix + avgLabelName, OBJPROP_PRICE, avgPrice);
         ObjectSetString(0, g_ObjectPrefix + avgLabelName, OBJPROP_TEXT, avgText);
#else
         ObjectSet(g_ObjectPrefix + avgLabelName, OBJPROP_PRICE1, avgPrice);
         ObjectSetText(g_ObjectPrefix + avgLabelName, avgText);
#endif
      } else {
         // 新規ラベルを作成
         CreatePriceLabel(g_ObjectPrefix + avgLabelName, avgText, avgPrice, AveragePriceLineColor, operationType == 0);
      }
   }

   // TPライン表示（利確が有効な場合のみ）
   if(EnableTakeProfit) {
      double tpPrice = 0;
      int tpPoints = TakeProfitPoints;

      if(operationType == 0) { // Buy
         tpPrice = avgPrice + (tpPoints * GetPointValue());
      } else { // Sell
         tpPrice = avgPrice - (tpPoints * GetPointValue());
      }

      if(tpPrice > 0) {
         string tpLineName = "TPLine" + direction;
         string tpLabelName = "TPLabel" + direction;

         // 既存TPラインがあるかチェック
#ifdef __MQL5__
         bool tpLineExists = (ObjectFind(0, g_ObjectPrefix + tpLineName) >= 0);
#else
         bool tpLineExists = (ObjectFind(g_ObjectPrefix + tpLineName) >= 0);
#endif

         if(tpLineExists) {
            // 既存TPラインの価格を更新
#ifdef __MQL5__
            ObjectSetDouble(0, g_ObjectPrefix + tpLineName, OBJPROP_PRICE, tpPrice);
#else
            ObjectSet(g_ObjectPrefix + tpLineName, OBJPROP_PRICE1, tpPrice);
#endif
         } else {
            // 新規TPラインを作成
            CreateHorizontalLine(g_ObjectPrefix + tpLineName, tpPrice, TakeProfitLineColor, STYLE_DASH, 1);
         }

         // TPラベルを更新/作成
         if(EnablePriceLabels) {
#ifdef __MQL5__
            bool tpLabelExists = (ObjectFind(0, g_ObjectPrefix + tpLabelName) >= 0);
#else
            bool tpLabelExists = (ObjectFind(g_ObjectPrefix + tpLabelName) >= 0);
#endif

            string tpText = "TP: " + DoubleToString(tpPrice, GetDigitsValue()) + " (+" + IntegerToString(tpPoints) + "pt)";

            if(tpLabelExists) {
               // 既存TPラベルの価格とテキストを更新
#ifdef __MQL5__
               ObjectSetDouble(0, g_ObjectPrefix + tpLabelName, OBJPROP_PRICE, tpPrice);
               ObjectSetString(0, g_ObjectPrefix + tpLabelName, OBJPROP_TEXT, tpText);
#else
               ObjectSet(g_ObjectPrefix + tpLabelName, OBJPROP_PRICE1, tpPrice);
               ObjectSetText(g_ObjectPrefix + tpLabelName, tpText);
#endif
            } else {
               // 新規TPラベルを作成
               CreatePriceLabel(g_ObjectPrefix + tpLabelName, tpText, tpPrice, TakeProfitLineColor, operationType == 0);
            }
         }
      }
   }
}




// LAYOUT_PATTERNはEnums.mqhで定義済み



// パネルとテーブルの位置を保存するグローバル変数
int g_EffectivePanelX = 0;
int g_EffectivePanelY = 0;
int g_EffectiveTableX = 0;
int g_EffectiveTableY = 0;

//+------------------------------------------------------------------+
//| レイアウトパターンに基づいて位置を設定する関数                    |
//+------------------------------------------------------------------+
void ApplyLayoutPattern()
{
   // デフォルトのサイズを設定
   int defaultPanelWidth = PANEL_WIDTH;
   int defaultPanelHeight = g_PanelMinimized ? TITLE_HEIGHT : (PANEL_HEIGHT + 170); // 最小化時は高さを縮小
   int defaultTableWidth = TABLE_WIDTH;

   // PanelX/PanelYが0の場合はデフォルト値を使用
   int effectivePanelX = (PanelX == 0) ? 20 : PanelX;
   int effectivePanelY = (PanelY == 0) ? 50 : PanelY;

   // レイアウトパターンに応じて位置を調整
   switch(LayoutPattern)
   {
      case LAYOUT_DEFAULT: // デフォルト (パネル上/テーブル下)
         g_EffectivePanelX = effectivePanelX;
         g_EffectivePanelY = effectivePanelY;
         g_EffectiveTableX = effectivePanelX;
         g_EffectiveTableY = effectivePanelY + (g_PanelMinimized ? TITLE_HEIGHT + 20 : 500); // テーブルを下に配置
         break;

      case LAYOUT_SIDE_BY_SIDE: // 横並び (パネル左/テーブル右)
         g_EffectivePanelX = effectivePanelX;
         g_EffectivePanelY = effectivePanelY;
         g_EffectiveTableX = effectivePanelX + defaultPanelWidth + 20; // パネルの右側にテーブルを配置
         g_EffectiveTableY = effectivePanelY;
         break;
         
      case LAYOUT_TABLE_TOP: // テーブル優先 (テーブル上/パネル下)
         g_EffectivePanelX = effectivePanelX;
         g_EffectivePanelY = effectivePanelY + 350; // パネルを下に配置
         g_EffectiveTableX = effectivePanelX;
         g_EffectiveTableY = effectivePanelY;
         break;

      case LAYOUT_COMPACT: // コンパクト (小さいパネル)
         g_EffectivePanelX = effectivePanelX;
         g_EffectivePanelY = effectivePanelY;
         g_EffectiveTableX = effectivePanelX;
         g_EffectiveTableY = effectivePanelY + (g_PanelMinimized ? TITLE_HEIGHT + 20 : 350); // 少し間隔を小さくする
         break;
         
      case LAYOUT_CUSTOM: // カスタム (位置を個別指定)
         g_EffectivePanelX = CustomPanelX;
         g_EffectivePanelY = CustomPanelY;
         g_EffectiveTableX = CustomTableX;
         g_EffectiveTableY = CustomTableY;
         break;
         
      default: // デフォルトの設定
         g_EffectivePanelX = effectivePanelX;
         g_EffectivePanelY = effectivePanelY;
         g_EffectiveTableX = effectivePanelX;
         g_EffectiveTableY = effectivePanelY + (g_PanelMinimized ? TITLE_HEIGHT + 20 : 500);
   }
   
}

//+------------------------------------------------------------------+
//| 現在のレイアウト設定を文字列で取得する関数                        |
//+------------------------------------------------------------------+
string GetLayoutPatternText()
{
   string layoutText = "";
   
   switch(LayoutPattern)
   {
      case LAYOUT_DEFAULT:
         layoutText = "デフォルト (パネル上/テーブル下)";
         break;
      case LAYOUT_SIDE_BY_SIDE:
         layoutText = "横並び (パネル左/テーブル右)";
         break;
      case LAYOUT_TABLE_TOP:
         layoutText = "テーブル優先 (テーブル上/パネル下)";
         break;
      case LAYOUT_COMPACT:
         layoutText = "コンパクト (小さいパネル)";
         break;
      case LAYOUT_CUSTOM:
         layoutText = "カスタム (位置個別指定)";
         break;
      default:
         layoutText = "不明";
   }
   
   return layoutText;
}




//+------------------------------------------------------------------+
//| GUIを作成する - レイアウトパターン対応版                          |
//+------------------------------------------------------------------+
void CreateGUI()
{
   DeleteGUI(); // 既存のGUIを削除
   g_PanelObjectCount = 0; // オブジェクトカウントリセット
   
   // レイアウトパターンを適用
   ApplyLayoutPattern();
   
   // パネル位置を調整された値に設定
   int adjustedPanelX = g_EffectivePanelX;
   int adjustedPanelY = g_EffectivePanelY;
   
   // コンパクトモードの場合はパネルサイズを縮小
   int panelWidth = PANEL_WIDTH;
   int panelHeight = PANEL_HEIGHT + 170; // ゴーストボタン追加のため高さを拡大
   if(LayoutPattern == LAYOUT_COMPACT)
   {
      panelHeight = panelHeight - 50; // 高さを少し縮小
   }
   
   // メインパネル背景
   CreatePanel("MainPanel", adjustedPanelX, adjustedPanelY, panelWidth, panelHeight, COLOR_PANEL_BG, COLOR_PANEL_BORDER);
   
   // パネルタイトル
   CreateTitleBar("TitleBar", adjustedPanelX, adjustedPanelY, panelWidth, TITLE_HEIGHT, COLOR_TITLE_BG, PanelTitle);

   // 最小化ボタン
   int minimizeButtonSize = TITLE_HEIGHT - 4;
   CreateButton("btnMinimize", g_PanelMinimized ? "□" : "−",
               adjustedPanelX + panelWidth - minimizeButtonSize - 2,
               adjustedPanelY + 2,
               minimizeButtonSize, minimizeButtonSize,
               COLOR_BUTTON_NEUTRAL, COLOR_TEXT_WHITE);
   
   int buttonWidth = (panelWidth - (PANEL_MARGIN * 3)) / 2; // 2列のボタン用
   int fullWidth = panelWidth - (PANEL_MARGIN * 2); // 横いっぱいのボタン用

   // パネルが最小化されている場合は、タイトルバーとボタンのみ表示
   if(g_PanelMinimized)
   {
      // 最小化時の高さに調整
      int minimizedHeight = TITLE_HEIGHT;
      #ifdef __MQL5__
         ObjectSetInteger(0, g_ObjectPrefix + "MainPanel" + "BG", OBJPROP_YSIZE, minimizedHeight);
      #else
         ObjectSet(g_ObjectPrefix + "MainPanel" + "BG", OBJPROP_YSIZE, minimizedHeight);
      #endif

      ChartRedraw();
      return; // 最小化時は他のボタンを作成しない
   }

   // Y座標管理用変数
   int currentY = adjustedPanelY + TITLE_HEIGHT + PANEL_MARGIN;
   int sectionSpacing = PANEL_MARGIN * 3;  // セクション間のスペース
   int labelOffset = 20;  // セクションラベルのオフセット

   // ========== 行1: 決済ボタン ==========
   
   // Sell決済ボタン (左)
   CreateButton("btnCloseSell", "Close Sell", adjustedPanelX + PANEL_MARGIN, currentY, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_SELL, COLOR_TEXT_LIGHT);
   
   // Buy決済ボタン (右)
   CreateButton("btnCloseBuy", "Close Buy", adjustedPanelX + PANEL_MARGIN * 2 + buttonWidth, currentY, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_BUY, COLOR_TEXT_LIGHT);
   currentY += BUTTON_HEIGHT + PANEL_MARGIN;
   
   // ========== 行2: 全決済ボタン ==========
   
   // 全決済ボタン（横いっぱい）
   CreateButton("btnCloseAll", "Close All", adjustedPanelX + PANEL_MARGIN, currentY, fullWidth, BUTTON_HEIGHT, COLOR_BUTTON_CLOSE_ALL, COLOR_TEXT_WHITE);
   currentY += BUTTON_HEIGHT + sectionSpacing;
   CreateTooltip("btnCloseAll", "相殺決済を優先してすべてのポジションを決済します");
   
   // ========== 行3: 直接エントリーボタン ==========
   
   // セクションラベル
   CreateLabel("lblDirectEntry", "【直接エントリー】", adjustedPanelX + PANEL_MARGIN, currentY - labelOffset, COLOR_TEXT_LIGHT);
   
   // Sellエントリーボタン (左) - 直接エントリー色
   CreateButton("btnDirectSell", "SELL NOW", adjustedPanelX + PANEL_MARGIN, currentY, buttonWidth, BUTTON_HEIGHT, COLOR_ENTRY_DIRECT, COLOR_TEXT_WHITE);
   CreateTooltip("btnDirectSell", "現在価格で即座にSELL注文を実行します");
   
   // Buyエントリーボタン (右) - 直接エントリー色
   CreateButton("btnDirectBuy", "BUY NOW", adjustedPanelX + PANEL_MARGIN * 2 + buttonWidth, currentY, buttonWidth, BUTTON_HEIGHT, COLOR_ENTRY_DIRECT, COLOR_TEXT_WHITE);
   currentY += BUTTON_HEIGHT + sectionSpacing;
   CreateTooltip("btnDirectBuy", "現在価格で即座にBUY注文を実行します");
   
   // コンパクトモードの場合、一部のセクションを省略または縮小
   int rowSpacing = (LayoutPattern == LAYOUT_COMPACT) ? 10 : 15;
   
   // ========== 新規追加: 行3.5: ゴーストエントリーボタン ==========
   
   // セクションラベル
   CreateLabel("lblGhostEntry", "【ゴーストエントリー】", adjustedPanelX + PANEL_MARGIN, currentY - labelOffset, COLOR_TEXT_LIGHT);
   
   // ゴーストSellエントリーボタン (左) - ゴースト色
   CreateButton("btnGhostSell", "GHOST SELL", adjustedPanelX + PANEL_MARGIN, currentY, buttonWidth, BUTTON_HEIGHT, COLOR_ENTRY_GHOST, COLOR_TEXT_WHITE);
   CreateTooltip("btnGhostSell", "仮想SELL注文を作成します（実際の取引は行いません）");
   
   // ゴーストBuyエントリーボタン (右) - ゴースト色
   CreateButton("btnGhostBuy", "GHOST BUY", adjustedPanelX + PANEL_MARGIN * 2 + buttonWidth, currentY, buttonWidth, BUTTON_HEIGHT, COLOR_ENTRY_GHOST, COLOR_TEXT_WHITE);
   currentY += BUTTON_HEIGHT + sectionSpacing;
   CreateTooltip("btnGhostBuy", "仮想BUY注文を作成します（実際の取引は行いません）");
   
   // ========== 行4: 途中からエントリーボタン ==========
   
   // セクションラベル
   CreateLabel("lblLevelEntry", "【レベル指定エントリー】", adjustedPanelX + PANEL_MARGIN, currentY - labelOffset, COLOR_TEXT_LIGHT);
   
   // 現在のゴーストカウントに基づいてレベルを決定
   int buyLevel = ghost_position_count(OP_BUY) + 1;
   int sellLevel = ghost_position_count(OP_SELL) + 1;
   
   // Sellエントリーボタン (左) - レベルエントリー色
   CreateButton("btnLevelSell", "SELL Level " + IntegerToString(sellLevel), adjustedPanelX + PANEL_MARGIN, currentY, buttonWidth, BUTTON_HEIGHT, COLOR_ENTRY_LEVEL, COLOR_TEXT_WHITE);
   CreateTooltip("btnLevelSell", "指定レベル(" + IntegerToString(sellLevel) + ")でSELL注文を実行します");
   
   // Buyエントリーボタン (右) - レベルエントリー色
   CreateButton("btnLevelBuy", "BUY Level " + IntegerToString(buyLevel), adjustedPanelX + PANEL_MARGIN * 2 + buttonWidth, currentY, buttonWidth, BUTTON_HEIGHT, COLOR_ENTRY_LEVEL, COLOR_TEXT_WHITE);
   currentY += BUTTON_HEIGHT + sectionSpacing;
   CreateTooltip("btnLevelBuy", "指定レベル(" + IntegerToString(buyLevel) + ")でBUY注文を実行します");
   
   // ========== 行5: 設定セクション ==========
   
   // セクションラベル
   CreateLabel("lblSettings", "【設定】", adjustedPanelX + PANEL_MARGIN, currentY - labelOffset, COLOR_TEXT_LIGHT);
   
   // Ghostモードボタン（横いっぱい）
   CreateButton("btnGhostToggle", "GHOST " + (g_GhostMode ? "ON" : "OFF"), 
               adjustedPanelX + PANEL_MARGIN, currentY, fullWidth, BUTTON_HEIGHT, 
               g_GhostMode ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE, COLOR_TEXT_LIGHT);
   currentY += BUTTON_HEIGHT + PANEL_MARGIN * 2;
   
   // ========== 行6: ゴーストリセットボタン ==========
   
   // ゴーストリセットボタン（横いっぱい）
   CreateButton("btnResetGhost", "GHOST RESET", adjustedPanelX + PANEL_MARGIN, currentY, fullWidth, BUTTON_HEIGHT, COLOR_BUTTON_INACTIVE, COLOR_TEXT_LIGHT);
   currentY += BUTTON_HEIGHT + PANEL_MARGIN;
   
   // ========== 行7: 平均取得単価表示切替ボタン ==========
   
   // 平均取得単価表示切替ボタン（横いっぱい）
   CreateButton("btnToggleAvgPrice", "AVG PRICE " + (g_AvgPriceVisible ? "ON" : "OFF"),
               adjustedPanelX + PANEL_MARGIN, currentY, fullWidth, BUTTON_HEIGHT,
               g_AvgPriceVisible ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE, COLOR_TEXT_LIGHT);
   currentY += BUTTON_HEIGHT + PANEL_MARGIN;

   // ========== 行8: 自動売買切替ボタン ==========

   // 自動売買切替ボタン（横いっぱい）
   CreateButton("btnToggleAutoTrading", "AUTO TRADING " + (g_AutoTrading ? "ON" : "OFF"),
               adjustedPanelX + PANEL_MARGIN, currentY, fullWidth, BUTTON_HEIGHT,
               g_AutoTrading ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE, COLOR_TEXT_WHITE);
   currentY += BUTTON_HEIGHT + PANEL_MARGIN;

   // テクニカル指標表示トグルボタン
   CreateButton("btnToggleInfoPanel", "指標状態表示 " + (IsInfoPanelVisible() ? "ON" : "OFF"),
               adjustedPanelX + PANEL_MARGIN, currentY, fullWidth, BUTTON_HEIGHT,
               IsInfoPanelVisible() ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE,
               IsInfoPanelVisible() ? COLOR_TEXT_WHITE : COLOR_TEXT_LIGHT);
   currentY += BUTTON_HEIGHT + PANEL_MARGIN;

   // ========== 行9: 情報表示ボタン ==========
   
   // ロット情報表示ボタン (左)
   CreateButton("btnShowLotTable", "Lot Table", adjustedPanelX + PANEL_MARGIN, currentY, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_NEUTRAL, COLOR_TEXT_LIGHT);
   
   // 設定情報表示ボタン (右)
   CreateButton("btnShowSettings", "Settings", adjustedPanelX + PANEL_MARGIN * 2 + buttonWidth, currentY, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_NEUTRAL, COLOR_TEXT_LIGHT);
   currentY += BUTTON_HEIGHT + PANEL_MARGIN;
   
   // パネルの高さを調整
   panelHeight = currentY - adjustedPanelY;
   #ifdef __MQL5__
      ObjectSetInteger(0, g_ObjectPrefix + "MainPanel" + "BG", OBJPROP_YSIZE, panelHeight);
   #else
      ObjectSet(g_ObjectPrefix + "MainPanel" + "BG", OBJPROP_YSIZE, panelHeight);
   #endif
   
   ChartRedraw(); // チャートを再描画
}

//+------------------------------------------------------------------+
//| ラベル作成 - フォントをSegoe UIに変更                           |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color textColor)
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string objectName = g_ObjectPrefix + name;
   
   #ifdef __MQL5__
      ObjectCreate(0, objectName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, objectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, objectName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, objectName, OBJPROP_YDISTANCE, y);
      ObjectSetString(0, objectName, OBJPROP_TEXT, text);
      ObjectSetString(0, objectName, OBJPROP_FONT, "MS Gothic");
      ObjectSetInteger(0, objectName, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, objectName, OBJPROP_COLOR, textColor);
      ObjectSetInteger(0, objectName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objectName, OBJPROP_ZORDER, 3020);
   #else
      ObjectCreate(objectName, OBJ_LABEL, 0, 0, 0);
      ObjectSet(objectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(objectName, OBJPROP_XDISTANCE, x);
      ObjectSet(objectName, OBJPROP_YDISTANCE, y);
      ObjectSetText(objectName, text, 9, "MS Gothic", textColor);
      ObjectSet(objectName, OBJPROP_SELECTABLE, false);
      ObjectSet(objectName, OBJPROP_ZORDER, 3020);
   #endif
   
   // オブジェクト名を保存
   SaveObjectName(objectName, g_PanelNames, g_PanelObjectCount);
}

//+------------------------------------------------------------------+
//| パネル作成                                                        |
//+------------------------------------------------------------------+
void CreatePanel(string name, int x, int y, int width, int height, color bgColor, color borderColor)
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string objectName = g_ObjectPrefix + name;
   
   // パネル背景
   string bgName = objectName + "BG";
   
   #ifdef __MQL5__
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, bgName, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, bgColor);
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bgName, OBJPROP_COLOR, borderColor);
      ObjectSetInteger(0, bgName, OBJPROP_WIDTH, PANEL_BORDER_WIDTH);
      ObjectSetInteger(0, bgName, OBJPROP_BACK, false);
      ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, bgName, OBJPROP_ZORDER, 3000);
   #else
      ObjectCreate(bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSet(bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(bgName, OBJPROP_XDISTANCE, x);
      ObjectSet(bgName, OBJPROP_YDISTANCE, y);
      ObjectSet(bgName, OBJPROP_XSIZE, width);
      ObjectSet(bgName, OBJPROP_YSIZE, height);
      ObjectSet(bgName, OBJPROP_BGCOLOR, bgColor);
      ObjectSet(bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSet(bgName, OBJPROP_COLOR, borderColor);
      ObjectSet(bgName, OBJPROP_WIDTH, PANEL_BORDER_WIDTH);
      ObjectSet(bgName, OBJPROP_BACK, false);
      ObjectSet(bgName, OBJPROP_SELECTABLE, false);
      ObjectSet(bgName, OBJPROP_ZORDER, 3000);
   #endif

   // オブジェクト名を保存
   SaveObjectName(bgName, g_PanelNames, g_PanelObjectCount);
}

//+------------------------------------------------------------------+
//| タイトルバー作成                                                  |
//+------------------------------------------------------------------+
void CreateTitleBar(string name, int x, int y, int width, int height, color bgColor, string title)
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string objectName = g_ObjectPrefix + name;
   
   // タイトルバー背景
   string bgName = objectName + "BG";
   
   #ifdef __MQL5__
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, bgName, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, bgColor);
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bgName, OBJPROP_COLOR, bgColor);
      ObjectSetInteger(0, bgName, OBJPROP_BACK, false);
      ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, bgName, OBJPROP_ZORDER, 3010);
   #else
      ObjectCreate(bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSet(bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(bgName, OBJPROP_XDISTANCE, x);
      ObjectSet(bgName, OBJPROP_YDISTANCE, y);
      ObjectSet(bgName, OBJPROP_XSIZE, width);
      ObjectSet(bgName, OBJPROP_YSIZE, height);
      ObjectSet(bgName, OBJPROP_BGCOLOR, bgColor);
      ObjectSet(bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSet(bgName, OBJPROP_COLOR, bgColor);
      ObjectSet(bgName, OBJPROP_BACK, false);
      ObjectSet(bgName, OBJPROP_SELECTABLE, false);
      ObjectSet(bgName, OBJPROP_ZORDER, 3010);
   #endif
   
   // タイトルテキスト
   string textName = objectName + "Text";
   
   #ifdef __MQL5__
      ObjectCreate(0, textName, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, textName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, textName, OBJPROP_XDISTANCE, x + 10);
      ObjectSetInteger(0, textName, OBJPROP_YDISTANCE, y + 8);
      ObjectSetString(0, textName, OBJPROP_TEXT, title);
      ObjectSetString(0, textName, OBJPROP_FONT, "MS Gothic");
      ObjectSetInteger(0, textName, OBJPROP_FONTSIZE, 10);
      ObjectSetInteger(0, textName, OBJPROP_COLOR, COLOR_TITLE_TEXT);
      ObjectSetInteger(0, textName, OBJPROP_SELECTABLE, false);
   #else
      ObjectCreate(textName, OBJ_LABEL, 0, 0, 0);
      ObjectSet(textName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(textName, OBJPROP_XDISTANCE, x + 10);
      ObjectSet(textName, OBJPROP_YDISTANCE, y + 8);
      ObjectSetText(textName, title, 10, "Arial", COLOR_TITLE_TEXT);
      ObjectSet(textName, OBJPROP_SELECTABLE, false);
   #endif
   
   // オブジェクト名を保存
   SaveObjectName(bgName, g_PanelNames, g_PanelObjectCount);
   SaveObjectName(textName, g_PanelNames, g_PanelObjectCount);
}

//+------------------------------------------------------------------+
//| ツールチップ作成                                                |
//+------------------------------------------------------------------+
void CreateTooltip(string objectName, string tooltipText)
{
   string tooltipName = g_ObjectPrefix + objectName + "_Tooltip";
   
#ifdef __MQL5__
   ObjectCreate(0, tooltipName, OBJ_LABEL, 0, 0, 0);
   ObjectSetString(0, tooltipName, OBJPROP_TEXT, tooltipText);
   ObjectSetString(0, tooltipName, OBJPROP_FONT, "MS Gothic");
   ObjectSetInteger(0, tooltipName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, tooltipName, OBJPROP_COLOR, COLOR_TEXT_LIGHT);
   ObjectSetInteger(0, tooltipName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, tooltipName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, tooltipName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS); // 非表示にする
#else
   ObjectCreate(tooltipName, OBJ_LABEL, 0, 0, 0);
   ObjectSet(tooltipName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetText(tooltipName, tooltipText, 8, "MS Gothic", COLOR_TEXT_LIGHT);
   ObjectSet(tooltipName, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS); // 非表示にする
#endif
   
   SaveObjectName(tooltipName, g_PanelNames, g_PanelObjectCount);
}

//+------------------------------------------------------------------+
//| ボタン作成 - フォントをMS Gothicに変更                           |
//+------------------------------------------------------------------+
void CreateButton(string name, string text, int x, int y, int width, int height, color bgColor, color textColor)
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string objectName = g_ObjectPrefix + name;
   
   // ボタン背景
   string bgName = objectName + "BG";
   
   #ifdef __MQL5__
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, bgName, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE, height);
      ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, bgColor);
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSetInteger(0, bgName, OBJPROP_COLOR, ColorDarken(bgColor, 20));
      ObjectSetInteger(0, bgName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, bgName, OBJPROP_BACK, false);
      ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, bgName, OBJPROP_ZORDER, 3030);
   #else
      ObjectCreate(bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSet(bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(bgName, OBJPROP_XDISTANCE, x);
      ObjectSet(bgName, OBJPROP_YDISTANCE, y);
      ObjectSet(bgName, OBJPROP_XSIZE, width);
      ObjectSet(bgName, OBJPROP_YSIZE, height);
      ObjectSet(bgName, OBJPROP_BGCOLOR, bgColor);
      ObjectSet(bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
      ObjectSet(bgName, OBJPROP_COLOR, ColorDarken(bgColor, 20));
      ObjectSet(bgName, OBJPROP_WIDTH, 1);
      ObjectSet(bgName, OBJPROP_BACK, false);
      ObjectSet(bgName, OBJPROP_SELECTABLE, false);
      ObjectSet(bgName, OBJPROP_ZORDER, 3030);
   #endif
   
   // ボタン本体
   #ifdef __MQL5__
      ObjectCreate(0, objectName, OBJ_BUTTON, 0, 0, 0);
      ObjectSetInteger(0, objectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, objectName, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, objectName, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, objectName, OBJPROP_XSIZE, width);
      ObjectSetInteger(0, objectName, OBJPROP_YSIZE, height);
      ObjectSetString(0, objectName, OBJPROP_TEXT, text);
      ObjectSetString(0, objectName, OBJPROP_FONT, "MS Gothic");
      ObjectSetInteger(0, objectName, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, objectName, OBJPROP_COLOR, textColor);
      ObjectSetInteger(0, objectName, OBJPROP_BGCOLOR, bgColor);
      ObjectSetInteger(0, objectName, OBJPROP_BORDER_COLOR, ColorDarken(bgColor, 20));
      ObjectSetInteger(0, objectName, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, objectName, OBJPROP_ZORDER, 3040);
   #else
      ObjectCreate(objectName, OBJ_BUTTON, 0, 0, 0);
      ObjectSet(objectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSet(objectName, OBJPROP_XDISTANCE, x);
      ObjectSet(objectName, OBJPROP_YDISTANCE, y);
      ObjectSet(objectName, OBJPROP_XSIZE, width);
      ObjectSet(objectName, OBJPROP_YSIZE, height);
      ObjectSetText(objectName, text, 9, "MS Gothic", textColor);
      ObjectSet(objectName, OBJPROP_BGCOLOR, bgColor);
      ObjectSet(objectName, OBJPROP_BORDER_COLOR, ColorDarken(bgColor, 20));
      ObjectSet(objectName, OBJPROP_COLOR, textColor);
      ObjectSet(objectName, OBJPROP_SELECTABLE, false);
      ObjectSet(objectName, OBJPROP_ZORDER, 3040);
   #endif
   
   // オブジェクト名を保存
   SaveObjectName(bgName, g_PanelNames, g_PanelObjectCount);
   SaveObjectName(objectName, g_PanelNames, g_PanelObjectCount);
}

//+------------------------------------------------------------------+
//| ロットテーブル表示を作成するための補助関数                         |
//+------------------------------------------------------------------+
void CreateLotTableDialog()
{
   // ダイアログタイトル
   string title = "Hosopi 3 - ロットテーブル";
   
   // ダイアログ内容を構築
   string message = "現在のロットテーブル:\n\n";
   
   // 最初の10レベルを表示
   for(int i = 0; i < 10; i++)
   {
      message += "Level " + IntegerToString(i + 1) + ": " + DoubleToString(g_LotTable[i], 2) + "\n";
   }
   
   // 次の10レベルは折りたたんで表示
   message += "\n続き (11-20):\n";
   for(int i = 10; i < 20; i++)
   {
      message += "Level " + IntegerToString(i + 1) + ": " + DoubleToString(g_LotTable[i], 2) + "\n";
   }
   
   // 設定モードを表示
   message += "\n設定モード: " + (IndividualLotEnabled == ON_MODE ? "個別指定" : "マーチンゲール方式");
   if(IndividualLotEnabled == OFF_MODE)
   {
      message += "\n初期ロット: " + DoubleToString(InitialLot, 2);
      message += "\n倍率: " + DoubleToString(LotMultiplier, 2);
   }
   
   // メッセージボックスを表示
   MessageBox(message, title, MB_ICONINFORMATION);
}


//+------------------------------------------------------------------+
//| エントリーモードを文字列に変換する補助関数                         |
//+------------------------------------------------------------------+
string GetEntryModeString(int mode)
{
   switch(mode)
   {
      case MODE_BUY_ONLY: return "Buyのみ";
      case MODE_SELL_ONLY: return "Sellのみ";
      case MODE_BOTH: return "Buy & Sell両方";
      default: return "不明";
   }
}

//+------------------------------------------------------------------+
//| GUIを削除する                                                     |
//+------------------------------------------------------------------+
void DeleteGUI()
{
   for(int i = 0; i < g_PanelObjectCount; i++)
   {
      #ifdef __MQL5__
         if(ObjectFind(0, g_PanelNames[i]) >= 0)
            ObjectDelete(0, g_PanelNames[i]);
      #else
         if(ObjectFind(g_PanelNames[i]) >= 0)
            ObjectDelete(g_PanelNames[i]);
      #endif
   }
   
   g_PanelObjectCount = 0;
   ChartRedraw(); // チャートを再描画
}

//+------------------------------------------------------------------+
//| GUIを更新する - レベルボタン対応版                               |
//+------------------------------------------------------------------+
void UpdateGUI()
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string ghostBtnPrefix = g_ObjectPrefix + "btnGhostToggle";
   string avgPriceBtnPrefix = g_ObjectPrefix + "btnToggleAvgPrice";
   string levelBuyBtnPrefix = g_ObjectPrefix + "btnLevelBuy";
   string levelSellBtnPrefix = g_ObjectPrefix + "btnLevelSell";
   
   // レベルボタンのラベルを更新 - ナンピンレベル廃止対応
   int buyLevel = ghost_position_count(OP_BUY) + 1;
   int sellLevel = ghost_position_count(OP_SELL) + 1;
   
   #ifdef __MQL5__
      ObjectSetString(0, levelBuyBtnPrefix, OBJPROP_TEXT, "BUY Level " + IntegerToString(buyLevel));
      ObjectSetString(0, levelSellBtnPrefix, OBJPROP_TEXT, "SELL Level " + IntegerToString(sellLevel));
   #else
      ObjectSetText(levelBuyBtnPrefix, "BUY Level " + IntegerToString(buyLevel), 9, "MS Gothic", COLOR_TEXT_LIGHT);
      ObjectSetText(levelSellBtnPrefix, "SELL Level " + IntegerToString(sellLevel), 9, "MS Gothic", COLOR_TEXT_LIGHT);
   #endif
   
   // Ghost ON/OFFボタン状態更新
   color ghostButtonColor = g_GhostMode ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE;
   
   #ifdef __MQL5__
      ObjectSetInteger(0, ghostBtnPrefix + "BG", OBJPROP_BGCOLOR, ghostButtonColor);
      ObjectSetInteger(0, ghostBtnPrefix + "BG", OBJPROP_COLOR, ColorDarken(ghostButtonColor, 20));
      ObjectSetInteger(0, ghostBtnPrefix, OBJPROP_BGCOLOR, ghostButtonColor);
      ObjectSetInteger(0, ghostBtnPrefix, OBJPROP_BORDER_COLOR, ColorDarken(ghostButtonColor, 20));
      ObjectSetString(0, ghostBtnPrefix, OBJPROP_TEXT, g_GhostMode ? "GHOST ON" : "GHOST OFF");
   #else
      ObjectSet(ghostBtnPrefix + "BG", OBJPROP_BGCOLOR, ghostButtonColor);
      ObjectSet(ghostBtnPrefix + "BG", OBJPROP_COLOR, ColorDarken(ghostButtonColor, 20));
      ObjectSet(ghostBtnPrefix, OBJPROP_BGCOLOR, ghostButtonColor);
      ObjectSet(ghostBtnPrefix, OBJPROP_BORDER_COLOR, ColorDarken(ghostButtonColor, 20));
      ObjectSetText(ghostBtnPrefix, g_GhostMode ? "GHOST ON" : "GHOST OFF", 9, "MS Gothic", COLOR_TEXT_LIGHT);
   #endif
   
   // 平均取得単価表示ボタン状態更新
   color avgPriceButtonColor = g_AvgPriceVisible ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE;
   
   #ifdef __MQL5__
      ObjectSetInteger(0, avgPriceBtnPrefix + "BG", OBJPROP_BGCOLOR, avgPriceButtonColor);
      ObjectSetInteger(0, avgPriceBtnPrefix + "BG", OBJPROP_COLOR, ColorDarken(avgPriceButtonColor, 20));
      ObjectSetInteger(0, avgPriceBtnPrefix, OBJPROP_BGCOLOR, avgPriceButtonColor);
      ObjectSetInteger(0, avgPriceBtnPrefix, OBJPROP_BORDER_COLOR, ColorDarken(avgPriceButtonColor, 20));
      ObjectSetString(0, avgPriceBtnPrefix, OBJPROP_TEXT, g_AvgPriceVisible ? "AVG PRICE ON" : "AVG PRICE OFF");
   #else
      ObjectSet(avgPriceBtnPrefix + "BG", OBJPROP_BGCOLOR, avgPriceButtonColor);
      ObjectSet(avgPriceBtnPrefix + "BG", OBJPROP_COLOR, ColorDarken(avgPriceButtonColor, 20));
      ObjectSet(avgPriceBtnPrefix, OBJPROP_BGCOLOR, avgPriceButtonColor);
      ObjectSet(avgPriceBtnPrefix, OBJPROP_BORDER_COLOR, ColorDarken(avgPriceButtonColor, 20));
      ObjectSetText(avgPriceBtnPrefix, g_AvgPriceVisible ? "AVG PRICE ON" : "AVG PRICE OFF", 9, "MS Gothic", COLOR_TEXT_LIGHT);
   #endif

   // ChartRedraw()は必要な場合のみ呼び出す（HLINEちかちか防止）
   // ChartRedraw(); // HLINEちかちか防止のため無効化
}


//+------------------------------------------------------------------+
//| ボタンクリックを処理する - ゴーストエントリーボタン対応版         |
//+------------------------------------------------------------------+
void ProcessButtonClick(string buttonName)
{
   // プレフィックスを除去してボタン名を比較（複数チャート対策）
   string originalName = buttonName;
   
   // プレフィックスチェック
   if(StringFind(buttonName, g_ObjectPrefix) == 0) {
      // プレフィックスを除去
      buttonName = StringSubstr(buttonName, StringLen(g_ObjectPrefix));
   } else {
      // このEAに属さないボタンならスキップ
      return;
   }
   
   // ボタンの状態をリセット（押したままにならないように）
   #ifdef __MQL5__
      ObjectSetInteger(0, originalName, OBJPROP_STATE, false);
   #else
      ObjectSet(originalName, OBJPROP_STATE, false);
   #endif
   
   // Buy Close - 非同期対応
   if(buttonName == "btnCloseBuy")
   {
      #ifdef __MQL5__
      // 非同期でBuyポジションを全決済
      for(int i = 0; i < PositionsTotal(); i++) {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket)) {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
               PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) {
               ClosePositionAsync(ticket, UseAsyncOrders);
               if(UseAsyncOrders) Sleep(10);
            }
         }
      }
      #else
      position_close(0, -1);
      #endif
      UpdateGUI();
   }

   // Sell Close - 非同期対応
   else if(buttonName == "btnCloseSell")
   {
      #ifdef __MQL5__
      // 非同期でSellポジションを全決済
      for(int i = 0; i < PositionsTotal(); i++) {
         ulong ticket = PositionGetTicket(i);
         if(PositionSelectByTicket(ticket)) {
            if(PositionGetInteger(POSITION_MAGIC) == MagicNumber &&
               PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) {
               ClosePositionAsync(ticket, UseAsyncOrders);
               if(UseAsyncOrders) Sleep(10);
            }
         }
      }
      #else
      position_close(1, -1);
      #endif
      UpdateGUI();
   }
   
   // Close All（相殺決済優先）
   else if(buttonName == "btnCloseAll")
   {
      Print("=== Close All実行開始（相殺決済優先） ===");

      // 非同期で相殺決済を優先して全決済
      CloseAllPositionsAsync(UseAsyncOrders, true);  // 相殺決済を優先

      // 少し待機してからゴーストポジションもクリア
      Sleep(100);

      // ゴーストもリセット
      ResetGhostPositions(OP_BUY);
      ResetGhostPositions(OP_SELL);

      // グローバル変数からもクリア
      ClearGhostGlobalVariables();

      // 決済済みフラグもリセット
      g_BuyGhostClosed = false;
      g_SellGhostClosed = false;
      SaveGhostPositionsToGlobal();

      Print("=== Close All完了 ===");

      UpdateGUI();
      UpdatePositionTable();
   }
   
   // Ghost Toggle
   else if(buttonName == "btnGhostToggle" || buttonName == "btnGhostMode")
   {
      g_GhostMode = !g_GhostMode;
      
      // ゴーストモードをOFFにした場合は、すべてのゴーストをリセット
      if(!g_GhostMode)
      {
         ResetGhostPositions(OP_BUY);
         ResetGhostPositions(OP_SELL);
      }
      else
      {
         // ゴーストモードをONにした場合、決済済みフラグをリセット
         g_BuyGhostClosed = false;
         g_SellGhostClosed = false;
         SaveGhostPositionsToGlobal();
      }
      
      UpdateGUI();
   
   }
   
   // Reset Ghost
   else if(buttonName == "btnResetGhost")
   {
      
      
      // ゴーストオブジェクトを削除
      DeleteObjectsByPrefix(g_ObjectPrefix + "GhostArrow_");
      ClearGhostObjects();
      
      // ゴーストポジションをリセット
      ResetGhostPositions(OP_BUY);  // 両方のゴーストをリセット
      ResetGhostPositions(OP_SELL);
      
      // グローバル変数からも完全にクリア
      ClearGhostGlobalVariables();
      
      // 決済済みフラグもリセット
      g_BuyGhostClosed = false;
      g_SellGhostClosed = false;
      SaveGhostPositionsToGlobal();
      
      // GUIとテーブルを再作成
      DeleteGUI();
      DeletePositionTable();
      CreateGUI();
      CreatePositionTable();
      
      UpdateGUI();
      
      // 最後にチャートを再描画
      ChartRedraw();
      
      // ゴーストポジションリセット完了
   }
   
   // Toggle Average Price Display
   else if(buttonName == "btnToggleAvgPrice" || buttonName == "btnAvgPriceLine")
   {
      g_AvgPriceVisible = !g_AvgPriceVisible;

      if(!g_AvgPriceVisible)
      {
         DeleteAllLines();
      }

      UpdateGUI();
      // 平均価格ライン表示状態を切り替え
   }

   // Toggle Auto Trading
   else if(buttonName == "btnToggleAutoTrading")
   {
      g_AutoTrading = !g_AutoTrading;

      UpdateGUI();
      // 自動売買設定を切り替え
      if(g_AutoTrading)
      {
         Print("【重要】自動売買が有効になりました。戦略シグナルでリアルエントリーが実行されます。");
      }
      else
      {
         Print("【重要】自動売買が無効になりました。戦略シグナルではゴーストエントリーのみ実行されます。");
      }
   }

   // Toggle Info Panel
   else if(buttonName == "btnToggleInfoPanel")
   {
      ToggleInfoPanel();
      // UpdateGUI()を呼ばず、ボタンのテキストのみ更新
      ObjectSetString(0, "btnToggleInfoPanel", OBJPROP_TEXT, "INFO PANEL " + (IsInfoPanelVisible() ? "ON" : "OFF"));
      ObjectSetInteger(0, "btnToggleInfoPanel", OBJPROP_BGCOLOR,
                      IsInfoPanelVisible() ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE);
      Print("テクニカル指標InfoPanel: ", IsInfoPanelVisible() ? "表示" : "非表示");

      // 強制的にテーブル位置を更新
      ForceUpdatePositionTableLocation();
   }

   // Panel Minimize/Maximize
   else if(buttonName == "btnMinimize")
   {
      g_PanelMinimized = !g_PanelMinimized;

      // GUIを再構築
      CreateGUI();
      UpdateGUI();

      // パネル表示状態を切り替え
   }

   // ===== 直接エントリー機能 =====
   
   // 直接Buy
   else if(buttonName == "btnDirectBuy")
   {
      ExecuteDiscretionaryEntry(OP_BUY);
      UpdatePositionTable();
      UpdateGUI(); // レベルボタンのラベルを更新
   }
   
// 直接Sell
else if(buttonName == "btnDirectSell")
{
   ExecuteDiscretionaryEntry(OP_SELL);
   UpdatePositionTable();
   UpdateGUI(); // レベルボタンのラベルを更新
}

// ===== ゴーストエントリーボタン処理（新規追加） =====

// ゴーストBuy
else if(buttonName == "btnGhostBuy")
{
   if(!g_GhostMode)
   {
      // ゴーストモードが無効の場合はメッセージを表示
      MessageBox("ゴーストモードが無効です。先にGHOST ONにしてください。", "ゴーストエントリーエラー", MB_ICONWARNING);
   }
   else if(position_count(OP_SELL) > 0)
   {
      // すでにリアルポジションがある場合
      MessageBox("すでにBuy方向のリアルポジションが存在します。\nゴーストエントリーはリアルポジションがない状態で行ってください。", 
                 "ゴーストエントリーエラー", MB_ICONWARNING);
   }
   else
   {
      // ゴーストBuyポジション初期化
      InitializeGhostPosition(OP_BUY, "手動ゴーストエントリー");
      UpdatePositionTable();
      UpdateGUI(); // レベルボタンのラベルを更新
   }
}

// ゴーストSell
else if(buttonName == "btnGhostSell")
{
   if(!g_GhostMode)
   {
      // ゴーストモードが無効の場合はメッセージを表示
      MessageBox("ゴーストモードが無効です。先にGHOST ONにしてください。", "ゴーストエントリーエラー", MB_ICONWARNING);
   }
   else if(position_count(OP_SELL) > 0)
   {
      // すでにリアルポジションがある場合
      MessageBox("すでにSell方向のリアルポジションが存在します。\nゴーストエントリーはリアルポジションがない状態で行ってください。", 
                 "ゴーストエントリーエラー", MB_ICONWARNING);
   }
   else
   {
      // ゴーストSellポジション初期化
      InitializeGhostPosition(OP_SELL, "手動ゴーストエントリー");
      UpdatePositionTable();
      UpdateGUI(); // レベルボタンのラベルを更新
   }
}

// ===== レベル指定エントリーボタン =====

// レベル指定Buy
else if(buttonName == "btnLevelBuy")
{
   // 現在のゴーストカウント+1をレベルとして使用 - ナンピンレベル廃止対応
   int entryLevel = ghost_position_count(OP_BUY) + 1;
   ExecuteEntryFromLevel(OP_BUY, entryLevel);
   UpdatePositionTable();
   UpdateGUI(); // レベルボタンのラベルを更新
}

// レベル指定Sell
else if(buttonName == "btnLevelSell")
{
   // 現在のゴーストカウント+1をレベルとして使用 - ナンピンレベル廃止対応
   int entryLevel = ghost_position_count(OP_SELL) + 1;
   ExecuteEntryFromLevel(OP_SELL, entryLevel);
   UpdatePositionTable();
   UpdateGUI(); // レベルボタンのラベルを更新
}

// ロットテーブル表示ボタン
else if(buttonName == "btnShowLotTable")
{
   CreateLotTableDialog();
}

// 設定情報表示ボタン
else if(buttonName == "btnShowSettings")
{
   ShowSettingsDialog();
}

// 未知のボタンの場合
else
{
   Print("未知のボタン: ", buttonName);
}
}



//+------------------------------------------------------------------+
//| 平均取得単価計算方式を文字列に変換                                 |
//+------------------------------------------------------------------+
string GetAvgPriceCalcModeString(int mode)
{
   switch(mode)
   {
      case REAL_POSITIONS_ONLY: return "リアルポジションのみ";
      case REAL_AND_GHOST: return "リアル＋ゴースト";
      default: return "不明";
   }
}



//+------------------------------------------------------------------+
//| 設定情報ダイアログを表示 - レイアウトパターン対応版                |
//+------------------------------------------------------------------+
void ShowSettingsDialog()
{
   // ダイアログタイトル
   string title = "Hosopi 3 - 設定情報";
   
   // ダイアログ内容を構築
   string message = "【基本設定】\n";
   message += "エントリーモード: " + GetEntryModeString(EntryMode) + "\n";
   message += "ゴーストモード: " + (g_GhostMode ? "ON" : "OFF") + "\n";
   message += "ナンピンスキップレベル: " + IntegerToString((int)NanpinSkipLevel) + "\n\n";
   
   // 【レイアウト設定】情報を追加
   message += "【レイアウト設定】\n";
   message += "レイアウトパターン: " + GetLayoutPatternText() + "\n";
   message += "パネル位置: X=" + IntegerToString(g_EffectivePanelX) + ", Y=" + IntegerToString(g_EffectivePanelY) + "\n";
   message += "テーブル位置: X=" + IntegerToString(g_EffectiveTableX) + ", Y=" + IntegerToString(g_EffectiveTableY) + "\n\n";
   
   message += "【エントリー戦略設定】\n";
   message += "常時エントリー戦略: " + GetConstantEntryStrategyState() + "\n";
   message += "偶数/奇数時間戦略: " + GetEvenOddStrategyState() + "\n\n";
   message += "【ナンピン設定】\n";
   message += "ナンピン機能: " + (EnableNanpin ? "有効" : "無効") + "\n";
   message += "ナンピンインターバル: " + IntegerToString(NanpinInterval) + "分\n";

   // 決済後インターバル機能の情報を追加
   message += "\n【決済後インターバル機能】\n";
   message += "決済後インターバル: " + (EnableCloseInterval ? "有効" : "無効") + "\n";
   if(EnableCloseInterval) {
      message += "インターバル時間: " + IntegerToString(CloseInterval) + "分\n";
   }

   message += "最大スプレッド: " + IntegerToString(MaxSpreadPoints) + "ポイント\n\n";
   
   message += "【表示設定】\n";
   message += "平均取得単価表示: " + (g_AvgPriceVisible ? "表示" : "非表示") + "\n";
   message += "平均取得単価計算: " + GetAvgPriceCalcModeString(AvgPriceCalculationMode) + "\n\n";
   
   message += "【利確設定】\n";
   message += "利確モード: ";
   message += EnableTakeProfit ? "有効（成行決済）" : "無効";
   message += "\n";
   message += "利確ポイント: " + IntegerToString(TakeProfitPoints) + "\n\n";
   
   message += "【トレーリングストップ】\n";
   message += "トレーリングストップ: " + (EnableTrailingStop ? "有効" : "無効") + "\n";
   
   // 建値決済機能の情報を追加
   message += "\n【建値決済機能】\n";
   message += "ポジション数建値決済: " + (EnableBreakEvenByPositions ? "有効" : "無効") + "\n";
   if(EnableBreakEvenByPositions) {
      message += "最低ポジション数: " + IntegerToString(BreakEvenMinPositions) + "\n";
      message += "建値利益: " + DoubleToString(BreakEvenProfit, 2) + "\n";
   }
   
   // メッセージボックスを表示
   MessageBox(message, title, MB_ICONINFORMATION);
}


//+------------------------------------------------------------------+
//| 平均取得単価表示/非表示切替                                       |
//+------------------------------------------------------------------+
void ToggleAveragePriceVisibility(bool visible)
{
if(visible)
{
   // 表示ONの場合は平均取得価格ラインを更新表示
   UpdateAveragePriceLines(0); // Buy側
   UpdateAveragePriceLines(1); // Sell側
}
else
{
   // 表示OFFの場合はラインを削除
   DeleteAllLines();
}

ChartRedraw(); // チャートを再描画
}

//+------------------------------------------------------------------+
//| 水平線を作成                                                     |
//+------------------------------------------------------------------+
void CreateHorizontalLine(string lineName, double price, color lineColor, int lineStyle, int lineWidth)
{
// オブジェクト名にプレフィックスを追加（複数チャート対策）
string objectName = g_ObjectPrefix + lineName;

#ifdef __MQL5__
   // 既存のオブジェクトがある場合は価格のみ更新（ちらつき防止）
   if(ObjectFind(0, objectName) >= 0)
   {
      ObjectSetDouble(0, objectName, OBJPROP_PRICE, price);
      ObjectSetInteger(0, objectName, OBJPROP_ZORDER, -100);
      ObjectSetInteger(0, objectName, OBJPROP_BACK, true);
      return;
   }

   // 新規作成
   ObjectCreate(0, objectName, OBJ_HLINE, 0, 0, price);
   ObjectSetInteger(0, objectName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, objectName, OBJPROP_STYLE, lineStyle);
   ObjectSetInteger(0, objectName, OBJPROP_WIDTH, lineWidth);
   ObjectSetInteger(0, objectName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objectName, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, objectName, OBJPROP_SELECTED, false);
   ObjectSetInteger(0, objectName, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, objectName, OBJPROP_ZORDER, -100); // 完全に背景に配置
#else
   // 既存のオブジェクトがある場合は価格のみ更新（ちらつき防止）
   if(ObjectFind(objectName) >= 0)
   {
      ObjectSet(objectName, OBJPROP_PRICE1, price);
      ObjectSet(objectName, OBJPROP_ZORDER, -100);
      ObjectSet(objectName, OBJPROP_BACK, true);
      return;
   }

   // 新規作成
   ObjectCreate(objectName, OBJ_HLINE, 0, 0, price);
   ObjectSet(objectName, OBJPROP_COLOR, lineColor);
   ObjectSet(objectName, OBJPROP_STYLE, lineStyle);
   ObjectSet(objectName, OBJPROP_WIDTH, lineWidth);
   ObjectSet(objectName, OBJPROP_BACK, true);
   ObjectSet(objectName, OBJPROP_SELECTABLE, true);
   ObjectSet(objectName, OBJPROP_SELECTED, false);
   ObjectSet(objectName, OBJPROP_HIDDEN, true);
   ObjectSet(objectName, OBJPROP_ZORDER, -100); // 完全に背景に配置
#endif

// オブジェクト名を保存
SaveObjectName(objectName, g_LineNames, g_LineObjectCount);
}



//+------------------------------------------------------------------+
//| 価格ラベルを作成                                                  |
//+------------------------------------------------------------------+
void CreatePriceLabel(string labelName, string text, double price, color textColor, bool isLeft)
{
// オブジェクト名にプレフィックスを追加（複数チャート対策）
string objectName = g_ObjectPrefix + labelName;

// 既存のラベルがあれば削除
#ifdef __MQL5__
   if(ObjectFind(0, objectName) >= 0)
      ObjectDelete(0, objectName);
#else
   if(ObjectFind(objectName) >= 0)
      ObjectDelete(objectName);
#endif
   
// ラベルの作成
datetime labelTime = TimeCurrent() + 1800; // 現在時刻から30分後の位置に表示

#ifdef __MQL5__
   ObjectCreate(0, objectName, OBJ_TEXT, 0, labelTime, price + (isLeft ? 25*_Point : -25*_Point));
   ObjectSetString(0, objectName, OBJPROP_TEXT, text);
   ObjectSetString(0, objectName, OBJPROP_FONT, "Segoe UI Semibold");
   ObjectSetInteger(0, objectName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, objectName, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, objectName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objectName, OBJPROP_SELECTABLE, false);
#else
   ObjectCreate(objectName, OBJ_TEXT, 0, labelTime, price + (isLeft ? 25*Point : -25*Point));
   ObjectSetText(objectName, text, 8, "Arial Bold", textColor);
   ObjectSet(objectName, OBJPROP_BACK, false);
   ObjectSet(objectName, OBJPROP_SELECTABLE, false);
#endif

// オブジェクト名を保存
SaveObjectName(objectName, g_LineNames, g_LineObjectCount);
}
//+------------------------------------------------------------------+
//| すべてのラインを削除 - ボタン保護版                               |
//+------------------------------------------------------------------+
void DeleteAllLines()
{
   // チャート上のすべてのオブジェクトを検索して関連するラインを削除
   #ifdef __MQL5__
      for(int i = ObjectsTotal(0, 0, -1) - 1; i >= 0; i--)
      {
         string name = ObjectName(0, i, 0, -1);
   #else
      for(int i = ObjectsTotal() - 1; i >= 0; i--)
      {
         string name = ObjectName(i);
   #endif
      
      // 自分のEAのオブジェクトのみを対象にする
      if(StringFind(name, g_ObjectPrefix) != 0) 
         continue;
      
      // GUIボタンを保護 - 重要
      if(StringFind(name, "btn") >= 0 || StringFind(name, "Panel") >= 0 || StringFind(name, "Title") >= 0)
         continue;
      
      // 平均価格ラインとTP関連のオブジェクトを削除
      if(StringFind(name, "AvgPrice") >= 0 || 
         StringFind(name, "TPLine") >= 0 || 
         StringFind(name, "Label") >= 0 || 
         StringFind(name, "LimitTP") >= 0)
      {
         #ifdef __MQL5__
            ObjectDelete(0, name);
         #else
            ObjectDelete(name);
         #endif
      }
   }
   
   // 配列に保存されたオブジェクトも削除
   for(int i = 0; i < g_LineObjectCount; i++)
   {
      #ifdef __MQL5__
         if(ObjectFind(0, g_LineNames[i]) >= 0)
      #else
         if(ObjectFind(g_LineNames[i]) >= 0)
      #endif
      {
         // ここでもボタン保護
         if(StringFind(g_LineNames[i], "btn") >= 0)
            continue;
            
         #ifdef __MQL5__
            ObjectDelete(0, g_LineNames[i]);
         #else
            ObjectDelete(g_LineNames[i]);
         #endif
      }
   }
   
   // 明示的に特定のオブジェクト名を指定して削除
   string specificObjects[12]; // 配列サイズを宣言
   
   // 各要素に個別に値を代入
   specificObjects[0] = g_ObjectPrefix + "AvgPriceBuy";
   specificObjects[1] = g_ObjectPrefix + "AvgPriceSell";
   specificObjects[2] = g_ObjectPrefix + "TPLineBuy";
   specificObjects[3] = g_ObjectPrefix + "TPLineSell";
   specificObjects[4] = g_ObjectPrefix + "AvgPriceLabelBuy";
   specificObjects[5] = g_ObjectPrefix + "AvgPriceLabelSell";
   specificObjects[6] = g_ObjectPrefix + "TPLabelBuy";
   specificObjects[7] = g_ObjectPrefix + "TPLabelSell";
   specificObjects[8] = g_ObjectPrefix + "LimitTPBuy";
   specificObjects[9] = g_ObjectPrefix + "LimitTPSell";
   specificObjects[10] = g_ObjectPrefix + "LimitTPLabelBuy";
   specificObjects[11] = g_ObjectPrefix + "LimitTPLabelSell";
   
   for(int i = 0; i < ArraySize(specificObjects); i++)
   {
      #ifdef __MQL5__
         if(ObjectFind(0, specificObjects[i]) >= 0)
         {
            ObjectDelete(0, specificObjects[i]);
         }
      #else
         if(ObjectFind(specificObjects[i]) >= 0)
         {
            ObjectDelete(specificObjects[i]);
         }
      #endif
   }
   
   // カウンターをリセット
   g_LineObjectCount = 0;
   
   // チャートの再描画を強制
   ChartRedraw();
}


//+------------------------------------------------------------------+
//| 決済時にラインを削除する関数                                      |
//+------------------------------------------------------------------+
void CleanupLinesOnClose(int side)
{
    // 方向に対応するラインを削除
    string direction = (side == 0) ? "Buy" : "Sell";
    
    // 平均価格ライン、TPライン、各ラベルを削除
    string objects[6];
    objects[0] = g_ObjectPrefix + "AvgPrice" + direction;
    objects[1] = g_ObjectPrefix + "TPLine" + direction;
    objects[2] = g_ObjectPrefix + "AvgPriceLabel" + direction;
    objects[3] = g_ObjectPrefix + "TPLabel" + direction;
    objects[4] = g_ObjectPrefix + "LimitTP" + direction;
    objects[5] = g_ObjectPrefix + "LimitTPLabel" + direction;
    
    for(int i = 0; i < ArraySize(objects); i++)
    {
        #ifdef __MQL5__
            if(ObjectFind(0, objects[i]) >= 0)
            {
                ObjectDelete(0, objects[i]);
            }
        #else
            if(ObjectFind(objects[i]) >= 0)
            {
                ObjectDelete(objects[i]);
            }
        #endif
    }
    
    // チャートを再描画
    ChartRedraw();
}

//+------------------------------------------------------------------+
//| ポジションがない場合にラインを削除するチェック関数                 |
//+------------------------------------------------------------------+
void CheckAndDeleteLinesIfNoPositions()
{
   // Buy方向のチェック
   int buyPositions = position_count(OP_BUY);
   int buyGhosts = ghost_position_count(OP_BUY);
   
   // Buy方向のポジションがゼロならラインを削除
   if(buyPositions == 0 && buyGhosts == 0)
   {
      CleanupLinesOnClose(0); // Buy側のライン削除
   }
   
   // Sell方向のチェック
   int sellPositions = position_count(OP_SELL);
   int sellGhosts = ghost_position_count(OP_SELL);
   
   // Sell方向のポジションがゼロならラインを削除
   if(sellPositions == 0 && sellGhosts == 0)
   {
      CleanupLinesOnClose(1); // Sell側のライン削除
   }
}