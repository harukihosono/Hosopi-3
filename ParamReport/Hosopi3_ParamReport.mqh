//+------------------------------------------------------------------+
//| Hosopi3_ParamReport.mqh                                          |
//| 初期input(宣言時デフォルト) と 現在値 の差分を HTML 出力する。     |
//| ・全項目を表示し、変更された項目をハイライト                       |
//| ・出力先: <Common>\Files\Hosopi3\Hosopi3_params.html (UTF-8)      |
//| ・ライブ/テスター両方でボタンからブラウザ自動オープン             |
//| ・ELDRA2 の ParamReport を移植（ELDRA_ParamReport.mqh 参照）      |
//+------------------------------------------------------------------+
#ifndef HOSOPI3_PARAMREPORT_MQH
#define HOSOPI3_PARAMREPORT_MQH

#include "Hosopi3_ParamTable.mqh"   // 自動生成: Hosopi3_BuildParamTable()

//--- ブラウザ起動用 (shell32)
#import "shell32.dll"
int ShellExecuteW(int hwnd, string operation, string file, string params, string dir, int showcmd);
#import

//+------------------------------------------------------------------+
//| HTML エスケープ                                                  |
//+------------------------------------------------------------------+
string Hosopi3_HtmlEscape(string s) {
   StringReplace(s, "&", "&amp;");
   StringReplace(s, "<", "&lt;");
   StringReplace(s, ">", "&gt;");
   StringReplace(s, "\"", "&quot;");
   return s;
}

//+------------------------------------------------------------------+
//| 現在の時間足を短い文字列に                                       |
//+------------------------------------------------------------------+
string Hosopi3_PeriodStr() {
   string p = EnumToString((ENUM_TIMEFRAMES)_Period);
   if(StringFind(p, "PERIOD_") == 0) p = StringSubstr(p, 7);
   return p;
}

//+------------------------------------------------------------------+
//| パラメータ差分 HTML レポートを生成して開く                       |
//+------------------------------------------------------------------+
void GenerateParamDiffReport() {
   Hosopi3ParamRow rows[];
   Hosopi3_BuildParamTable(rows);
   int total = ArraySize(rows);

   // 変更件数カウント
   int changedCnt = 0;
   int paramCnt = 0;
   for(int i = 0; i < total; i++) {
      if(rows[i].isSection) continue;
      paramCnt++;
      if(rows[i].changed) changedCnt++;
   }

   // テスター判定
   bool isTester;
#ifdef __MQL5__
   isTester = (bool)MQLInfoInteger(MQL_TESTER);
#else
   isTester = (IsTesting() || IsOptimization() || IsVisualMode());
#endif

   string nowStr = TimeToString(TimeCurrent(), TIME_DATE | TIME_MINUTES);
   string acc    = IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN)) + " @ " + AccountInfoString(ACCOUNT_SERVER);

   //--- HTML 構築
   string h = "";
   h += "<!DOCTYPE html><html lang=\"ja\"><head><meta charset=\"utf-8\">";
   h += "<title>Hosopi3 パラメータ差分</title>";
   h += "<style>";
   h += "body{font-family:'Meiryo UI','Segoe UI',sans-serif;background:#1b1b1b;color:#e8e8e8;margin:0;padding:24px;}";
   h += "h1{font-size:20px;margin:0 0 4px 0;}";
   h += ".meta{color:#9aa0a6;font-size:13px;margin-bottom:16px;line-height:1.6;}";
   h += ".badge{display:inline-block;background:#2a2a2a;border-radius:4px;padding:2px 10px;margin-right:8px;}";
   h += ".chg{color:#ffd54f;font-weight:bold;}";
   h += "table{border-collapse:collapse;width:100%;font-size:13px;}";
   h += "th,td{text-align:left;padding:6px 10px;border-bottom:1px solid #333;}";
   h += "th{background:#262626;position:sticky;top:0;color:#bbb;}";
   h += "tr.sec td{background:#0f3b57;color:#cfe8ff;font-weight:bold;border-bottom:1px solid #155;}";
   h += "tr.changed td{background:#3a3517;}";
   h += "tr.changed .name{color:#ffd54f;font-weight:bold;}";
   h += "td.val{font-family:Consolas,monospace;}";
   h += "td.cur{color:#fff;} td.def{color:#8a8f94;}";
   h += "tr.changed td.cur{color:#ffe082;font-weight:bold;}";
   h += ".toggle{margin:8px 0 16px 0;}";
   h += ".tg{background:#2a2a2a;color:#ccc;border:1px solid #444;padding:6px 18px;cursor:pointer;font-size:13px;}";
   h += ".tg.act{background:#0f6fc4;color:#fff;border-color:#0f6fc4;font-weight:bold;}";
   h += ".tg:first-child{border-radius:4px 0 0 4px;}";
   h += ".tg:last-child{border-radius:0 4px 4px 0;}";
   h += "</style></head><body>";

   h += "<h1>Hosopi3 パラメータ差分レポート</h1>";
   h += "<div class=\"meta\">";
   h += "<span class=\"badge\">" + Hosopi3_HtmlEscape(_Symbol) + " " + Hosopi3_PeriodStr() + "</span>";
   h += "<span class=\"badge\">口座: " + Hosopi3_HtmlEscape(acc) + "</span>";
   h += "<span class=\"badge\">" + nowStr + "</span>";
   if(isTester) h += "<span class=\"badge\">バックテスト</span>";
   h += "<br><span class=\"chg\">変更 " + IntegerToString(changedCnt) + "</span> / 全 " + IntegerToString(paramCnt) + " 項目";
   h += "</div>";

   // 表示モード切替トグル（変更のみ / 全体）
   h += "<div class=\"toggle\">";
   h += "<button id=\"bChg\" class=\"tg\" onclick=\"setMode(true)\">変更のみ</button>";
   h += "<button id=\"bAll\" class=\"tg act\" onclick=\"setMode(false)\">全体</button>";
   h += "</div>";

   h += "<table id=\"tbl\"><thead><tr><th>項目</th><th>初期値</th><th>現在値</th></tr></thead><tbody>";

   for(int i = 0; i < total; i++) {
      if(rows[i].isSection) {
         h += "<tr class=\"sec\"><td colspan=\"3\">" + Hosopi3_HtmlEscape(rows[i].label) + "</td></tr>";
         continue;
      }
      string cls = rows[i].changed ? " class=\"changed\"" : "";
      string lbl = rows[i].label;
      if(lbl == "") lbl = rows[i].name;
      h += "<tr" + cls + ">";
      h += "<td class=\"name\">" + Hosopi3_HtmlEscape(lbl) + "</td>";
      h += "<td class=\"val def\">" + Hosopi3_HtmlEscape(rows[i].defVal) + "</td>";
      h += "<td class=\"val cur\">" + Hosopi3_HtmlEscape(rows[i].curVal) + "</td>";
      h += "</tr>";
   }
   h += "</tbody></table>";

   // モード切替スクリプト（変更のみ=co:true / 全体=co:false）
   h += "<script>";
   h += "function setMode(co){";
   h += "var rows=document.querySelectorAll('#tbl tbody tr');";
   h += "for(var i=0;i<rows.length;i++){var r=rows[i];";
   h += "if(r.className.indexOf('sec')>=0){";
   h += "if(!co){r.style.display='';continue;}";
   h += "var has=false;for(var j=i+1;j<rows.length;j++){";
   h += "if(rows[j].className.indexOf('sec')>=0)break;";
   h += "if(rows[j].className.indexOf('changed')>=0){has=true;break;}}";
   h += "r.style.display=has?'':'none';";
   h += "}else{r.style.display=(co&&r.className.indexOf('changed')<0)?'none':'';}}";
   h += "document.getElementById('bAll').className=co?'tg':'tg act';";
   h += "document.getElementById('bChg').className=co?'tg act':'tg';}";
   h += "setMode(false);";
   h += "</script>";

   h += "</body></html>";

   //--- UTF-8 で書き出し (Common\Files\Hosopi3\)
   FolderCreate("Hosopi3", FILE_COMMON);
   string relPath = "Hosopi3\\Hosopi3_params.html";

   uchar bytes[];
   int len = StringToCharArray(h, bytes, 0, -1, CP_UTF8); // 末尾に \0 を含む
   int fh = FileOpen(relPath, FILE_WRITE | FILE_BIN | FILE_COMMON);
   if(fh == INVALID_HANDLE) {
      Print("[ParamDiff] HTML出力失敗 err=", GetLastError());
      return;
   }
   if(len > 1) FileWriteArray(fh, bytes, 0, len - 1); // 終端\0は書かない
   FileClose(fh);

   string absPath = TerminalInfoString(TERMINAL_COMMONDATA_PATH) + "\\Files\\" + relPath;
   Print("[ParamDiff] 出力: ", absPath, "  変更 ", changedCnt, "/", paramCnt);

   //--- ブラウザで開く (ライブ/テスター両方)
   int r = ShellExecuteW(0, "open", absPath, "", "", 1);
   if(r <= 32) {
      Print("[ParamDiff] ブラウザ起動に失敗 (code=", r, ")。ファイルは出力済み: ", absPath);
      if(!isTester) Alert("パラメータ差分HTMLを出力しました:\n", absPath);
   }
}

#endif // HOSOPI3_PARAMREPORT_MQH
