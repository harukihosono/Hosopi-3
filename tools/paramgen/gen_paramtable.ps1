# =====================================================================
# gen_paramtable.ps1  (Hosopi-3)
#   Parse Hosopi-3 input/sinput declarations and generate
#   ParamReport\Hosopi3_ParamTable.mqh (initial-default vs current table).
#   Re-run after changing any input parameter, then recompile.
#
#   Usage: powershell -ExecutionPolicy Bypass -File tools\paramgen\gen_paramtable.ps1
#   NOTE: keep this script ASCII-only (PS 5.1 misreads BOM-less UTF-8 scripts).
#
#   Hosopi-3 specifics:
#     - Two separate parameter files (MQL5 / MQL4). Rows parsed from each are
#       wrapped in the matching __MQL5__ / __MQL4__ guard so only the active
#       platform's rows compile.
#         MQL5 file: sections come from  sinput group "..."
#         MQL4 file: sections come from  input string <Title|_..|COMMENT_..>
#     - Multiple input declarations may appear on ONE physical line
#       (e.g. individual Lot/Spread/TP arrays). All are captured.
#       Limitation: a ';' inside a string default is not supported (none exist).
#
#   ELDRA2 ParamReport v4.18 features carried over:
#     - setVal / exportable  : machine-readable value for .set export
#     - enumOpts             : "0=label|1=label|..." for HTML enum dropdowns
#       (enum definitions are pre-scanned from the enum files below;
#        member labels come from the trailing // comment)
# =====================================================================
$ErrorActionPreference = 'Stop'

# Project root (this script lives in tools\paramgen)
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

# Per-file config. guard = platform macro, mode = section detection style.
$files = @(
    @{ rel='Hosopi3_AllParams_MQL5.mqh'; guard='__MQL5__'; mode='sinput' },
    @{ rel='Hosopi3_AllParams_MQL4.mqh'; guard='__MQL4__'; mode='titlestring' }
)

# Files scanned for enum definitions (dropdown options)
$enumFiles = @(
    'Hosopi3_Defines.mqh',
    'Hosopi3_Enums.mqh'
)

$builtin = @{
    'bool'=$true;'char'=$true;'uchar'=$true;'short'=$true;'ushort'=$true;
    'int'=$true;'uint'=$true;'long'=$true;'ulong'=$true;
    'double'=$true;'float'=$true;'string'=$true;'datetime'=$true;'color'=$true
}

function Esc([string]$s){
    if($null -eq $s){ return '' }
    return $s.Replace('\','\\').Replace('"','\"')
}
function Q([string]$s){ return '"' + (Esc $s) + '"' }

# Trim decorative characters from a section label
function CleanSection([string]$s){
    if($null -eq $s){ return '' }
    $s = $s.Trim()
    $s = $s.Trim(@('=',' ','-'))
    return $s.Trim()
}

# Is this string-input name a section marker (not a real param)?
function IsSectionName([string]$name){
    return ($name -match 'Title$') -or ($name -match '^_') -or ($name -match '^COMMENT')
}

# Split code vs // comment (ignore // inside string literals)
function Split-CodeComment([string]$line){
    $inStr = $false
    $n = $line.Length
    for($i=0; $i -lt ($n-1); $i++){
        $c = $line[$i]
        if($c -eq '"'){ $inStr = -not $inStr }
        elseif((-not $inStr) -and $c -eq '/' -and $line[$i+1] -eq '/'){
            return ,@($line.Substring(0,$i).Trim(), $line.Substring($i+2).Trim())
        }
    }
    return ,@($line.Trim(), '')
}

# ---- Pre-scan enum definitions for dropdown options (value=Japanese-comment label) ----
# enumMap[EnumName] = "0=label0|1=label1|..."  (first '=' splits value/label; '|' between options)
$enumMap = @{}
foreach($rel in $enumFiles){
    $path = Join-Path $root $rel
    $src = [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)
    $erx = [regex]'(?s)enum\s+([A-Za-z_]\w*)\s*\{(.*?)\}'
    foreach($em in $erx.Matches($src)){
        $ename = $em.Groups[1].Value
        $val = 0
        $opts = New-Object System.Collections.Generic.List[string]
        foreach($bl in ($em.Groups[2].Value -split "`n")){
            $bp = Split-CodeComment $bl.Trim()
            $bcode = $bp[0].TrimEnd(',').Trim()
            if($bcode -eq ''){ continue }
            $mm = [regex]::Match($bcode, '^([A-Za-z_]\w*)\s*(?:=\s*(-?\d+))?$')
            if(-not $mm.Success){ continue }
            if($mm.Groups[2].Success){ $val = [int]$mm.Groups[2].Value }
            $lbl = if($bp[1] -ne ''){ $bp[1] } else { $mm.Groups[1].Value }
            $lbl = $lbl -replace '[|=]',' '   # keep delimiters safe
            $opts.Add(("{0}={1}" -f $val, $lbl))
            $val++
        }
        if($opts.Count -gt 0){ $enumMap[$ename] = ($opts -join '|') }
    }
}

# Build one param row line from type/name/def/label
function Build-Row([string]$type,[string]$name,[string]$def,[string]$label){
    # setVal = machine-readable value for .set export (bool=true/false, enum=int)
    # defSetVal = same encoding but for the declaration default (clean default-set generation)
    $exportable = 'true'
    $enumOpts = ''   # enum rows only: "0=label|1=label|..." for dropdown
    if($type -eq 'bool'){
        $curExpr = '((' + $name + ') ? "ON" : "OFF")'
        $defExpr = '((' + $def  + ') ? "ON" : "OFF")'
        $setExpr = '((' + $name + ') ? "true" : "false")'
        $defSetExpr = '((' + $def + ') ? "true" : "false")'
    }
    elseif($type -eq 'double' -or $type -eq 'float'){
        # Hosopi3_NumStr: strip trailing zeros (0.01000000 -> 0.01)
        $curExpr = 'Hosopi3_NumStr((double)(' + $name + '))'
        $defExpr = 'Hosopi3_NumStr((double)(' + $def  + '))'
        $setExpr = 'Hosopi3_NumStr((double)(' + $name + '))'
        $defSetExpr = 'Hosopi3_NumStr((double)(' + $def + '))'
    }
    elseif($type -eq 'string'){
        $curExpr = '(' + $name + ')'
        $defExpr = '(' + $def  + ')'
        $setExpr = '(' + $name + ')'
        $defSetExpr = '(' + $def + ')'
    }
    elseif($type -eq 'datetime'){
        $curExpr = 'TimeToString((datetime)(' + $name + '))'
        $defExpr = 'TimeToString((datetime)(' + $def  + '))'
        $setExpr = '""'
        $defSetExpr = '""'
        $exportable = 'false'
    }
    elseif($type -eq 'color'){
        $curExpr = 'ColorToString((color)(' + $name + '),true)'
        $defExpr = 'ColorToString((color)(' + $def  + '),true)'
        $setExpr = 'IntegerToString((long)(' + $name + '))'
        $defSetExpr = 'IntegerToString((long)(' + $def + '))'
    }
    elseif($builtin.ContainsKey($type)){
        $curExpr = 'IntegerToString((long)(' + $name + '))'
        $defExpr = 'IntegerToString((long)(' + $def  + '))'
        $setExpr = 'IntegerToString((long)(' + $name + '))'
        $defSetExpr = 'IntegerToString((long)(' + $def + '))'
    }
    else {
        # enum type
        $curExpr = 'EnumToString((' + $type + ')(' + $name + '))'
        $defExpr = 'EnumToString((' + $type + ')(' + $def  + '))'
        $setExpr = 'IntegerToString((int)(' + $name + '))'
        $defSetExpr = 'IntegerToString((int)(' + $def + '))'
        if($enumMap.ContainsKey($type)){ $enumOpts = $enumMap[$type] }  # dropdown value=label
    }
    $cmp = '((' + $name + ') != (' + $def + '))'
    return '   rows[k].isSection=false; rows[k].name=' + (Q $name) + '; rows[k].label=' + (Q $label) + '; rows[k].section=""; rows[k].curVal=' + $curExpr + '; rows[k].defVal=' + $defExpr + '; rows[k].setVal=' + $setExpr + '; rows[k].defSetVal=' + $defSetExpr + '; rows[k].exportable=' + $exportable + '; rows[k].enumOpts=' + (Q $enumOpts) + '; rows[k].changed=' + $cmp + '; k++;'
}

# Build one section row line
function Build-SectionRow([string]$label){
    return '   rows[k].isSection=true; rows[k].name=""; rows[k].label=' + (Q $label) + '; rows[k].section=""; rows[k].curVal=""; rows[k].defVal=""; rows[k].setVal=""; rows[k].defSetVal=""; rows[k].exportable=false; rows[k].enumOpts=""; rows[k].changed=false; k++;'
}

$out = New-Object System.Collections.Generic.List[string]
$count = 0
$nParams = 0
$nSections = 0
$nGuarded = 0

foreach($f in $files){
    $rel  = $f.rel
    $mode = $f.mode
    $path = Join-Path $root $rel
    $lines = [System.IO.File]::ReadAllLines($path, [System.Text.Encoding]::UTF8)
    $guardStack = New-Object System.Collections.Generic.List[string]

    $out.Add('   // ===== ' + $rel + ' =====')
    $out.Add('#ifdef ' + $f.guard)

    foreach($line in $lines){
        $t = $line.Trim()

        # ---- preprocessor tracking ----
        if($t -match '^#\s*ifdef\s+__MQL5__'){ $guardStack.Add('MQL5'); continue }
        elseif($t -match '^#\s*ifdef\s+__MQL4__'){ $guardStack.Add('MQL4'); continue }
        elseif($t -match '^#\s*ifndef\s+__MQL5__'){ $guardStack.Add('!MQL5'); continue }
        elseif($t -match '^#\s*ifndef\s+__MQL4__'){ $guardStack.Add('!MQL4'); continue }
        elseif($t -match '^#\s*(if|ifdef|ifndef)\b'){ $guardStack.Add('OTHER'); continue }
        elseif($t -match '^#\s*endif'){ if($guardStack.Count -gt 0){ $guardStack.RemoveAt($guardStack.Count-1) }; continue }
        elseif($t -match '^#\s*else'){
            if($guardStack.Count -gt 0){
                $top = $guardStack[$guardStack.Count-1]
                switch($top){
                    'MQL5'  { $guardStack[$guardStack.Count-1] = '!MQL5' }
                    'MQL4'  { $guardStack[$guardStack.Count-1] = '!MQL4' }
                    '!MQL5' { $guardStack[$guardStack.Count-1] = 'MQL5' }
                    '!MQL4' { $guardStack[$guardStack.Count-1] = 'MQL4' }
                    default { $guardStack[$guardStack.Count-1] = 'OTHER' }
                }
            }
            continue
        }
        elseif($t -match '^#\s*elif'){ continue }

        # ---- section header from sinput group (MQL5 style) ----
        if($mode -eq 'sinput' -and $t -match '^\s*sinput\s+group\s+"(.*)"'){
            $lbl = CleanSection $matches[1]
            $out.Add((Build-SectionRow $lbl))
            $count++; $nSections++
            continue
        }

        # skip any remaining input group / sinput group lines
        if($t -match '^\s*s?input\s+group\b'){ continue }

        # only input / sinput data lines
        if($t -notmatch '^(input|sinput)\s'){ continue }

        $parts = Split-CodeComment $t
        $code = $parts[0]
        $comment = $parts[1]

        # find ALL declarations on this line (supports multiple per line)
        $decls = [regex]::Matches($code, '(?:input|sinput)\s+([A-Za-z_]\w*)\s+([A-Za-z_]\w*)\s*=\s*([^;]+);')
        if($decls.Count -eq 0){ continue }

        # active MQL4/MQL5 guards for this whole line (from source #ifdef)
        $guards = @($guardStack | Where-Object { $_ -ne 'OTHER' })

        foreach($m in $decls){
            $type = $m.Groups[1].Value
            $name = $m.Groups[2].Value
            $def  = $m.Groups[3].Value.Trim()

            if($name -match '\['){ continue }  # skip array inputs

            # use the trailing comment as label only when a single decl on the line
            $label = if($decls.Count -eq 1 -and $comment -ne ''){ $comment } else { $name }

            # ---- string-input section markers (Title / _.. / COMMENT_..) ----
            if($type -eq 'string' -and (IsSectionName $name)){
                if($mode -eq 'titlestring'){
                    # label = quoted default value if non-empty, else the comment
                    $secLbl = ''
                    $dm = [regex]::Match($def, '^"(.*)"$')
                    if($dm.Success -and $dm.Groups[1].Value.Trim() -ne ''){
                        $secLbl = CleanSection $dm.Groups[1].Value
                    } else {
                        $secLbl = CleanSection $comment
                    }
                    $out.Add((Build-SectionRow $secLbl))
                    $count++; $nSections++
                }
                # sinput mode: sinput group already provides the section -> skip title strings
                continue
            }

            $row = Build-Row $type $name $def $label

            if($guards.Count -gt 0){ $nGuarded++ }
            foreach($g in $guards){
                switch($g){
                    'MQL5'  { $out.Add('#ifdef __MQL5__') }
                    'MQL4'  { $out.Add('#ifdef __MQL4__') }
                    '!MQL5' { $out.Add('#ifndef __MQL5__') }
                    '!MQL4' { $out.Add('#ifndef __MQL4__') }
                }
            }
            $out.Add($row)
            for($gi=0; $gi -lt $guards.Count; $gi++){ $out.Add('#endif') }

            $count++; $nParams++
        }
    }

    $out.Add('#endif // ' + $f.guard)
}

$body = ($out -join "`r`n")

$header = @"
//+------------------------------------------------------------------+
//| Hosopi3_ParamTable.mqh                                           |
//| *** AUTO-GENERATED FILE - DO NOT EDIT MANUALLY ***               |
//| Generator: tools\paramgen\gen_paramtable.ps1                     |
//| Regenerate after changing any input parameter.                   |
//| entries=$count param=$nParams section=$nSections guarded=$nGuarded |
//+------------------------------------------------------------------+
#ifndef HOSOPI3_PARAMTABLE_MQH
#define HOSOPI3_PARAMTABLE_MQH

struct Hosopi3ParamRow {
   string section;
   string name;
   string label;
   string curVal;
   string defVal;
   string setVal;      // raw value for .set export (bool=true/false, enum=int)
   string defSetVal;   // default as .set value (for clean default-set generation)
   bool   exportable;  // can be written to .set (datetime etc. = false)
   string enumOpts;    // enum dropdown options "0=label|1=label|..." (empty=not enum)
   bool   changed;
   bool   isSection;
};

//+------------------------------------------------------------------+
//| Trim trailing zeros from a double (0.01000000 -> 0.01)           |
//+------------------------------------------------------------------+
string Hosopi3_NumStr(double v) {
   string s = DoubleToString(v, 8);
   int len = StringLen(s);
   if(StringFind(s, ".") < 0) return s;
   while(len > 0 && StringGetCharacter(s, len - 1) == '0') len--;
   if(len > 0 && StringGetCharacter(s, len - 1) == '.') len--;  // also drop trailing dot
   return StringSubstr(s, 0, len);
}

//+------------------------------------------------------------------+
//| Build the full "initial vs current" input table                 |
//+------------------------------------------------------------------+
void Hosopi3_BuildParamTable(Hosopi3ParamRow &rows[]) {
   ArrayResize(rows, $count);
   int k = 0;
$body
   ArrayResize(rows, k);
}

#endif // HOSOPI3_PARAMTABLE_MQH
"@

$outDir = Join-Path $root 'ParamReport'
if(-not (Test-Path $outDir)){ New-Item -ItemType Directory -Path $outDir | Out-Null }
$outPath = Join-Path $outDir 'Hosopi3_ParamTable.mqh'
$enc = New-Object System.Text.UTF8Encoding($true)
[System.IO.File]::WriteAllText($outPath, $header, $enc)

Write-Output ("Generated: " + $outPath)
Write-Output ("  entries=$count  params=$nParams  sections=$nSections  guarded=$nGuarded")
