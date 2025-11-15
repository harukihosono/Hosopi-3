//+------------------------------------------------------------------+
//|                    Hosopi 3 - テクニカル指標InfoPanel             |
//|                           Copyright 2025                          |
//+------------------------------------------------------------------+
#ifndef HOSOPI3_INFOPANEL_MQH
#define HOSOPI3_INFOPANEL_MQH

#include "Hosopi3_Defines.mqh"
#include "Hosopi3_Enums.mqh"
#include "Hosopi3_StrategyTechnical.mqh"

//+------------------------------------------------------------------+
//| テクニカル指標の状態定義                                           |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_STATE
{
   SIGNAL_NONE = 0,    // シグナルなし（グレー）
   SIGNAL_BUY = 1,     // BUYシグナル（青）
   SIGNAL_SELL = 2     // SELLシグナル（赤）
};

//+------------------------------------------------------------------+
//| テクニカル指標情報構造体                                           |
//+------------------------------------------------------------------+
struct TechnicalIndicatorInfo
{
   string name;              // 指標名
   bool enabled;             // ON/OFF状態
   ENUM_SIGNAL_STATE buySignal;   // BUYシグナル状態
   ENUM_SIGNAL_STATE sellSignal;  // SELLシグナル状態
};

//+------------------------------------------------------------------+
//| InfoPanelクラス                                                  |
//+------------------------------------------------------------------+
class InfoPanelManager
{
private:
   // パネル設定
   int m_panelX;
   int m_panelY;
   int m_panelWidth;
   int m_panelHeight;
   int m_rowHeight;
   bool m_isVisible;

   // 色設定
   color m_bgColor;
   color m_headerColor;
   color m_textColor;
   color m_enabledColor;
   color m_disabledColor;
   color m_buyColor;
   color m_sellColor;
   color m_neutralColor;

   // テクニカル指標データ
   TechnicalIndicatorInfo m_indicators[9];  // 8→9に変更（ボラティリティフィルター追加）
   int m_indicatorCount;

   // オブジェクト名管理
   string m_objectPrefix;

public:
   // コンストラクタ・デストラクタ
   InfoPanelManager();
   ~InfoPanelManager();

   // 初期化・終了処理
   bool Initialize();
   void Deinitialize();

   // パネル管理
   void CreatePanel();
   void UpdatePanel();
   void DeletePanel();
   void CalculatePosition();

   // 指標データ更新
   void UpdateIndicatorStates();

   // 表示制御
   void ShowPanel()
   {
      if(!m_isVisible) {
         Print("InfoPanel: ShowPanel() 開始");
         m_isVisible = true;
         CreatePanel();
         Print("InfoPanel: CreatePanel() 完了、UpdatePositionTableLocation() 実行");
         UpdatePositionTableLocation();
         Print("InfoPanel: ShowPanel() 完了");
      }
   }
   void HidePanel()
   {
      if(m_isVisible) {
         Print("InfoPanel: HidePanel() 開始");
         m_isVisible = false;
         DeletePanel();
         Print("InfoPanel: DeletePanel() 完了、UpdatePositionTableLocation() 実行");
         UpdatePositionTableLocation(); // テーブル位置も元に戻す
         Print("InfoPanel: HidePanel() 完了");
      }
   }
   void TogglePanel()
   {
      if(m_isVisible)
         HidePanel();
      else
         ShowPanel();
   }
   bool IsVisible() { return m_isVisible; }

private:
   // 内部描画関数
   void CreateBackground();
   void CreateHeader();
   void CreateIndicatorRow(int index, TechnicalIndicatorInfo &indicator);
   void UpdateIndicatorRow(int index, TechnicalIndicatorInfo &indicator);

   // ヘルパー関数
   string GenerateObjectName(string baseName);
   color GetSignalColor(ENUM_SIGNAL_STATE state);
   string GetSignalText(ENUM_SIGNAL_STATE state);

public:
   // テーブル位置更新（publicに変更）
   void UpdatePositionTableLocation();
};

//+------------------------------------------------------------------+
//| コンストラクタ                                                    |
//+------------------------------------------------------------------+
InfoPanelManager::InfoPanelManager()
{
   // パネル位置・サイズ設定（メインパネル右側に配置）
   m_panelX = 10; // 初期値、後で動的計算
   m_panelY = 100;
   m_panelWidth = 380; // InfoPanel専用幅
   m_rowHeight = 25;
   m_indicatorCount = 9;  // 8→9に変更（ボラティリティフィルター追加）
   m_panelHeight = 40 + (m_indicatorCount * m_rowHeight) + 30; // ヘッダー + 指標行 + 30
   m_isVisible = true;  // デフォルトで表示

   // 色設定（メインパネルと同じ配色）
   m_bgColor = COLOR_PANEL_BG;
   m_headerColor = COLOR_TITLE_BG;
   m_textColor = COLOR_TITLE_TEXT;
   m_enabledColor = COLOR_BUTTON_ACTIVE;
   m_disabledColor = COLOR_BUTTON_INACTIVE;
   m_buyColor = COLOR_BUTTON_BUY;
   m_sellColor = COLOR_BUTTON_SELL;
   m_neutralColor = C'128,128,128';

   // オブジェクトプレフィックス設定
   m_objectPrefix = g_ObjectPrefix + "InfoPanel_";

   // 指標データ初期化
   m_indicators[0].name = "MA";
   m_indicators[1].name = "RSI";
   m_indicators[2].name = "Bollinger";
   m_indicators[3].name = "RCI";
   m_indicators[4].name = "Stochastic";
   m_indicators[5].name = "CCI";
   m_indicators[6].name = "ADX";
   m_indicators[7].name = IndicatorEntryDisplayName();  // カスタムインジケーター
   m_indicators[8].name = "VolFilter";  // ボラティリティフィルター追加

   for(int i = 0; i < m_indicatorCount; i++)
   {
      m_indicators[i].enabled = false;
      m_indicators[i].buySignal = SIGNAL_NONE;
      m_indicators[i].sellSignal = SIGNAL_NONE;
   }
}

//+------------------------------------------------------------------+
//| デストラクタ                                                      |
//+------------------------------------------------------------------+
InfoPanelManager::~InfoPanelManager()
{
   Deinitialize();
}

//+------------------------------------------------------------------+
//| 初期化                                                            |
//+------------------------------------------------------------------+
bool InfoPanelManager::Initialize()
{
   UpdateIndicatorStates();
   return true;
}

//+------------------------------------------------------------------+
//| 終了処理                                                          |
//+------------------------------------------------------------------+
void InfoPanelManager::Deinitialize()
{
   DeletePanel();
}

//+------------------------------------------------------------------+
//| パネル作成                                                        |
//+------------------------------------------------------------------+
void InfoPanelManager::CreatePanel()
{
   if(!m_isVisible) return;

   // 位置を計算して更新
   CalculatePosition();

   // 既存パネルを削除
   DeletePanel();

   // 背景作成
   CreateBackground();

   // ヘッダー作成
   CreateHeader();

   // 各指標行を作成
   for(int i = 0; i < m_indicatorCount; i++)
   {
      CreateIndicatorRow(i, m_indicators[i]);
   }

   // チャート再描画
   ChartRedraw();
}

//+------------------------------------------------------------------+
//| パネル更新                                                        |
//+------------------------------------------------------------------+
void InfoPanelManager::UpdatePanel()
{
   if(!m_isVisible) return;

   // 指標状態を更新
   UpdateIndicatorStates();

   // 各指標行を更新
   for(int i = 0; i < m_indicatorCount; i++)
   {
      UpdateIndicatorRow(i, m_indicators[i]);
   }

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| パネル削除                                                        |
//+------------------------------------------------------------------+
void InfoPanelManager::DeletePanel()
{
   // InfoPanel専用のオブジェクトを明示的に削除（他のオブジェクトを保護）
   string objectsToDelete[];
   ArrayResize(objectsToDelete, 5);  // 4→5に変更（閉じるボタン追加）
   objectsToDelete[0] = GenerateObjectName("Background");
   objectsToDelete[1] = GenerateObjectName("TitleBar");
   objectsToDelete[2] = GenerateObjectName("TitleText");
   objectsToDelete[3] = GenerateObjectName("ColumnHeaders");
   objectsToDelete[4] = GenerateObjectName("CloseButton");  // 閉じるボタンを追加


   // 基本オブジェクトを削除
   for(int i = 0; i < ArraySize(objectsToDelete); i++)
   {
      if(ObjectFind(0, objectsToDelete[i]) >= 0)
         ObjectDelete(0, objectsToDelete[i]);
   }

   // 指標関連オブジェクトを削除
   for(int i = 0; i < m_indicatorCount; i++)
   {
      ObjectDelete(0, GenerateObjectName("Name_" + IntegerToString(i)));
      ObjectDelete(0, GenerateObjectName("Status_" + IntegerToString(i)));
      ObjectDelete(0, GenerateObjectName("Buy_" + IntegerToString(i)));
      ObjectDelete(0, GenerateObjectName("Sell_" + IntegerToString(i)));
   }

   ChartRedraw();
}

//+------------------------------------------------------------------+
//| 指標状態更新                                                      |
//+------------------------------------------------------------------+
void InfoPanelManager::UpdateIndicatorStates()
{
   // MA
   m_indicators[0].enabled = (MA_Entry_Strategy == MA_ENTRY_ENABLED);
   m_indicators[0].buySignal = m_indicators[0].enabled && CheckMASignal(0) ? SIGNAL_BUY : SIGNAL_NONE;
   m_indicators[0].sellSignal = m_indicators[0].enabled && CheckMASignal(1) ? SIGNAL_SELL : SIGNAL_NONE;

   // RSI
   m_indicators[1].enabled = (RSI_Entry_Strategy == RSI_ENTRY_ENABLED);
   m_indicators[1].buySignal = m_indicators[1].enabled && CheckRSISignal(0) ? SIGNAL_BUY : SIGNAL_NONE;
   m_indicators[1].sellSignal = m_indicators[1].enabled && CheckRSISignal(1) ? SIGNAL_SELL : SIGNAL_NONE;

   // Bollinger
   m_indicators[2].enabled = (BB_Entry_Strategy == BB_ENTRY_ENABLED);
   m_indicators[2].buySignal = m_indicators[2].enabled && CheckBollingerSignal(0) ? SIGNAL_BUY : SIGNAL_NONE;
   m_indicators[2].sellSignal = m_indicators[2].enabled && CheckBollingerSignal(1) ? SIGNAL_SELL : SIGNAL_NONE;

   // RCI
   m_indicators[3].enabled = (RCI_Entry_Strategy == RCI_ENTRY_ENABLED);
   m_indicators[3].buySignal = m_indicators[3].enabled && CheckRCISignal(0) ? SIGNAL_BUY : SIGNAL_NONE;
   m_indicators[3].sellSignal = m_indicators[3].enabled && CheckRCISignal(1) ? SIGNAL_SELL : SIGNAL_NONE;

   // Stochastic
   m_indicators[4].enabled = (Stoch_Entry_Strategy == STOCH_ENTRY_ENABLED);
   m_indicators[4].buySignal = m_indicators[4].enabled && CheckStochasticSignal(0) ? SIGNAL_BUY : SIGNAL_NONE;
   m_indicators[4].sellSignal = m_indicators[4].enabled && CheckStochasticSignal(1) ? SIGNAL_SELL : SIGNAL_NONE;

   // CCI
   m_indicators[5].enabled = (CCI_Entry_Strategy == CCI_ENTRY_ENABLED);
   m_indicators[5].buySignal = m_indicators[5].enabled && CheckCCISignal(0) ? SIGNAL_BUY : SIGNAL_NONE;
   m_indicators[5].sellSignal = m_indicators[5].enabled && CheckCCISignal(1) ? SIGNAL_SELL : SIGNAL_NONE;

   // ADX
   m_indicators[6].enabled = (ADX_Entry_Strategy == ADX_ENTRY_ENABLED);
   m_indicators[6].buySignal = m_indicators[6].enabled && CheckADXSignal(0) ? SIGNAL_BUY : SIGNAL_NONE;
   m_indicators[6].sellSignal = m_indicators[6].enabled && CheckADXSignal(1) ? SIGNAL_SELL : SIGNAL_NONE;

   // カスタムインジケーター
   m_indicators[7].enabled = IndicatorEntryHasConfiguration() && (InpIndicatorMode != INDICATOR_EXIT_ONLY);
   m_indicators[7].buySignal = m_indicators[7].enabled && CheckIndicatorEntrySignal(0) ? SIGNAL_BUY : SIGNAL_NONE;
   m_indicators[7].sellSignal = m_indicators[7].enabled && CheckIndicatorEntrySignal(1) ? SIGNAL_SELL : SIGNAL_NONE;
   // 名前を更新（パラメータが変わった場合に対応）
   m_indicators[7].name = IndicatorEntryDisplayName();

   // ボラティリティフィルター（BUY/SELLの概念なし、PASS/BLOCKのみ）
   m_indicators[8].enabled = InpVolatilityFilterEnabled;
   bool volPass = PassVolatilityEntryFilter();
   // PASSの場合は両方●、BLOCKの場合は両方○で表示
   ENUM_SIGNAL_STATE volState = m_indicators[8].enabled ? (volPass ? SIGNAL_BUY : SIGNAL_NONE) : SIGNAL_NONE;
   m_indicators[8].buySignal = volState;
   m_indicators[8].sellSignal = volState;
}

//+------------------------------------------------------------------+
//| 背景作成（メインパネルと同じスタイル）                             |
//+------------------------------------------------------------------+
void InfoPanelManager::CreateBackground()
{
   string name = GenerateObjectName("Background");

#ifdef __MQL5__
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, m_panelX);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, m_panelY);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, m_panelWidth);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, m_panelHeight);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, m_bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_COLOR, COLOR_PANEL_BORDER);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, PANEL_BORDER_WIDTH);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_ZORDER, 2100);
#else
   ObjectCreate(name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(name, OBJPROP_XDISTANCE, m_panelX);
   ObjectSet(name, OBJPROP_YDISTANCE, m_panelY);
   ObjectSet(name, OBJPROP_XSIZE, m_panelWidth);
   ObjectSet(name, OBJPROP_YSIZE, m_panelHeight);
   ObjectSet(name, OBJPROP_BGCOLOR, m_bgColor);
   ObjectSet(name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(name, OBJPROP_COLOR, COLOR_PANEL_BORDER);
   ObjectSet(name, OBJPROP_WIDTH, PANEL_BORDER_WIDTH);
   ObjectSet(name, OBJPROP_BACK, false);
   ObjectSet(name, OBJPROP_SELECTABLE, false);
   ObjectSet(name, OBJPROP_ZORDER, 2100);
#endif
}

//+------------------------------------------------------------------+
//| ヘッダー作成（メインパネルと同じスタイル）                         |
//+------------------------------------------------------------------+
void InfoPanelManager::CreateHeader()
{
   // タイトルバー背景
   string headerBg = GenerateObjectName("TitleBar");

#ifdef __MQL5__
   ObjectCreate(0, headerBg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, headerBg, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, headerBg, OBJPROP_XDISTANCE, m_panelX);
   ObjectSetInteger(0, headerBg, OBJPROP_YDISTANCE, m_panelY);
   ObjectSetInteger(0, headerBg, OBJPROP_XSIZE, m_panelWidth);
   ObjectSetInteger(0, headerBg, OBJPROP_YSIZE, TITLE_HEIGHT);
   ObjectSetInteger(0, headerBg, OBJPROP_BGCOLOR, m_headerColor);
   ObjectSetInteger(0, headerBg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, headerBg, OBJPROP_COLOR, COLOR_PANEL_BORDER);
   ObjectSetInteger(0, headerBg, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, headerBg, OBJPROP_BACK, false);
   ObjectSetInteger(0, headerBg, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, headerBg, OBJPROP_ZORDER, 2110);
#else
   ObjectCreate(headerBg, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSet(headerBg, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(headerBg, OBJPROP_XDISTANCE, m_panelX);
   ObjectSet(headerBg, OBJPROP_YDISTANCE, m_panelY);
   ObjectSet(headerBg, OBJPROP_XSIZE, m_panelWidth);
   ObjectSet(headerBg, OBJPROP_YSIZE, TITLE_HEIGHT);
   ObjectSet(headerBg, OBJPROP_BGCOLOR, m_headerColor);
   ObjectSet(headerBg, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSet(headerBg, OBJPROP_COLOR, COLOR_PANEL_BORDER);
   ObjectSet(headerBg, OBJPROP_WIDTH, 1);
   ObjectSet(headerBg, OBJPROP_BACK, false);
   ObjectSet(headerBg, OBJPROP_SELECTABLE, false);
   ObjectSet(headerBg, OBJPROP_ZORDER, 2110);
#endif

   // タイトルテキスト
   string headerText = GenerateObjectName("TitleText");
#ifdef __MQL5__
   ObjectCreate(0, headerText, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, headerText, OBJPROP_XDISTANCE, m_panelX + PANEL_MARGIN);
   ObjectSetInteger(0, headerText, OBJPROP_YDISTANCE, m_panelY + 8);
   ObjectSetString(0, headerText, OBJPROP_TEXT, "Technical Indicators");
   ObjectSetInteger(0, headerText, OBJPROP_COLOR, m_textColor);
   ObjectSetString(0, headerText, OBJPROP_FONT, "MS Gothic");
   ObjectSetInteger(0, headerText, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, headerText, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, headerText, OBJPROP_BACK, false);
   ObjectSetInteger(0, headerText, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, headerText, OBJPROP_ZORDER, 2120);
#else
   ObjectCreate(headerText, OBJ_LABEL, 0, 0, 0);
   ObjectSet(headerText, OBJPROP_XDISTANCE, m_panelX + PANEL_MARGIN);
   ObjectSet(headerText, OBJPROP_YDISTANCE, m_panelY + 8);
   ObjectSetText(headerText, "Technical Indicators", 9, "MS Gothic", m_textColor);
   ObjectSet(headerText, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(headerText, OBJPROP_BACK, false);
   ObjectSet(headerText, OBJPROP_SELECTABLE, false);
   ObjectSet(headerText, OBJPROP_ZORDER, 2120);
#endif

   // 閉じるボタン（×ボタン）を追加
   string closeBtn = GenerateObjectName("CloseButton");
#ifdef __MQL5__
   ObjectCreate(0, closeBtn, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, closeBtn, OBJPROP_XDISTANCE, m_panelX + m_panelWidth - 25);
   ObjectSetInteger(0, closeBtn, OBJPROP_YDISTANCE, m_panelY + 3);
   ObjectSetInteger(0, closeBtn, OBJPROP_XSIZE, 20);
   ObjectSetInteger(0, closeBtn, OBJPROP_YSIZE, 20);
   ObjectSetString(0, closeBtn, OBJPROP_TEXT, "×");
   ObjectSetString(0, closeBtn, OBJPROP_FONT, "MS Gothic");
   ObjectSetInteger(0, closeBtn, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, closeBtn, OBJPROP_COLOR, White);
   ObjectSetInteger(0, closeBtn, OBJPROP_BGCOLOR, C'200,50,50');  // 赤系の色
   ObjectSetInteger(0, closeBtn, OBJPROP_BORDER_COLOR, C'150,30,30');
   ObjectSetInteger(0, closeBtn, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, closeBtn, OBJPROP_BACK, false);
   ObjectSetInteger(0, closeBtn, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, closeBtn, OBJPROP_ZORDER, 2125);
   ObjectSetInteger(0, closeBtn, OBJPROP_STATE, false);
#else
   ObjectCreate(closeBtn, OBJ_BUTTON, 0, 0, 0);
   ObjectSet(closeBtn, OBJPROP_XDISTANCE, m_panelX + m_panelWidth - 25);
   ObjectSet(closeBtn, OBJPROP_YDISTANCE, m_panelY + 3);
   ObjectSet(closeBtn, OBJPROP_XSIZE, 20);
   ObjectSet(closeBtn, OBJPROP_YSIZE, 20);
   ObjectSetText(closeBtn, "×", 10, "MS Gothic", White);
   ObjectSet(closeBtn, OBJPROP_COLOR, White);
   ObjectSet(closeBtn, OBJPROP_BGCOLOR, C'200,50,50');
   ObjectSet(closeBtn, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(closeBtn, OBJPROP_BACK, false);
   ObjectSet(closeBtn, OBJPROP_SELECTABLE, false);
   ObjectSet(closeBtn, OBJPROP_ZORDER, 2125);
   ObjectSet(closeBtn, OBJPROP_STATE, false);
#endif

   // 列ヘッダー
   string colHeaders = GenerateObjectName("ColumnHeaders");
#ifdef __MQL5__
   ObjectCreate(0, colHeaders, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, colHeaders, OBJPROP_XDISTANCE, m_panelX + PANEL_MARGIN);
   ObjectSetInteger(0, colHeaders, OBJPROP_YDISTANCE, m_panelY + TITLE_HEIGHT + 5);
   ObjectSetString(0, colHeaders, OBJPROP_TEXT, "Indicator            Status          BUY      SELL");
   ObjectSetInteger(0, colHeaders, OBJPROP_COLOR, C'160,160,160');
   ObjectSetString(0, colHeaders, OBJPROP_FONT, "MS Gothic");
   ObjectSetInteger(0, colHeaders, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, colHeaders, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, colHeaders, OBJPROP_BACK, false);
   ObjectSetInteger(0, colHeaders, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, colHeaders, OBJPROP_ZORDER, 2120);
#else
   ObjectCreate(colHeaders, OBJ_LABEL, 0, 0, 0);
   ObjectSet(colHeaders, OBJPROP_XDISTANCE, m_panelX + PANEL_MARGIN);
   ObjectSet(colHeaders, OBJPROP_YDISTANCE, m_panelY + TITLE_HEIGHT + 5);
   ObjectSetText(colHeaders, "Indicator        Status        BUY    SELL", 8, "MS Gothic", C'160,160,160');
   ObjectSet(colHeaders, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSet(colHeaders, OBJPROP_BACK, false);
   ObjectSet(colHeaders, OBJPROP_SELECTABLE, false);
   ObjectSet(colHeaders, OBJPROP_ZORDER, 2120);
#endif
}

//+------------------------------------------------------------------+
//| 指標行作成                                                        |
//+------------------------------------------------------------------+
void InfoPanelManager::CreateIndicatorRow(int index, TechnicalIndicatorInfo &indicator)
{
   int yPos = m_panelY + TITLE_HEIGHT + 30 + (index * m_rowHeight);

   // 指標名
   string nameLabel = GenerateObjectName("Name_" + IntegerToString(index));
   ObjectCreate(0, nameLabel, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, nameLabel, OBJPROP_XDISTANCE, m_panelX + 15);
   ObjectSetInteger(0, nameLabel, OBJPROP_YDISTANCE, yPos);
   ObjectSetString(0, nameLabel, OBJPROP_TEXT, indicator.name);
   ObjectSetInteger(0, nameLabel, OBJPROP_COLOR, m_textColor);
   ObjectSetString(0, nameLabel, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, nameLabel, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, nameLabel, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, nameLabel, OBJPROP_BACK, false);
   ObjectSetInteger(0, nameLabel, OBJPROP_SELECTABLE, false);

   // ON/OFF状態
   string statusLabel = GenerateObjectName("Status_" + IntegerToString(index));
   ObjectCreate(0, statusLabel, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, statusLabel, OBJPROP_XDISTANCE, m_panelX + 130);
   ObjectSetInteger(0, statusLabel, OBJPROP_YDISTANCE, yPos);
   ObjectSetString(0, statusLabel, OBJPROP_TEXT, indicator.enabled ? "ON" : "OFF");
   ObjectSetInteger(0, statusLabel, OBJPROP_COLOR, indicator.enabled ? m_enabledColor : m_disabledColor);
   ObjectSetString(0, statusLabel, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, statusLabel, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, statusLabel, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, statusLabel, OBJPROP_BACK, false);
   ObjectSetInteger(0, statusLabel, OBJPROP_SELECTABLE, false);

   // BUYシグナル
   string buyLabel = GenerateObjectName("Buy_" + IntegerToString(index));
   ObjectCreate(0, buyLabel, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, buyLabel, OBJPROP_XDISTANCE, m_panelX + 240);
   ObjectSetInteger(0, buyLabel, OBJPROP_YDISTANCE, yPos);
   ObjectSetString(0, buyLabel, OBJPROP_TEXT, GetSignalText(indicator.buySignal));
   ObjectSetInteger(0, buyLabel, OBJPROP_COLOR, GetSignalColor(indicator.buySignal));
   ObjectSetString(0, buyLabel, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, buyLabel, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, buyLabel, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, buyLabel, OBJPROP_BACK, false);
   ObjectSetInteger(0, buyLabel, OBJPROP_SELECTABLE, false);

   // SELLシグナル
   string sellLabel = GenerateObjectName("Sell_" + IntegerToString(index));
   ObjectCreate(0, sellLabel, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, sellLabel, OBJPROP_XDISTANCE, m_panelX + 295);
   ObjectSetInteger(0, sellLabel, OBJPROP_YDISTANCE, yPos);
   ObjectSetString(0, sellLabel, OBJPROP_TEXT, GetSignalText(indicator.sellSignal));
   ObjectSetInteger(0, sellLabel, OBJPROP_COLOR, GetSignalColor(indicator.sellSignal));
   ObjectSetString(0, sellLabel, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, sellLabel, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, sellLabel, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, sellLabel, OBJPROP_BACK, false);
   ObjectSetInteger(0, sellLabel, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| 指標行更新                                                        |
//+------------------------------------------------------------------+
void InfoPanelManager::UpdateIndicatorRow(int index, TechnicalIndicatorInfo &indicator)
{
   // ON/OFF状態更新
   string statusLabel = GenerateObjectName("Status_" + IntegerToString(index));
   ObjectSetString(0, statusLabel, OBJPROP_TEXT, indicator.enabled ? "ON" : "OFF");
   ObjectSetInteger(0, statusLabel, OBJPROP_COLOR, indicator.enabled ? m_enabledColor : m_disabledColor);

   // BUYシグナル更新
   string buyLabel = GenerateObjectName("Buy_" + IntegerToString(index));
   ObjectSetString(0, buyLabel, OBJPROP_TEXT, GetSignalText(indicator.buySignal));
   ObjectSetInteger(0, buyLabel, OBJPROP_COLOR, GetSignalColor(indicator.buySignal));

   // SELLシグナル更新
   string sellLabel = GenerateObjectName("Sell_" + IntegerToString(index));
   ObjectSetString(0, sellLabel, OBJPROP_TEXT, GetSignalText(indicator.sellSignal));
   ObjectSetInteger(0, sellLabel, OBJPROP_COLOR, GetSignalColor(indicator.sellSignal));
}

//+------------------------------------------------------------------+
//| オブジェクト名生成                                                |
//+------------------------------------------------------------------+
string InfoPanelManager::GenerateObjectName(string baseName)
{
   return m_objectPrefix + baseName;
}

//+------------------------------------------------------------------+
//| シグナル色取得                                                    |
//+------------------------------------------------------------------+
color InfoPanelManager::GetSignalColor(ENUM_SIGNAL_STATE state)
{
   switch(state)
   {
      case SIGNAL_BUY:  return m_buyColor;
      case SIGNAL_SELL: return m_sellColor;
      default:          return m_neutralColor;
   }
}

//+------------------------------------------------------------------+
//| シグナルテキスト取得                                              |
//+------------------------------------------------------------------+
string InfoPanelManager::GetSignalText(ENUM_SIGNAL_STATE state)
{
   switch(state)
   {
      case SIGNAL_BUY:  return "●";
      case SIGNAL_SELL: return "●";
      default:          return "○";
   }
}

//+------------------------------------------------------------------+
//| パネル位置計算                                                    |
//+------------------------------------------------------------------+
void InfoPanelManager::CalculatePosition()
{
   // メインパネルの右側に配置
   m_panelX = g_EffectivePanelX + PANEL_WIDTH + 20; // メインパネル幅 + マージン
   m_panelY = g_EffectivePanelY; // メインパネルと同じY位置
}


//+------------------------------------------------------------------+
//| ポジションテーブル位置更新（強制再作成版）                         |
//+------------------------------------------------------------------+
void InfoPanelManager::UpdatePositionTableLocation()
{
   // 再帰呼び出しを防ぐためのフラグ
   static bool isUpdating = false;
   if(isUpdating) return;
   isUpdating = true;

   int oldTableX = g_EffectiveTableX;
   int oldTableY = g_EffectiveTableY;

   if(m_isVisible)
   {
      // InfoPanelが表示されている場合：テーブルをInfoPanelの右側に配置
      // まず正確なInfoPanelの位置を計算
      int infoPanelX = g_EffectivePanelX + PANEL_WIDTH + 20;  // メインパネルの右側

      // PositionTableをInfoPanelのさらに右側に配置
      g_EffectiveTableX = infoPanelX + m_panelWidth + 25;  // InfoPanelの右側 + マージン
      g_EffectiveTableY = g_EffectivePanelY;
      Print("InfoPanel表示: InfoPanelX=", infoPanelX, " TableX=", g_EffectiveTableX, " Y=", g_EffectiveTableY);
   }
   else
   {
      // InfoPanelが非表示の場合：レイアウトパターンに基づいて元の位置に戻す
      switch(LayoutPattern)
      {
         case LAYOUT_DEFAULT:
            g_EffectiveTableX = g_EffectivePanelX;
            g_EffectiveTableY = g_EffectivePanelY + 500;
            break;
         case LAYOUT_SIDE_BY_SIDE:
            g_EffectiveTableX = g_EffectivePanelX + PANEL_WIDTH + 20;
            g_EffectiveTableY = g_EffectivePanelY;
            break;
         case LAYOUT_TABLE_TOP:
            g_EffectiveTableX = g_EffectivePanelX;
            g_EffectiveTableY = g_EffectivePanelY;
            break;
         case LAYOUT_COMPACT:
            g_EffectiveTableX = g_EffectivePanelX;
            g_EffectiveTableY = g_EffectivePanelY + 350;
            break;
         default:
            g_EffectiveTableX = g_EffectivePanelX;
            g_EffectiveTableY = g_EffectivePanelY + 500;
            break;
      }
      Print("InfoPanel非表示: テーブル位置復元 X=", g_EffectiveTableX, " Y=", g_EffectiveTableY);
   }

   // InfoPanel表示状態変更時は既存テーブルを直接移動
   if(EnablePositionTable)
   {
      Print("InfoPanel状態変更: テーブル直接移動 X=", g_EffectiveTableX, " Y=", g_EffectiveTableY);
      // まず直接移動を試行
      MovePositionTableDirectly(g_EffectiveTableX, g_EffectiveTableY);

      // それでも移動しない場合は再作成
      Print("InfoPanel状態変更: 念のためテーブル再作成も実行");
      DeletePositionTable();
      CreatePositionTable();
      ChartRedraw();
   }

   isUpdating = false;
}

// グローバルインスタンス
InfoPanelManager g_InfoPanel;

//+------------------------------------------------------------------+
//| グローバル関数                                                    |
//+------------------------------------------------------------------+
bool InitializeInfoPanel()
{
   return g_InfoPanel.Initialize();
}

void DeinitializeInfoPanel()
{
   g_InfoPanel.Deinitialize();
}

void UpdateInfoPanel()
{
   g_InfoPanel.UpdatePanel();
}

void ShowInfoPanel()
{
   g_InfoPanel.ShowPanel();
}

void HideInfoPanel()
{
   g_InfoPanel.HidePanel();
}

void ToggleInfoPanel()
{
   g_InfoPanel.TogglePanel();
}

bool IsInfoPanelVisible()
{
   return g_InfoPanel.IsVisible();
}

//+------------------------------------------------------------------+
//| グローバル関数 - 強制テーブル位置更新                            |
//+------------------------------------------------------------------+
void ForceUpdatePositionTableLocation()
{
   Print("ForceUpdatePositionTableLocation() 呼び出し");
   g_InfoPanel.UpdatePositionTableLocation();
}

#endif // HOSOPI3_INFOPANEL_MQH