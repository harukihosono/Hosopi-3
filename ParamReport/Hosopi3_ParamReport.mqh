//+------------------------------------------------------------------+
//| Hosopi3_ParamReport.mqh                                          |
//| 初期input(宣言時デフォルト) と 現在値 の差分を HTML 出力する。     |
//| ・全項目を表示し、変更された項目をハイライト                       |
//| ・検索 / セクション目次 / 折りたたみ / ツールチップ解説            |
//| ・HTML上で値を編集して .set ファイルとして保存可能                 |
//| ・出力先: <Common>\Files\Hosopi3\Hosopi3_params.html (UTF-8)      |
//| ・ライブ/テスター両方でボタンからブラウザ自動オープン             |
//| ・ELDRA2 の ParamReport v4.18相当を移植（ELDRA_ParamReport.mqh）  |
//+------------------------------------------------------------------+
#ifndef HOSOPI3_PARAMREPORT_MQH
#define HOSOPI3_PARAMREPORT_MQH

#include "Hosopi3_ParamTable.mqh"   // 自動生成: Hosopi3_BuildParamTable()
#include "Hosopi3_ParamHelp.mqh"    // FX初心者向け解説: Hosopi3_ParamHelp(name)

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

   // ---- 全入力デフォルト値を .set 形式で書き出し（配布用クリーンset生成の基盤）----
   // EAが IntegerToString((int)(既定enum)) 等を正しく計算するので、色/enumも正確。
   {
      FolderCreate("Hosopi3", FILE_COMMON);
      int dfh = FileOpen("Hosopi3\\Hosopi3_default.set", FILE_WRITE | FILE_TXT | FILE_ANSI | FILE_COMMON);
      if(dfh != INVALID_HANDLE) {
         FileWriteString(dfh, "; Hosopi3 全入力デフォルト値（自動生成）\r\n");
         for(int di = 0; di < total; di++) {
            if(rows[di].isSection || !rows[di].exportable) continue;
            FileWriteString(dfh, rows[di].name + "=" + rows[di].defSetVal + "\r\n");
         }
         FileClose(dfh);
      }
   }

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
   h += "body{font-family:'Meiryo UI','Segoe UI',sans-serif;background:#1b1b1b;color:#e8e8e8;margin:0 auto;padding:20px;max-width:600px;box-sizing:border-box;}";
   // 項目名と値を中央の狭いカラムに寄せ、左右の目線移動を減らす（値は項目のすぐ隣）
   h += "td.name{max-width:360px;}";
   h += "h1{font-size:20px;margin:0 0 4px 0;}";
   h += ".meta{color:#9aa0a6;font-size:13px;margin-bottom:16px;line-height:1.6;}";
   h += ".badge{display:inline-block;background:#2a2a2a;border-radius:4px;padding:2px 10px;margin-right:8px;}";
   h += ".chg{color:#ffd54f;font-weight:bold;}";
   h += "table{border-collapse:collapse;width:100%;font-size:13px;}";
   h += "th,td{text-align:left;padding:6px 10px;border-bottom:1px solid #333;}";
   h += "th{background:#262626;position:sticky;top:0;color:#bbb;}";
   h += "tr.sec td{background:#0f3b57;color:#cfe8ff;font-weight:bold;border-bottom:1px solid #155;}";
   h += "tr.changed td{background:#4a3d12;}";  // 変更行=はっきりした背景色（MT5同様に現在値のみ表示）
   h += "tr.changed td.name{border-left:3px solid #ffb300;}";
   h += "tr.changed .name{color:#ffd54f;font-weight:bold;}";
   h += "td.val{font-family:Consolas,monospace;}";
   h += "td.cur{color:#fff;} td.def{color:#8a8f94;}";
   h += "tr.changed td.cur{color:#ffe082;font-weight:bold;}";
   h += ".ev{background:#161d24;border:1px solid #33414d;color:#eaeaea;font-family:Consolas,monospace;font-size:13px;padding:4px 8px;width:150px;border-radius:3px;}";
   h += ".ev:focus{outline:none;border-color:#0f6fc4;background:#0d1620;}";
   h += ".ev.edited{border-color:#ffb300;color:#ffd54f;font-weight:bold;background:#241d0d;}";
   h += "select.ev{width:168px;}";
   h += ".toggle{margin:8px 0 12px 0;display:inline-block;margin-right:14px;}";
   h += ".tg{background:#2a2a2a;color:#ccc;border:1px solid #444;padding:6px 18px;cursor:pointer;font-size:13px;}";
   h += ".tg.act{background:#0f6fc4;color:#fff;border-color:#0f6fc4;font-weight:bold;}";
   h += ".tg:first-child{border-radius:4px 0 0 4px;}";
   h += ".tg:last-child{border-radius:0 4px 4px 0;}";
   h += "#q{background:#222;border:1px solid #444;color:#eee;padding:7px 12px;font-size:13px;width:300px;border-radius:4px;vertical-align:middle;}";
   h += ".toc{margin:0 0 14px 0;line-height:2.1;}";
   h += ".toc a{color:#7fb7e6;text-decoration:none;font-size:12px;background:#232a31;border:1px solid #33414d;border-radius:3px;padding:2px 8px;margin:0 4px 4px 0;display:inline-block;cursor:pointer;}";
   h += ".toc a:hover{background:#0f6fc4;color:#fff;}";
   h += "tr.sec td{cursor:pointer;}";
   h += ".arw{color:#7fb7e6;margin-right:6px;font-size:10px;}";
   // ホバー時ツールチップ（項目名/見出しにカーソルを乗せると解説を表示）
   h += "td.name{position:relative;}";
   h += "td[data-tip]{position:relative;}";
   h += "td.name[data-tip]{cursor:help;}";
   h += "td[data-tip]:hover::after{content:attr(data-tip);position:absolute;left:8px;top:calc(100% - 4px);z-index:50;";
   h += "background:#0d1620;border:1px solid #0f6fc4;color:#e8e8e8;padding:8px 12px;border-radius:5px;font-size:12px;";
   h += "font-weight:normal;line-height:1.7;white-space:pre-line;width:max-content;max-width:460px;box-shadow:0 6px 18px rgba(0,0,0,.6);}";
   h += ".memo{background:#1a2740;border-left:4px solid #f0c040;color:#f4ead2;padding:12px 16px;margin:0 0 16px;border-radius:6px;font-size:14px;line-height:1.75;white-space:pre-line;}";
   h += ".memo b{color:#f0c040;font-weight:600;}";
   h += "</style></head><body>";

   h += "<h1>Hosopi3 パラメータ差分レポート</h1>";
   h += "<div class=\"meta\">";
   h += "<span class=\"badge\">v" + HOSOPI3_VERSION + "</span>";
   h += "<span class=\"badge\">" + Hosopi3_HtmlEscape(_Symbol) + " " + Hosopi3_PeriodStr() + "</span>";
   h += "<span class=\"badge\">口座: " + Hosopi3_HtmlEscape(acc) + "</span>";
   h += "<span class=\"badge\">" + nowStr + "</span>";
   if(isTester) h += "<span class=\"badge\">バックテスト</span>";
   h += "<br><span class=\"chg\">変更 " + IntegerToString(changedCnt) + "</span> / 全 " + IntegerToString(paramCnt) + " 項目";
   h += "　（セクション見出しクリックで折りたたみ）";
   h += "</div>";

   // セット説明メモ（input_set_memo が非空なら上部に表示）
   if(input_set_memo != "")
      h += "<div class=\"memo\"><b>📝 メモ</b>　" + Hosopi3_HtmlEscape(input_set_memo) + "</div>";

   // 表示モード切替トグル（変更のみ / 全体）＋ 検索ボックス ＋ setエクスポート
   h += "<div class=\"toggle\">";
   h += "<button id=\"bChg\" class=\"tg\" onclick=\"setMode(true)\">変更のみ</button>";
   h += "<button id=\"bAll\" class=\"tg act\" onclick=\"setMode(false)\">全体</button>";
   h += "</div>";
   h += "<input id=\"q\" type=\"text\" placeholder=\"検索（項目名・値・番号）\" oninput=\"doSearch()\">";
   h += "<div class=\"toggle\" style=\"margin-left:14px;\">";
   h += "<button class=\"tg\" onclick=\"dlSet(false)\">💾 setで保存（全体）</button>";
   h += "</div>";
   h += "<div class=\"toggle\" style=\"margin-left:14px;\">";
   h += "<button class=\"tg\" onclick=\"resetEdits()\">↩ 編集をリセット</button>";
   h += "</div>";
   h += "<div class=\"meta\" style=\"margin-top:2px;\">「set値」列は編集可能。書き換えた値でsetを保存できます（黄=編集済み。true/false・数値・enum番号で入力）。</div>";

   // セクション目次（ジャンプナビ）
   h += "<div class=\"toc\">";
   int secNo = 0;
   for(int i = 0; i < total; i++) {
      if(!rows[i].isSection) continue;
      string t = rows[i].label;
      StringReplace(t, "=== ", "");
      StringReplace(t, " ===", "");
      StringReplace(t, "===", "");
      h += "<a onclick=\"jmp(" + IntegerToString(secNo) + ")\">" + Hosopi3_HtmlEscape(t) + "</a>";
      secNo++;
   }
   h += "</div>";

   h += "<table id=\"tbl\"><thead><tr><th>項目</th><th>値（set・編集可）</th></tr></thead><tbody>";

   secNo = 0;
   for(int i = 0; i < total; i++) {
      if(rows[i].isSection) {
         string st = rows[i].label;
         StringReplace(st, "=== ", "");
         StringReplace(st, " ===", "");
         StringReplace(st, "===", "");
         h += "<tr class=\"sec\" id=\"sec" + IntegerToString(secNo) + "\" data-s=\"" + IntegerToString(secNo) + "\" data-sn=\"" + Hosopi3_HtmlEscape(rows[i].name) + "\" data-st=\"" + Hosopi3_HtmlEscape(st) + "\" onclick=\"tgSec(" + IntegerToString(secNo) + ")\">";
         string secHelp = Hosopi3_SectionHelp(st);
         string secTip = (secHelp != "") ? " data-tip=\"" + Hosopi3_HtmlEscape(secHelp) + "\"" : "";
         h += "<td colspan=\"2\"" + secTip + "><span class=\"arw\">▼</span>" + Hosopi3_HtmlEscape(st) + "</td></tr>";
         secNo++;
         continue;
      }
      string cls = rows[i].changed ? " class=\"changed\"" : "";
      string lbl = rows[i].label;
      if(lbl == "") lbl = rows[i].name;
      // .setエクスポート用データ属性（data-n=input名 / data-v=生値）
      string dataAttr = "";
      if(rows[i].exportable) {
         dataAttr = " data-n=\"" + Hosopi3_HtmlEscape(rows[i].name) + "\" data-v=\"" + Hosopi3_HtmlEscape(rows[i].setVal) + "\"";
      }
      h += "<tr" + cls + dataAttr + ">";
      // ホバー用ツールチップ: FX初心者向け解説を先頭に、続けて変数名/初期値/enum選択肢
      string tip = "■ " + lbl;
      string help = Hosopi3_ParamHelp(rows[i].name);
      if(help != "") tip += "\n" + help;
      tip += "\n────────────";
      tip += "\n変数名: " + rows[i].name;
      if(rows[i].defVal != "") tip += "　／　初期値: " + rows[i].defVal;
      if(rows[i].enumOpts != "") {
         string eo = rows[i].enumOpts;
         StringReplace(eo, "=", ": ");
         StringReplace(eo, "|", " ／ ");
         tip += "\n選べる値: " + eo;
      }
      h += "<td class=\"name\" data-tip=\"" + Hosopi3_HtmlEscape(tip) + "\">" + Hosopi3_HtmlEscape(lbl) + "</td>";
      // set値の編集セル（exportableな行のみ入力欄。bool型・enum型はセレクトに自動変換）
      if(rows[i].exportable) {
         string sv = Hosopi3_HtmlEscape(rows[i].setVal);
         if(rows[i].setVal == "true" || rows[i].setVal == "false") {
            h += "<td><select class=\"ev\" data-orig=\"" + sv + "\" oninput=\"onEdit(this)\">";
            h += "<option value=\"true\"" + (rows[i].setVal == "true" ? " selected" : "") + ">true</option>";
            h += "<option value=\"false\"" + (rows[i].setVal == "false" ? " selected" : "") + ">false</option>";
            h += "</select></td>";
         } else if(rows[i].enumOpts != "") {
            // enum: 値=日本語ラベルのドロップダウン（現在のset値を選択状態に）
            h += "<td><select class=\"ev\" data-orig=\"" + sv + "\" oninput=\"onEdit(this)\">";
            string opts[];
            int no = StringSplit(rows[i].enumOpts, '|', opts);
            for(int oi = 0; oi < no; oi++) {
               int eq = StringFind(opts[oi], "=");
               if(eq < 0) continue;
               string ov = StringSubstr(opts[oi], 0, eq);
               string olbl = StringSubstr(opts[oi], eq + 1);
               h += "<option value=\"" + Hosopi3_HtmlEscape(ov) + "\"" + (ov == rows[i].setVal ? " selected" : "") + ">"
                    + Hosopi3_HtmlEscape(ov + ": " + olbl) + "</option>";
            }
            h += "</select></td>";
         } else {
            h += "<td><input class=\"ev\" type=\"text\" data-orig=\"" + sv + "\" value=\"" + sv + "\" oninput=\"onEdit(this)\"></td>";
         }
      } else {
         // 非exportable(datetime等)は編集不可だが現在値を読み取り専用で表示
         string ro = Hosopi3_HtmlEscape(rows[i].curVal);
         h += "<td class=\"val cur\">" + (ro == "" ? "-" : ro) + "</td>";
      }
      h += "</tr>";
   }
   h += "</tbody></table>";

   // フィルタ統合スクリプト（表示モード×検索×折りたたみを一括適用）
   h += "<script>";
   h += "var chgOnly=false,q='',collapsed={};";
   h += "function apply(){";
   h += "var rows=document.querySelectorAll('#tbl tbody tr');";
   h += "var query=q.toLowerCase();";
   h += "for(var i=0;i<rows.length;i++){var r=rows[i];";
   h += "if(r.className.indexOf('sec')<0)continue;";
   h += "var s=r.getAttribute('data-s');var vis=false;";
   h += "for(var j=i+1;j<rows.length;j++){var p=rows[j];";
   h += "if(p.className.indexOf('sec')>=0)break;";
   h += "var show=true;";
   h += "if(chgOnly&&p.className.indexOf('changed')<0)show=false;";
   h += "if(show&&query!==''&&p.textContent.toLowerCase().indexOf(query)<0&&r.textContent.toLowerCase().indexOf(query)<0)show=false;";
   h += "if(show)vis=true;";
   h += "p.style.display=(show&&!collapsed[s])?'':'none';}";
   h += "r.style.display=vis?'':'none';";
   h += "var a=r.querySelector('.arw');if(a)a.textContent=collapsed[s]?'▶':'▼';}";
   h += "document.getElementById('bAll').className=chgOnly?'tg':'tg act';";
   h += "document.getElementById('bChg').className=chgOnly?'tg act':'tg';}";
   h += "function setMode(c){chgOnly=c;apply();}";
   h += "function doSearch(){q=document.getElementById('q').value;apply();}";
   h += "function tgSec(s){collapsed[s]=!collapsed[s];apply();}";
   h += "function jmp(s){collapsed[s]=false;apply();var e=document.getElementById('sec'+s);";
   h += "if(e){e.scrollIntoView({behavior:'smooth',block:'start'});}}";
   // ---- .setファイル生成（UTF-16LE + BOM、MT5パラメータダイアログでそのままロード可能）----
   h += "var SETSYM='" + _Symbol + "';var SETVER='" + HOSOPI3_VERSION + "';";
   // 編集ハンドラ: 元値と異なれば黄色ハイライト、行にeditedクラス付与
   h += "function onEdit(el){var tr=el.closest('tr');var changed=(el.value!==el.getAttribute('data-orig'));";
   h += "if(changed){el.classList.add('edited');tr.setAttribute('data-edited','1');}else{el.classList.remove('edited');tr.removeAttribute('data-edited');}}";
   h += "function resetEdits(){var evs=document.querySelectorAll('.ev');for(var i=0;i<evs.length;i++){";
   h += "evs[i].value=evs[i].getAttribute('data-orig');evs[i].classList.remove('edited');";
   h += "var tr=evs[i].closest('tr');if(tr)tr.removeAttribute('data-edited');}}";
   // changedOnly指定時は「デフォルトから変更 or 編集済み」を出力
   h += "function dlSet(changedOnly){";
   h += "var rows=document.querySelectorAll('#tbl tbody tr');";
   h += "var d=new Date();";
   h += "var ds=d.getFullYear()+('0'+(d.getMonth()+1)).slice(-2)+('0'+d.getDate()).slice(-2);";
   h += "var lines=[];";
   h += "lines.push('; Hosopi3 v'+SETVER+' '+SETSYM+' パラメータエクスポート（'+(changedOnly?'変更/編集分のみ':'全体')+'）');";
   h += "lines.push('; パラメータ差分レポートから生成 '+d.toLocaleString('ja-JP'));";
   h += "var n=0;var pendSecName='',pendSecTitle='';";
   h += "for(var i=0;i<rows.length;i++){var r=rows[i];";
   // セクション行: メモ区切りとして保留（配下にパラメータが出た時のみ書き出す）
   h += "if(r.className.indexOf('sec')>=0){pendSecName=r.getAttribute('data-sn')||'';pendSecTitle=r.getAttribute('data-st')||'';continue;}";
   h += "var nm=r.getAttribute('data-n');if(!nm)continue;";
   // set値は編集欄があればその値、なければdata-v
   h += "var ev=r.querySelector('.ev');";
   h += "var v=ev?ev.value:r.getAttribute('data-v');if(v===null||v===undefined)continue;";
   h += "var isEdited=r.getAttribute('data-edited')==='1';";
   h += "if(changedOnly&&r.className.indexOf('changed')<0&&!isEdited)continue;";
   h += "v=(''+v).trim();if(v==='')continue;";
   // 小数の末尾ゼロを整形（0.24000000→0.24）
   h += "if(/^-?\\d+\\.\\d+$/.test(v)){v=v.replace(/(\\.\\d*?)0+$/,'$1').replace(/\\.$/,'.0');}";
   // 保留中のセクション区切りメモを先に書き出す
   h += "if(pendSecTitle){lines.push('');lines.push('; ==== '+pendSecTitle+' ====');}";
   h += "if(pendSecName){lines.push(pendSecName+'=');}";
   h += "pendSecName='';pendSecTitle='';";
   h += "lines.push(nm+'='+v);n++;}";
   h += "if(n===0){alert('出力対象のパラメータがありません');return;}";
   h += "var txt=lines.join('\\r\\n')+'\\r\\n';";
   h += "var buf=new Uint8Array(2+txt.length*2);buf[0]=0xFF;buf[1]=0xFE;";
   h += "for(var i2=0;i2<txt.length;i2++){var c=txt.charCodeAt(i2);buf[2+i2*2]=c&0xFF;buf[3+i2*2]=(c>>8)&0xFF;}";
   h += "var blob=new Blob([buf],{type:'application/octet-stream'});";
   h += "var a=document.createElement('a');a.href=URL.createObjectURL(blob);";
   h += "a.download='Hosopi3_'+SETSYM+'_'+ds+(changedOnly?'_diff':'_full')+'.set';";
   h += "document.body.appendChild(a);a.click();document.body.removeChild(a);";
   h += "setTimeout(function(){URL.revokeObjectURL(a.href);},2000);}";
   h += "apply();";
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
