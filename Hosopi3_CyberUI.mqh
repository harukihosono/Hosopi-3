//+------------------------------------------------------------------+
//|                               Hosopi3_CyberUI.mqh               |
//|              サイバー風テクニカルインジケーターUI                 |
//|                ELDRAから移植・改良したUI システム               |
//+------------------------------------------------------------------+
#ifndef HOSOPI3_CYBER_UI_H
#define HOSOPI3_CYBER_UI_H

//+------------------------------------------------------------------+
//| サイバーUIカラーシステム                                         |
//+------------------------------------------------------------------+

// サイバー風カラーパレット
#define CYBER_BG_DARK        C'15,18,25'      // ダークブルー背景
#define CYBER_BG_MEDIUM      C'25,30,40'      // ミディアムブルー
#define CYBER_ACCENT_CYAN    C'0,255,255'     // シアン（アクセント）
#define CYBER_ACCENT_PURPLE  C'128,0,255'     // 紫（アクセント）
#define CYBER_ACCENT_GREEN   C'0,255,128'     // グリーン（アクセント）
#define CYBER_ACCENT_RED     C'255,64,128'    // レッド（アクセント）
#define CYBER_TEXT_BRIGHT    C'220,230,255'   // 明るいテキスト
#define CYBER_TEXT_DIM       C'160,170,200'   // 薄いテキスト
#define CYBER_BORDER_GLOW    C'64,128,255'    // 境界線のグロー
#define CYBER_WARNING        C'255,165,0'     // 警告色

// エントリー状態用背景色
#define CHART_BG_BUY         C'10,20,50'      // BUY可能時（深い青）
#define CHART_BG_SELL        C'50,10,20'      // SELL可能時（深い赤）
#define CHART_BG_BUYSELL     C'30,10,50'      // BUYSELL可能時（深い紫）
#define CHART_BG_NEUTRAL     C'15,15,15'      // ニュートラル（黒）

//+------------------------------------------------------------------+
//| エントリー状態列挙型                                             |
//+------------------------------------------------------------------+
enum ENUM_ENTRY_STATE
{
   ENTRY_STATE_NEUTRAL = 0,    // ニュートラル
   ENTRY_STATE_BUY = 1,        // BUY可能
   ENTRY_STATE_SELL = 2,       // SELL可能
   ENTRY_STATE_BUYSELL = 3     // 両方向可能
};

//+------------------------------------------------------------------+
//| テクニカル指標状態構造体                                         |
//+------------------------------------------------------------------+
struct TechnicalIndicatorState
{
   string name;              // 指標名
   double value;             // 現在値
   double previousValue;     // 前回値
   int signal;               // シグナル（-1:SELL, 0:NEUTRAL, 1:BUY）
   color indicatorColor;     // 表示色
   datetime lastUpdate;      // 最終更新時刻
};

//+------------------------------------------------------------------+
//| サイバーUIマネージャークラス                                     |
//+------------------------------------------------------------------+
class CyberUIManager
{
private:
   // UI状態管理
   ENUM_ENTRY_STATE m_currentEntryState;
   color m_currentChartBG;
   bool m_uiInitialized;
   datetime m_lastUpdate;

   // パネル管理
   int m_panelWidth;
   int m_panelHeight;
   int m_panelX;
   int m_panelY;

   // テクニカル指標状態配列
   TechnicalIndicatorState m_indicators[10];
   int m_indicatorCount;

   // UI要素名
   string m_panelName;
   string m_headerName;

public:
   // コンストラクタ・デストラクタ
   CyberUIManager();
   ~CyberUIManager();

   // 初期化・終了処理
   bool InitializeUI();
   void DeinitializeUI();

   // チャート背景色管理
   void UpdateChartBackground(ENUM_ENTRY_STATE state);
   color GetEntryStateColor(ENUM_ENTRY_STATE state);

   // テクニカルパネル管理
   void CreateTechnicalPanel();
   void UpdateTechnicalPanel();
   void AddIndicator(string name, double value, int signal);

   // オシレータパネル
   void CreateOscillatorPanel();
   void UpdateOscillator(string name, double value, double min_val, double max_val);

   // メイン更新処理
   void UpdateUI();

   // ゲッター・セッター
   ENUM_ENTRY_STATE GetCurrentEntryState() { return m_currentEntryState; }
   void SetEntryState(ENUM_ENTRY_STATE state);

   // エントリー状態判定
   ENUM_ENTRY_STATE DetermineEntryState();

   // テクニカル指標パネル更新
   void UpdateTechnicalIndicatorPanels();

private:
   // 内部ヘルパー関数
   void CreateCyberButton(string name, int x, int y, int width, int height,
                          string text, color bg_color, color text_color);
   void CreateCyberLabel(string name, int x, int y, string text, color text_color, int font_size);
   void CreateCyberRectangle(string name, int x, int y, int width, int height,
                             color bg_color, color border_color);
   void CreateGlowEffect(string name, int x, int y, int width, int height, color glow_color);

   // パネル描画ヘルパー
   void DrawProgressBar(string name, int x, int y, int width, int height,
                        double value, double min_val, double max_val, color bar_color);
   void DrawSignalIndicator(string name, int x, int y, int signal, color color_positive, color color_negative);
};

//+------------------------------------------------------------------+
//| グローバルインスタンス                                           |
//+------------------------------------------------------------------+
CyberUIManager g_CyberUI;

//+------------------------------------------------------------------+
//| コンストラクタ                                                   |
//+------------------------------------------------------------------+
CyberUIManager::CyberUIManager()
{
   m_currentEntryState = ENTRY_STATE_NEUTRAL;
   m_currentChartBG = CHART_BG_NEUTRAL;
   m_uiInitialized = false;
   m_lastUpdate = 0;

   m_panelWidth = 300;
   m_panelHeight = 400;
   m_panelX = 20;
   m_panelY = 50;

   m_indicatorCount = 0;

   m_panelName = "CyberTechnicalPanel";
   m_headerName = "CyberPanelHeader";
}

//+------------------------------------------------------------------+
//| デストラクタ                                                     |
//+------------------------------------------------------------------+
CyberUIManager::~CyberUIManager()
{
   DeinitializeUI();
}

//+------------------------------------------------------------------+
//| UI初期化                                                         |
//+------------------------------------------------------------------+
bool CyberUIManager::InitializeUI()
{
   if(m_uiInitialized) return true;

   // チャートの前景設定を確認・調整（ELDRAから移植）
   if((bool)ChartGetInteger(0, CHART_FOREGROUND)) {
      ChartSetInteger(0, CHART_FOREGROUND, false);
      Print("サイバーUI: チャート前景設定を無効化（パネル表示最適化）");
   }

   // メインパネル作成
   CreateTechnicalPanel();
   CreateOscillatorPanel();

   // 初期チャート背景設定
   UpdateChartBackground(ENTRY_STATE_NEUTRAL);

   m_uiInitialized = true;
   Print("サイバーUI初期化完了 - 高度なテクニカル表示システムを開始");

   return true;
}

//+------------------------------------------------------------------+
//| UI終了処理                                                       |
//+------------------------------------------------------------------+
void CyberUIManager::DeinitializeUI()
{
   if(!m_uiInitialized) return;

   // 全UI要素を削除
   ObjectsDeleteAll(0, "Cyber", -1, OBJ_RECTANGLE_LABEL);
   ObjectsDeleteAll(0, "Cyber", -1, OBJ_LABEL);
   ObjectsDeleteAll(0, "Cyber", -1, OBJ_BUTTON);
   ObjectsDeleteAll(0, "Tech", -1, OBJ_RECTANGLE_LABEL);
   ObjectsDeleteAll(0, "Osc", -1, OBJ_RECTANGLE_LABEL);

   // チャート背景をデフォルトに戻す
   ChartSetInteger(0, CHART_COLOR_BACKGROUND, clrBlack);
   ChartRedraw();

   m_uiInitialized = false;
   Print("サイバーUI終了処理完了");
}

//+------------------------------------------------------------------+
//| チャート背景色更新                                               |
//+------------------------------------------------------------------+
void CyberUIManager::UpdateChartBackground(ENUM_ENTRY_STATE state)
{
   color newColor = GetEntryStateColor(state);

   if(newColor != m_currentChartBG) {
      m_currentChartBG = newColor;
      ChartSetInteger(0, CHART_COLOR_BACKGROUND, newColor);
      ChartRedraw();

      // 状態表示ログ
      string stateText = "";
      switch(state) {
         case ENTRY_STATE_BUY: stateText = "BUY SIGNAL"; break;
         case ENTRY_STATE_SELL: stateText = "SELL SIGNAL"; break;
         case ENTRY_STATE_BUYSELL: stateText = "DUAL SIGNAL"; break;
         default: stateText = "NEUTRAL"; break;
      }
      Print("サイバーUI: チャート背景更新 → ", stateText);
   }
}

//+------------------------------------------------------------------+
//| エントリー状態色取得                                             |
//+------------------------------------------------------------------+
color CyberUIManager::GetEntryStateColor(ENUM_ENTRY_STATE state)
{
   switch(state) {
      case ENTRY_STATE_BUY: return CHART_BG_BUY;
      case ENTRY_STATE_SELL: return CHART_BG_SELL;
      case ENTRY_STATE_BUYSELL: return CHART_BG_BUYSELL;
      default: return CHART_BG_NEUTRAL;
   }
}

//+------------------------------------------------------------------+
//| テクニカルパネル作成                                             |
//+------------------------------------------------------------------+
void CyberUIManager::CreateTechnicalPanel()
{
   // メインパネル背景
   CreateCyberRectangle("CyberMainPanel", m_panelX, m_panelY,
                        m_panelWidth, m_panelHeight, CYBER_BG_DARK, CYBER_BORDER_GLOW);

   // グローエフェクト
   CreateGlowEffect("CyberMainGlow", m_panelX-2, m_panelY-2,
                    m_panelWidth+4, m_panelHeight+4, CYBER_BORDER_GLOW);

   // ヘッダー
   CreateCyberRectangle("CyberHeader", m_panelX, m_panelY,
                        m_panelWidth, 40, CYBER_BG_MEDIUM, CYBER_ACCENT_CYAN);

   CreateCyberLabel("CyberHeaderText", m_panelX + 10, m_panelY + 10,
                    "◉ TECHNICAL ANALYSIS MATRIX ◉", CYBER_ACCENT_CYAN, 12);

   // 状態表示エリア
   CreateCyberLabel("CyberStatusLabel", m_panelX + 10, m_panelY + 50,
                    "SYSTEM STATUS: ACTIVE", CYBER_TEXT_BRIGHT, 10);

   // インジケーター表示エリアの準備
   for(int i = 0; i < 8; i++) {
      int yPos = m_panelY + 80 + (i * 35);

      // インジケーター名ラベル
      CreateCyberLabel("TechIndicator_" + IntegerToString(i),
                       m_panelX + 10, yPos, "", CYBER_TEXT_DIM, 9);

      // 値表示ラベル
      CreateCyberLabel("TechValue_" + IntegerToString(i),
                       m_panelX + 150, yPos, "", CYBER_TEXT_BRIGHT, 9);

      // シグナルインジケーター
      CreateCyberRectangle("TechSignal_" + IntegerToString(i),
                           m_panelX + 250, yPos, 20, 15, CYBER_BG_MEDIUM, CYBER_TEXT_DIM);
   }
}

//+------------------------------------------------------------------+
//| オシレータパネル作成                                             |
//+------------------------------------------------------------------+
void CyberUIManager::CreateOscillatorPanel()
{
   int oscX = m_panelX + m_panelWidth + 20;
   int oscY = m_panelY;
   int oscWidth = 250;
   int oscHeight = 300;

   // オシレータパネル背景
   CreateCyberRectangle("CyberOscPanel", oscX, oscY, oscWidth, oscHeight,
                        CYBER_BG_DARK, CYBER_ACCENT_PURPLE);

   // ヘッダー
   CreateCyberRectangle("CyberOscHeader", oscX, oscY, oscWidth, 40,
                        CYBER_BG_MEDIUM, CYBER_ACCENT_PURPLE);

   CreateCyberLabel("CyberOscHeaderText", oscX + 10, oscY + 10,
                    "◈ OSCILLATOR MATRIX ◈", CYBER_ACCENT_PURPLE, 12);

   // オシレータービジュアル要素の準備
   for(int i = 0; i < 5; i++) {
      int yPos = oscY + 60 + (i * 45);

      // オシレータ名
      CreateCyberLabel("OscName_" + IntegerToString(i),
                       oscX + 10, yPos, "", CYBER_TEXT_BRIGHT, 9);

      // プログレスバーの背景
      CreateCyberRectangle("OscBG_" + IntegerToString(i),
                           oscX + 10, yPos + 15, oscWidth - 20, 15,
                           CYBER_BG_MEDIUM, CYBER_TEXT_DIM);
   }
}

//+------------------------------------------------------------------+
//| メインUI更新処理                                                 |
//+------------------------------------------------------------------+
void CyberUIManager::UpdateUI()
{
   if(!m_uiInitialized) return;

   datetime currentTime = TimeCurrent();
   if(currentTime - m_lastUpdate < 1) return; // 1秒間隔で更新

   m_lastUpdate = currentTime;

   // パネルのZ-order修復（ELDRAから移植）
   ObjectSetInteger(0, "CyberMainPanel", OBJPROP_ZORDER, 1000);
   ObjectSetInteger(0, "CyberOscPanel", OBJPROP_ZORDER, 1000);

   // テクニカル指標更新
   UpdateTechnicalPanel();

   // 時刻表示更新
   string timeStr = "ACTIVE • " + TimeToString(currentTime, TIME_SECONDS);
   ObjectSetString(0, "CyberStatusLabel", OBJPROP_TEXT, timeStr);
}

//+------------------------------------------------------------------+
//| テクニカルパネル更新                                             |
//+------------------------------------------------------------------+
void CyberUIManager::UpdateTechnicalPanel()
{
   // Hosopi3の戦略状態を反映

   // 戦略1: RSI状態（例）
   AddIndicator("RSI(14)", 45.6, 0);  // 中立

   // 戦略2: MACD状態（例）
   AddIndicator("MACD", 0.0012, 1);   // 買いシグナル

   // 戦略3: ボリンジャーバンド（例）
   AddIndicator("BB %B", 0.75, -1);   // 売りシグナル

   // 戦略4: エントリー総合状態
   ENUM_ENTRY_STATE entryState = DetermineEntryState();
   SetEntryState(entryState);

   // パネルに反映
   for(int i = 0; i < m_indicatorCount && i < 8; i++) {
      ObjectSetString(0, "TechIndicator_" + IntegerToString(i), OBJPROP_TEXT, m_indicators[i].name);
      ObjectSetString(0, "TechValue_" + IntegerToString(i), OBJPROP_TEXT,
                      DoubleToString(m_indicators[i].value, 4));

      // シグナル色更新
      color signalColor = CYBER_TEXT_DIM;
      if(m_indicators[i].signal > 0) signalColor = CYBER_ACCENT_GREEN;
      else if(m_indicators[i].signal < 0) signalColor = CYBER_ACCENT_RED;

      ObjectSetInteger(0, "TechSignal_" + IntegerToString(i), OBJPROP_BGCOLOR, signalColor);
   }
}

//+------------------------------------------------------------------+
//| エントリー状態判定                                               |
//+------------------------------------------------------------------+
ENUM_ENTRY_STATE CyberUIManager::DetermineEntryState()
{
   // Hosopi3の戦略判定ロジックと連携
   // ここでは簡単な例を示す

   int buySignals = 0;
   int sellSignals = 0;

   for(int i = 0; i < m_indicatorCount; i++) {
      if(m_indicators[i].signal > 0) buySignals++;
      else if(m_indicators[i].signal < 0) sellSignals++;
   }

   if(buySignals > 0 && sellSignals > 0) return ENTRY_STATE_BUYSELL;
   else if(buySignals > sellSignals) return ENTRY_STATE_BUY;
   else if(sellSignals > buySignals) return ENTRY_STATE_SELL;
   else return ENTRY_STATE_NEUTRAL;
}

//+------------------------------------------------------------------+
//| インジケーター追加                                               |
//+------------------------------------------------------------------+
void CyberUIManager::AddIndicator(string name, double value, int signal)
{
   if(m_indicatorCount >= 10) return;

   TechnicalIndicatorState indicator;
   indicator.name = name;
   indicator.value = value;
   indicator.signal = signal;
   indicator.lastUpdate = TimeCurrent();

   // 既存のインジケーターを更新するか新規追加
   bool found = false;
   for(int i = 0; i < m_indicatorCount; i++) {
      if(m_indicators[i].name == name) {
         m_indicators[i] = indicator;
         found = true;
         break;
      }
   }

   if(!found) {
      m_indicators[m_indicatorCount] = indicator;
      m_indicatorCount++;
   }
}

//+------------------------------------------------------------------+
//| エントリー状態設定                                               |
//+------------------------------------------------------------------+
void CyberUIManager::SetEntryState(ENUM_ENTRY_STATE state)
{
   if(state != m_currentEntryState) {
      m_currentEntryState = state;
      UpdateChartBackground(state);
   }
}

//+------------------------------------------------------------------+
//| テクニカル指標パネル更新メソッド                                 |
//+------------------------------------------------------------------+
void CyberUIManager::UpdateTechnicalIndicatorPanels()
{
   // テクニカル指標の現在値を取得して表示を更新
   // 実装例：各指標の状態を更新
   UpdateTechnicalPanel();
}

//+------------------------------------------------------------------+
//| サイバーボタン作成                                               |
//+------------------------------------------------------------------+
void CyberUIManager::CreateCyberButton(string name, int x, int y, int width, int height,
                                       string text, color bg_color, color text_color)
{
   ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_color);
   ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, CYBER_BORDER_GLOW);
   ObjectSetString(0, name, OBJPROP_FONT, "Courier New");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 9);
}

//+------------------------------------------------------------------+
//| サイバーラベル作成                                               |
//+------------------------------------------------------------------+
void CyberUIManager::CreateCyberLabel(string name, int x, int y, string text,
                                      color text_color, int font_size)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
   ObjectSetString(0, name, OBJPROP_FONT, "Courier New");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

//+------------------------------------------------------------------+
//| サイバー矩形作成                                                 |
//+------------------------------------------------------------------+
void CyberUIManager::CreateCyberRectangle(string name, int x, int y, int width, int height,
                                          color bg_color, color border_color)
{
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bg_color);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, border_color);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

//+------------------------------------------------------------------+
//| グローエフェクト作成                                             |
//+------------------------------------------------------------------+
void CyberUIManager::CreateGlowEffect(string name, int x, int y, int width, int height,
                                      color glow_color)
{
   ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, clrNONE);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, glow_color);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
}

//+------------------------------------------------------------------+
//| グローバル関数 - UI初期化                                        |
//+------------------------------------------------------------------+
bool InitializeCyberUI()
{
   return g_CyberUI.InitializeUI();
}

//+------------------------------------------------------------------+
//| グローバル関数 - UI更新                                          |
//+------------------------------------------------------------------+
void UpdateCyberUI()
{
   g_CyberUI.UpdateUI();
}

//+------------------------------------------------------------------+
//| グローバル関数 - UI終了処理                                      |
//+------------------------------------------------------------------+
void DeinitializeCyberUI()
{
   g_CyberUI.DeinitializeUI();
}

//+------------------------------------------------------------------+
//| グローバル関数 - エントリー状態設定                              |
//+------------------------------------------------------------------+
void SetCyberEntryState(int buySignal, int sellSignal)
{
   ENUM_ENTRY_STATE state = ENTRY_STATE_NEUTRAL;

   if(buySignal > 0 && sellSignal > 0) state = ENTRY_STATE_BUYSELL;
   else if(buySignal > 0) state = ENTRY_STATE_BUY;
   else if(sellSignal > 0) state = ENTRY_STATE_SELL;

   g_CyberUI.SetEntryState(state);
}

//+------------------------------------------------------------------+
//| グローバル関数 - エントリー状態設定（enum版）                    |
//+------------------------------------------------------------------+
void SetCyberEntryState(ENUM_ENTRY_STATE state)
{
   g_CyberUI.SetEntryState(state);
}

//+------------------------------------------------------------------+
//| グローバル関数 - テクニカル指標パネル更新                        |
//+------------------------------------------------------------------+
void UpdateCyberTechnicalPanels()
{
   // テクニカル指標データを取得して表示を更新
   // この関数は戦略システムから呼び出される

   // 現在のエントリー状態に基づいてパネルを更新
   g_CyberUI.UpdateTechnicalIndicatorPanels();
}

#endif // HOSOPI3_CYBER_UI_H