//+------------------------------------------------------------------+
//|                   Hosopi 3 - GUI関連関数                         |
//|                         Copyright 2025                           |
//+------------------------------------------------------------------+
#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Utils.mqh"
#include "Hosopi3_Trading.mqh"

//+------------------------------------------------------------------+
//| GUIを作成する - 修正版                                           |
//+------------------------------------------------------------------+
void CreateGUI()
{
   DeleteGUI(); // 既存のGUIを削除
   g_PanelObjectCount = 0; // オブジェクトカウントリセット
   
   // パネル位置を100上げる
   int adjustedPanelY = PanelY;
   
   // メインパネル背景
   CreatePanel("MainPanel", PanelX, adjustedPanelY, PANEL_WIDTH, PANEL_HEIGHT + 250, COLOR_PANEL_BG, COLOR_PANEL_BORDER); // 高さを拡大
   
   // パネルタイトル
   CreateTitleBar("TitleBar", PanelX, adjustedPanelY, PANEL_WIDTH, TITLE_HEIGHT, COLOR_TITLE_BG, PanelTitle);
   
   int buttonWidth = (PANEL_WIDTH - (PANEL_MARGIN * 3)) / 2; // 2列のボタン用
   int fullWidth = PANEL_WIDTH - (PANEL_MARGIN * 2); // 横いっぱいのボタン用
   
   // ========== 行1: 決済ボタン ==========
   int row1Y = adjustedPanelY + TITLE_HEIGHT + PANEL_MARGIN;
   
   // Sell決済ボタン (左)
   CreateButton("btnCloseSell", "Close Sell", PanelX + PANEL_MARGIN, row1Y, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_SELL, COLOR_TEXT_LIGHT);
   
   // Buy決済ボタン (右)
   CreateButton("btnCloseBuy", "Close Buy", PanelX + PANEL_MARGIN * 2 + buttonWidth, row1Y, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_BUY, COLOR_TEXT_LIGHT);
   
   // ========== 行2: 全決済ボタン ==========
   int row2Y = row1Y + BUTTON_HEIGHT + PANEL_MARGIN;
   
   // 全決済ボタン（横いっぱい）
   CreateButton("btnCloseAll", "Close All", PanelX + PANEL_MARGIN, row2Y, fullWidth, BUTTON_HEIGHT, COLOR_BUTTON_CLOSE_ALL, COLOR_TEXT_DARK);
   
   // ========== 行3: 直接エントリーボタン (新規追加) ==========
   int row3Y = row2Y + BUTTON_HEIGHT + PANEL_MARGIN * 2; // 間隔を広く
   
   // セクションラベル
   CreateLabel("lblDirectEntry", "【直接エントリー】", PanelX + PANEL_MARGIN, row3Y - 5, COLOR_TEXT_LIGHT);
   
   // Sellエントリーボタン (左)
   CreateButton("btnDirectSell", "SELL NOW", PanelX + PANEL_MARGIN, row3Y + 15, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_SELL, COLOR_TEXT_LIGHT);
   
   // Buyエントリーボタン (右)
   CreateButton("btnDirectBuy", "BUY NOW", PanelX + PANEL_MARGIN * 2 + buttonWidth, row3Y + 15, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_BUY, COLOR_TEXT_LIGHT);
   
   // ========== 行4: 途中からエントリーボタン (新規追加) ==========
   int row4Y = row3Y + BUTTON_HEIGHT + PANEL_MARGIN * 2 + 15; // 間隔を広く
   
   // セクションラベル
   CreateLabel("lblLevelEntry", "【レベル指定エントリー】", PanelX + PANEL_MARGIN, row4Y - 5, COLOR_TEXT_LIGHT);
   
   // Sellエントリーボタン (左)
   CreateButton("btnLevelSell", "SELL Level 3", PanelX + PANEL_MARGIN, row4Y + 15, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_SELL, COLOR_TEXT_LIGHT);
   
   // Buyエントリーボタン (右)
   CreateButton("btnLevelBuy", "BUY Level 3", PanelX + PANEL_MARGIN * 2 + buttonWidth, row4Y + 15, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_BUY, COLOR_TEXT_LIGHT);
   
   // ========== 行5: 設定セクション ==========
   int row5Y = row4Y + BUTTON_HEIGHT + PANEL_MARGIN * 2 + 15; // 間隔を広く
   
   // セクションラベル
   CreateLabel("lblSettings", "【設定】", PanelX + PANEL_MARGIN, row5Y - 5, COLOR_TEXT_LIGHT);
   
   // Ghostモードボタン（横いっぱい）
   CreateButton("btnGhostToggle", "GHOST " + (g_GhostMode ? "ON" : "OFF"), 
               PanelX + PANEL_MARGIN, row5Y + 15, fullWidth, BUTTON_HEIGHT, 
               g_GhostMode ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE, COLOR_TEXT_LIGHT);
   
   // ========== 行6: ゴーストリセットボタン ==========
   int row6Y = row5Y + BUTTON_HEIGHT + PANEL_MARGIN + 15;
   
   // ゴーストリセットボタン（横いっぱい）
   CreateButton("btnResetGhost", "GHOST RESET", PanelX + PANEL_MARGIN, row6Y, fullWidth, BUTTON_HEIGHT, COLOR_BUTTON_INACTIVE, COLOR_TEXT_LIGHT);
   
   // ========== 行7: 平均取得単価表示切替ボタン ==========
   int row7Y = row6Y + BUTTON_HEIGHT + PANEL_MARGIN;
   
   // 平均取得単価表示切替ボタン（横いっぱい）
   CreateButton("btnToggleAvgPrice", "AVG PRICE " + (g_AvgPriceVisible ? "ON" : "OFF"), 
               PanelX + PANEL_MARGIN, row7Y, fullWidth, BUTTON_HEIGHT, 
               g_AvgPriceVisible ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE, COLOR_TEXT_LIGHT);
   
   // ========== 行8: 自動売買切替ボタン ==========
   int row8Y = row7Y + BUTTON_HEIGHT + PANEL_MARGIN;
   
   // 自動売買切替ボタン（横いっぱい）
   CreateButton("btnAutoTrading", "AUTO TRADING " + (g_AutoTrading ? "ON" : "OFF"), 
               PanelX + PANEL_MARGIN, row8Y, fullWidth, BUTTON_HEIGHT, 
               g_AutoTrading ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE, COLOR_TEXT_LIGHT);
   
   // ========== 行9: ナンピン切替ボタン ==========
   int row9Y = row8Y + BUTTON_HEIGHT + PANEL_MARGIN;
   
   // ナンピン切替ボタン（横いっぱい）
   CreateButton("btnNanpin", "NANPIN " + (g_EnableNanpin ? "ON" : "OFF"), 
               PanelX + PANEL_MARGIN, row9Y, fullWidth, BUTTON_HEIGHT, 
               g_EnableNanpin ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE, COLOR_TEXT_LIGHT);
   
   // ========== 行10: テクニカル指標利用 ==========
   int row10Y = row9Y + BUTTON_HEIGHT + PANEL_MARGIN;
   
   // テクニカル指標による入出切替ボタン（横いっぱい）
   CreateButton("btnIndicatorsEntry", "INDICATORS " + (g_EnableIndicatorsEntry ? "ON" : "OFF"), 
               PanelX + PANEL_MARGIN, row10Y, fullWidth, BUTTON_HEIGHT, 
               g_EnableIndicatorsEntry ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE, COLOR_TEXT_LIGHT);
   
   // ========== 行11: 情報表示ボタン ==========
   int row11Y = row10Y + BUTTON_HEIGHT + PANEL_MARGIN;
   
   // ロット情報表示ボタン (左)
   CreateButton("btnShowLotTable", "Lot Table", PanelX + PANEL_MARGIN, row11Y, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_NEUTRAL, COLOR_TEXT_LIGHT);
   
   // 設定情報表示ボタン (右)
   CreateButton("btnShowSettings", "Settings", PanelX + PANEL_MARGIN * 2 + buttonWidth, row11Y, buttonWidth, BUTTON_HEIGHT, COLOR_BUTTON_NEUTRAL, COLOR_TEXT_LIGHT);
   
   // パネルの高さを調整
   int panelHeight = row11Y + BUTTON_HEIGHT + PANEL_MARGIN - adjustedPanelY;
   ObjectSet(g_ObjectPrefix + "MainPanel" + "BG", OBJPROP_YSIZE, panelHeight);
   
   ChartRedraw(); // チャートを再描画
}

//+------------------------------------------------------------------+
//| ラベル作成 - フォントをMS Gothicに変更                           |
//+------------------------------------------------------------------+
void CreateLabel(string name, string text, int x, int y, color textColor)
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string objectName = g_ObjectPrefix + name;
   
   ObjectCreate(objectName, OBJ_LABEL, 0, 0, 0);
   ObjectSet(objectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(objectName, OBJPROP_XDISTANCE, x);
   ObjectSet(objectName, OBJPROP_YDISTANCE, y);
   // MS ゴシックフォントを使用
   ObjectSetText(objectName, text, 9, "MS Gothic", textColor);
   ObjectSet(objectName, OBJPROP_SELECTABLE, false);
   
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
   
   // タイトルテキスト
   string textName = objectName + "Text";
   ObjectCreate(textName, OBJ_LABEL, 0, 0, 0);
   ObjectSet(textName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(textName, OBJPROP_XDISTANCE, x + 10);
   ObjectSet(textName, OBJPROP_YDISTANCE, y + 8);
   ObjectSetText(textName, title, 10, "Arial", COLOR_TITLE_TEXT);
   ObjectSet(textName, OBJPROP_SELECTABLE, false);
   
   // オブジェクト名を保存
   SaveObjectName(bgName, g_PanelNames, g_PanelObjectCount);
   SaveObjectName(textName, g_PanelNames, g_PanelObjectCount);
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
   
   // ボタン本体
   ObjectCreate(objectName, OBJ_BUTTON, 0, 0, 0);
   ObjectSet(objectName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(objectName, OBJPROP_XDISTANCE, x);
   ObjectSet(objectName, OBJPROP_YDISTANCE, y);
   ObjectSet(objectName, OBJPROP_XSIZE, width);
   ObjectSet(objectName, OBJPROP_YSIZE, height);
   // MS ゴシックフォントを使用
   ObjectSetText(objectName, text, 9, "MS Gothic", textColor);
   ObjectSet(objectName, OBJPROP_BGCOLOR, bgColor);
   ObjectSet(objectName, OBJPROP_BORDER_COLOR, ColorDarken(bgColor, 20));
   ObjectSet(objectName, OBJPROP_COLOR, textColor);
   ObjectSet(objectName, OBJPROP_SELECTABLE, false);
   
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
//| 表示設定ダイアログを作成するための補助関数                         |
//+------------------------------------------------------------------+
void ShowSettingsDialog()
{
   // ダイアログタイトル
   string title = "Hosopi 3 - 設定状態";
   
   // ダイアログ内容を構築
   string message = "現在の設定状態:\n\n";
   
   // 各設定の状態
   message += "自動売買: " + (g_AutoTrading ? "ON" : "OFF") + "\n";
   message += "ゴーストモード: " + (g_GhostMode ? "ON" : "OFF") + "\n";
   message += "ナンピン: " + (g_EnableNanpin ? "ON" : "OFF") + "\n";
   message += "ゴーストエントリー: " + (g_EnableGhostEntry ? "ON" : "OFF") + "\n";
   message += "テクニカル指標エントリー: " + (g_EnableIndicatorsEntry ? "ON" : "OFF") + "\n";
   message += "時間エントリー: " + (g_EnableTimeEntry ? "ON" : "OFF") + "\n";
   message += "固定利確: " + (g_EnableFixedTP ? "ON" : "OFF") + "\n";
   message += "テクニカル指標利確: " + (g_EnableIndicatorsTP ? "ON" : "OFF") + "\n";
   message += "トレーリングストップ: " + (g_EnableTrailingStop ? "ON" : "OFF") + "\n";
   message += "偶数/奇数時間エントリー: " + (g_UseEvenOddHoursEntry ? "ON" : "OFF") + "\n";
   
   // 主要パラメータ
   message += "\n主要パラメータ:\n";
   message += "ナンピンスキップレベル: " + EnumToString(NanpinSkipLevel) + "\n";
   message += "最大ポジション数: " + EnumToString(MaxPositions) + "\n";
   message += "エントリー方向: " + GetEntryModeString(EntryMode) + "\n";
   
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
      if(ObjectFind(g_PanelNames[i]) >= 0)
         ObjectDelete(g_PanelNames[i]);
   }
   
   g_PanelObjectCount = 0;
   ChartRedraw(); // チャートを再描画
}

//+------------------------------------------------------------------+
//| GUIを更新する - 修正版                                           |
//+------------------------------------------------------------------+
void UpdateGUI()
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string ghostBtnPrefix = g_ObjectPrefix + "btnGhostToggle";
   string avgPriceBtnPrefix = g_ObjectPrefix + "btnToggleAvgPrice";
   string autoTradingBtnPrefix = g_ObjectPrefix + "btnAutoTrading";
   string nanpinBtnPrefix = g_ObjectPrefix + "btnNanpin";
   string indicatorsBtnPrefix = g_ObjectPrefix + "btnIndicatorsEntry";
   
   // Ghost ON/OFFボタン状態更新
   color ghostButtonColor = g_GhostMode ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE;
   ObjectSet(ghostBtnPrefix + "BG", OBJPROP_BGCOLOR, ghostButtonColor);
   ObjectSet(ghostBtnPrefix + "BG", OBJPROP_COLOR, ColorDarken(ghostButtonColor, 20));
   ObjectSet(ghostBtnPrefix, OBJPROP_BGCOLOR, ghostButtonColor);
   ObjectSet(ghostBtnPrefix, OBJPROP_BORDER_COLOR, ColorDarken(ghostButtonColor, 20));
   ObjectSetText(ghostBtnPrefix, g_GhostMode ? "GHOST ON" : "GHOST OFF", 9, "Arial", COLOR_TEXT_LIGHT);
   
   // 平均取得単価表示ボタン状態更新
   color avgPriceButtonColor = g_AvgPriceVisible ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE;
   ObjectSet(avgPriceBtnPrefix + "BG", OBJPROP_BGCOLOR, avgPriceButtonColor);
   ObjectSet(avgPriceBtnPrefix + "BG", OBJPROP_COLOR, ColorDarken(avgPriceButtonColor, 20));
   ObjectSet(avgPriceBtnPrefix, OBJPROP_BGCOLOR, avgPriceButtonColor);
   ObjectSet(avgPriceBtnPrefix, OBJPROP_BORDER_COLOR, ColorDarken(avgPriceButtonColor, 20));
   ObjectSetText(avgPriceBtnPrefix, g_AvgPriceVisible ? "AVG PRICE ON" : "AVG PRICE OFF", 9, "Arial", COLOR_TEXT_LIGHT);
   
   // 自動売買ボタン状態更新
   color autoTradingButtonColor = g_AutoTrading ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE;
   ObjectSet(autoTradingBtnPrefix + "BG", OBJPROP_BGCOLOR, autoTradingButtonColor);
   ObjectSet(autoTradingBtnPrefix + "BG", OBJPROP_COLOR, ColorDarken(autoTradingButtonColor, 20));
   ObjectSet(autoTradingBtnPrefix, OBJPROP_BGCOLOR, autoTradingButtonColor);
   ObjectSet(autoTradingBtnPrefix, OBJPROP_BORDER_COLOR, ColorDarken(autoTradingButtonColor, 20));
   ObjectSetText(autoTradingBtnPrefix, g_AutoTrading ? "AUTO TRADING ON" : "AUTO TRADING OFF", 9, "Arial", COLOR_TEXT_LIGHT);
   
   // ナンピンボタン状態更新
   color nanpinButtonColor = g_EnableNanpin ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE;
   ObjectSet(nanpinBtnPrefix + "BG", OBJPROP_BGCOLOR, nanpinButtonColor);
   ObjectSet(nanpinBtnPrefix + "BG", OBJPROP_COLOR, ColorDarken(nanpinButtonColor, 20));
   ObjectSet(nanpinBtnPrefix, OBJPROP_BGCOLOR, nanpinButtonColor);
   ObjectSet(nanpinBtnPrefix, OBJPROP_BORDER_COLOR, ColorDarken(nanpinButtonColor, 20));
   ObjectSetText(nanpinBtnPrefix, g_EnableNanpin ? "NANPIN ON" : "NANPIN OFF", 9, "Arial", COLOR_TEXT_LIGHT);
   
   // テクニカル指標ボタン状態更新
   color indicatorsButtonColor = g_EnableIndicatorsEntry ? COLOR_BUTTON_ACTIVE : COLOR_BUTTON_INACTIVE;
   ObjectSet(indicatorsBtnPrefix + "BG", OBJPROP_BGCOLOR, indicatorsButtonColor);
   ObjectSet(indicatorsBtnPrefix + "BG", OBJPROP_COLOR, ColorDarken(indicatorsButtonColor, 20));
   ObjectSet(indicatorsBtnPrefix, OBJPROP_BGCOLOR, indicatorsButtonColor);
   ObjectSet(indicatorsBtnPrefix, OBJPROP_BORDER_COLOR, ColorDarken(indicatorsButtonColor, 20));
   ObjectSetText(indicatorsBtnPrefix, g_EnableIndicatorsEntry ? "INDICATORS ON" : "INDICATORS OFF", 9, "Arial", COLOR_TEXT_LIGHT);
   
   ChartRedraw(); // チャートを再描画
}


//+------------------------------------------------------------------+
//| ボタンクリックを処理する - 拡張版                                |
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
   ObjectSet(originalName, OBJPROP_STATE, false);
   
   // Buy Close
   if(buttonName == "btnCloseBuy")
   {
      Print("Close Buy clicked");
      position_close(0);
      UpdateGUI();
   }
   
   // Sell Close
   else if(buttonName == "btnCloseSell")
   {
      Print("Close Sell clicked");
      position_close(1);
      UpdateGUI();
   }
   
   // Close All
   else if(buttonName == "btnCloseAll")
   {
      Print("Close All clicked");
      position_close(0);
      position_close(1);
      UpdateGUI();
   }
   
   // Ghost Toggle
   else if(buttonName == "btnGhostToggle" || buttonName == "btnGhostMode")
   {
      g_GhostMode = !g_GhostMode;
      
      // ゴーストモードをOFFにした場合は、すべてのゴーストをリセット
      if(!g_GhostMode)
      {
         ResetGhost(OP_BUY);
         ResetGhost(OP_SELL);
      }
      else
      {
         // ゴーストモードをONにした場合、決済済みフラグをリセット
         g_BuyGhostClosed = false;
         g_SellGhostClosed = false;
         SaveGhostPositionsToGlobal();
      }
      
      UpdateGUI();
      Print("ゴーストモードを", g_GhostMode ? "ON" : "OFF", "に切り替えました");
   }
   
   // Reset Ghost
   else if(buttonName == "btnResetGhost")
   {
      Print("Reset Ghost clicked - ゴーストデータをリセットします");
      
      // ゴーストオブジェクトを削除
      DeleteAllGhostObjectsByType(OP_BUY);
      DeleteAllGhostObjectsByType(OP_SELL);
      
      // ゴーストポジションをリセット
      ResetGhost(OP_BUY);  // 両方のゴーストをリセット
      ResetGhost(OP_SELL);
      
      // グローバル変数からも完全にクリア
      ClearGhostPositionsFromGlobal();
      
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
      
      Print("すべてのゴーストポジションをリセットしました");
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
      Print("平均価格ラインを", g_AvgPriceVisible ? "表示" : "非表示", "に切り替えました");
   }
   
   // 自動売買切り替えボタン
   else if(buttonName == "btnAutoTrading")
   {
      g_AutoTrading = !g_AutoTrading;
      UpdateGUI();
      Print("自動売買を", g_AutoTrading ? "ON" : "OFF", "に切り替えました");
   }
   
   // ナンピン切り替えボタン
   else if(buttonName == "btnNanpin")
   {
      g_EnableNanpin = !g_EnableNanpin;
      UpdateGUI();
      Print("ナンピン機能を", g_EnableNanpin ? "ON" : "OFF", "に切り替えました");
   }
   
   // テクニカル指標切り替えボタン
   else if(buttonName == "btnIndicatorsEntry")
   {
      g_EnableIndicatorsEntry = !g_EnableIndicatorsEntry;
      UpdateGUI();
      Print("テクニカル指標によるエントリーを", g_EnableIndicatorsEntry ? "ON" : "OFF", "に切り替えました");
   }
   
   // ===== 新規追加ボタン - 直接エントリー機能 =====
   
   // 直接Buy
   else if(buttonName == "btnDirectBuy")
   {
      Print("直接Buyボタンがクリックされました");
      ExecuteDiscretionaryEntry(OP_BUY);
      UpdatePositionTable();
   }
   
   // 直接Sell
   else if(buttonName == "btnDirectSell")
   {
      Print("直接Sellボタンがクリックされました");
      ExecuteDiscretionaryEntry(OP_SELL);
      UpdatePositionTable();
   }
   
   // ===== 新規追加ボタン - レベル指定エントリー機能 =====
   
   // レベル指定Buy
   else if(buttonName == "btnLevelBuy")
   {
      Print("レベル指定Buyボタンがクリックされました");
      // デフォルトでレベル3を指定（GUI上のボタンテキストと合わせる）
      int entryLevel = 3;
      ExecuteEntryFromLevel(OP_BUY, entryLevel);
      UpdatePositionTable();
   }
   
   // レベル指定Sell
   else if(buttonName == "btnLevelSell")
   {
      Print("レベル指定Sellボタンがクリックされました");
      // デフォルトでレベル3を指定（GUI上のボタンテキストと合わせる）
      int entryLevel = 3;
      ExecuteEntryFromLevel(OP_SELL, entryLevel);
      UpdatePositionTable();
   }
   
   // ロットテーブル表示ボタン
   else if(buttonName == "btnShowLotTable")
   {
      Print("ロットテーブル表示ボタンがクリックされました");
      CreateLotTableDialog();
   }
   
   // 設定情報表示ボタン
   else if(buttonName == "btnShowSettings")
   {
      Print("設定情報表示ボタンがクリックされました");
      ShowSettingsDialog();
   }
   
   // 未知のボタンの場合
   else
   {
      Print("未知のボタンがクリックされました: ", buttonName);
   }
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
void CreateHorizontalLine(string name, double price, color lineColor, int style, int width)
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string objectName = g_ObjectPrefix + name;
   
   if(ObjectFind(objectName) >= 0)
      ObjectDelete(objectName);
      
   ObjectCreate(objectName, OBJ_HLINE, 0, 0, price);
   ObjectSet(objectName, OBJPROP_COLOR, lineColor);
   ObjectSet(objectName, OBJPROP_STYLE, style);
   ObjectSet(objectName, OBJPROP_WIDTH, width);
   ObjectSet(objectName, OBJPROP_BACK, false);
   ObjectSet(objectName, OBJPROP_SELECTABLE, true);
   ObjectSet(objectName, OBJPROP_SELECTED, false);
   ObjectSet(objectName, OBJPROP_HIDDEN, true);
   
   // オブジェクト名を保存
   SaveObjectName(objectName, g_LineNames, g_LineObjectCount);
}

//+------------------------------------------------------------------+
//| 価格ラベルを作成                                                  |
//+------------------------------------------------------------------+
void CreatePriceLabel(string name, string text, double price, color textColor, bool isAbove)
{
   // オブジェクト名にプレフィックスを追加（複数チャート対策）
   string objectName = g_ObjectPrefix + name;
   
   // 既存のラベルがあれば削除
   if(ObjectFind(objectName) >= 0)
      ObjectDelete(objectName);
      
   // ラベルの作成
   datetime labelTime = TimeCurrent() + 1800; // 現在時刻から30分後の位置に表示
   ObjectCreate(objectName, OBJ_TEXT, 0, labelTime, price + (isAbove ? 25*Point : -25*Point));
   ObjectSetText(objectName, text, 8, "Arial Bold", textColor);
   ObjectSet(objectName, OBJPROP_BACK, false);
   ObjectSet(objectName, OBJPROP_SELECTABLE, false);
   
   // オブジェクト名を保存
   SaveObjectName(objectName, g_LineNames, g_LineObjectCount);
}

//+------------------------------------------------------------------+
//| すべてのラインを削除                                              |
//+------------------------------------------------------------------+
void DeleteAllLines()
{
   // 配列に保存されたオブジェクトを削除
   for(int i = 0; i < g_LineObjectCount; i++)
   {
      if(ObjectFind(g_LineNames[i]) >= 0)
         ObjectDelete(g_LineNames[i]);
   }
   
   // 追加: 平均価格関連の命名パターンを持つすべてのオブジェクトを検索して削除（ボタンは保護）
   for(int i = ObjectsTotal() - 1; i >= 0; i--)
   {
      string name = ObjectName(i);
      
      // 現在のEAのプレフィックスを持つオブジェクトのみ処理（複数チャート対策）
      if(StringFind(name, g_ObjectPrefix) != 0)
         continue;
         
      // ボタンや他の重要なGUI要素を保護
      if(StringFind(name, "btn") >= 0 ||       // ボタン
         StringFind(name, "Panel") >= 0 ||     // パネル
         StringFind(name, "Title") >= 0 ||     // タイトル
         StringFind(name, "Table") >= 0)       // テーブル
      {
         continue; // これらのオブジェクトは保護
      }
      
      // 平均価格関連のオブジェクトを検索
      if(StringFind(name, "AvgPrice") >= 0 || 
         StringFind(name, "TpLine") >= 0 || 
         StringFind(name, "TpLabel") >= 0 ||
         StringFind(name, "AvgPriceLabel") >= 0)
      {
         ObjectDelete(name);
      }
   }
   
   // カウンターをリセット
   g_LineObjectCount = 0;
}