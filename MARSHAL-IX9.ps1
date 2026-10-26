# =====================================================================
#  MARSHAL IX-9 PROJECT  v2.0  -  Game PC Optimizer (Windows 10/11)
#  Jalankan : klik dua kali MARSHAL-IX9.bat (minta izin Admin)
#  Logo     : taruh logo.png di folder yang sama untuk logo sendiri
# =====================================================================

# ---------- SETTINGS (boleh diubah) ----------
$Password = 'MARSHAL9'
$PingHost = '1.1.1.1'
$KillList = 'OneDrive', 'Teams', 'ms-teams', 'Skype', 'YourPhone', 'PhoneExperienceHost', 'Widgets', 'WidgetService'
$GameList = 'RobloxPlayerBeta', 'HD-Player', 'dnplayer', 'MEmuHeadless', 'AndroidEmulatorEx', 'aow_exe'
# app yang dihapus WINDOWS DEBLOAT (tambah/kurangi sesuai selera, boleh pakai *)
$BloatApps = 'Microsoft.BingNews', 'Microsoft.BingWeather', 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.MicrosoftOfficeHub',
    'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.People', 'Microsoft.WindowsFeedbackHub', 'Microsoft.WindowsMaps',
    'Microsoft.ZuneVideo', 'Microsoft.549981C3F5F10', 'Clipchamp.Clipchamp', 'MicrosoftTeams', 'MSTeams', 'Microsoft.MixedReality.Portal',
    'Microsoft.Microsoft3DViewer', 'Microsoft.SkypeApp', 'Microsoft.PowerAutomateDesktop', 'Microsoft.Windows.DevHome',
    'Microsoft.OutlookForWindows', '*CandyCrush*', '*BubbleWitch*', '*FarmVille*', '*MarchofEmpires*', '*RoyalRevolt*'

# ---------- auto admin + satu instance ----------
$me = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not (New-Object Security.Principal.WindowsPrincipal($me)).IsInRole('Administrator')) {
    try { Start-Process powershell -Verb RunAs -WindowStyle Hidden -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" } catch {}
    exit
}
$script:mtx = New-Object Threading.Mutex($false, 'MARSHAL-IX9-LOCK')
try { $got = $script:mtx.WaitOne(0) } catch { $got = $true }
if (-not $got) { exit }

Add-Type -AssemblyName System.Windows.Forms, System.Drawing
if (-not ('MX' -as [type])) {
Add-Type -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
public static class MX {
  [StructLayout(LayoutKind.Sequential)]
  public class MS { public uint len = 64; public uint load; public ulong tot, avail, a, b, c, d, e; }
  [StructLayout(LayoutKind.Sequential, Pack = 1)]
  struct TP { public int C; public long L; public int A; }
  [DllImport("kernel32.dll")] static extern bool GlobalMemoryStatusEx([In, Out] MS m);
  [DllImport("kernel32.dll")] static extern bool GetSystemTimes(out long i, out long k, out long u);
  [DllImport("psapi.dll")] static extern bool EmptyWorkingSet(IntPtr h);
  [DllImport("ntdll.dll")] static extern int NtSetSystemInformation(int c, ref int i, int l);
  [DllImport("advapi32.dll")] static extern bool OpenProcessToken(IntPtr p, uint a, out IntPtr t);
  [DllImport("advapi32.dll")] static extern bool LookupPrivilegeValue(string s, string n, out long l);
  [DllImport("advapi32.dll")] static extern bool AdjustTokenPrivileges(IntPtr t, bool d, ref TP n, int l, IntPtr p, IntPtr r);
  [DllImport("user32.dll")] static extern bool SystemParametersInfo(int a, int b, int[] c, int d);
  [DllImport("user32.dll")] static extern bool ReleaseCapture();
  [DllImport("user32.dll")] static extern IntPtr SendMessage(IntPtr h, int m, int w, int l);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
  static long pi, pk, pu;
  public static double[] Mem() { MS m = new MS(); GlobalMemoryStatusEx(m); return new double[] { m.tot, m.avail }; }
  public static int Cpu() {
    long i, k, u; GetSystemTimes(out i, out k, out u);
    long di = i - pi, t = (k - pk) + (u - pu); pi = i; pk = k; pu = u;
    return t <= 0 ? 0 : (int)(100 * (t - di) / t);
  }
  public static int Trim(string[] skip) {
    int n = 0;
    foreach (Process p in Process.GetProcesses()) {
      try { if (Array.IndexOf(skip, p.ProcessName) < 0 && EmptyWorkingSet(p.Handle)) n++; } catch { }
      p.Dispose();
    }
    return n;
  }
  public static bool Purge() {
    IntPtr t;
    if (!OpenProcessToken(Process.GetCurrentProcess().Handle, 0x28, out t)) return false;
    TP tp = new TP(); tp.C = 1; tp.A = 2;
    if (!LookupPrivilegeValue(null, "SeProfileSingleProcessPrivilege", out tp.L)) return false;
    AdjustTokenPrivileges(t, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
    int cmd = 4;
    return NtSetSystemInformation(80, ref cmd, 4) == 0;
  }
  public static void Accel(bool on) { SystemParametersInfo(4, 0, on ? new int[] { 6, 10, 1 } : new int[] { 0, 0, 0 }, 3); }
  public static void Keys(int d) { SystemParametersInfo(0x17, d, null, 3); SystemParametersInfo(0x0B, 31, null, 3); }
  public static void Drag(IntPtr h) { ReleaseCapture(); SendMessage(h, 0xA1, 2, 0); }
}
'@
}
[void][MX]::SetProcessDPIAware()
[Windows.Forms.Application]::EnableVisualStyles()

$script:busy = $false
$script:tries = 0
$script:tn = 0
$script:pulse = $false
$script:gameOn = $false
$script:pingTask = $null
$script:png = New-Object Net.NetworkInformation.Ping
$script:dot = [string][char]0x25CF
$script:locked = New-Object 'System.Collections.Generic.HashSet[int]'
$script:hc = New-Object 'System.Collections.Generic.List[int]'
$script:hr = New-Object 'System.Collections.Generic.List[int]'
$GuidRx = '(?i)[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}'
$RainChars = '01ABCDEF789<>/\|=+*#%'.ToCharArray()

# ---------- theme ----------
function Col($h) { [Drawing.ColorTranslator]::FromHtml($h) }
$Clr = @{
    bg = (Col '#070204'); panel = (Col '#10050a'); tile = (Col '#18080e'); hdr = (Col '#2b060e')
    red = (Col '#ff1f3a'); dim = (Col '#8a1a28'); txt = (Col '#ffd9dc'); ok = (Col '#41ff8b')
    warn = (Col '#ffb020'); btn = (Col '#1f060c'); btnh = (Col '#4d0b18')
}
$Fnt = @{
    title = New-Object Drawing.Font('Bahnschrift', 20, [Drawing.FontStyle]::Bold)
    big = New-Object Drawing.Font('Bahnschrift', 13, [Drawing.FontStyle]::Bold)
    head = New-Object Drawing.Font('Bahnschrift', 10, [Drawing.FontStyle]::Bold)
    name = New-Object Drawing.Font('Consolas', 11, [Drawing.FontStyle]::Bold)
    body = New-Object Drawing.Font('Consolas', 9.5)
    small = New-Object Drawing.Font('Consolas', 8.5)
}
$Pn = @{
    red = New-Object Drawing.Pen($Clr.red, 1)
    dim = New-Object Drawing.Pen($Clr.dim, 1)
    cpu = New-Object Drawing.Pen($Clr.red, 1.6)
    ram = New-Object Drawing.Pen($Clr.warn, 1.2)
    grid = New-Object Drawing.Pen((Col '#2a0a12'), 1)
}
$Br = @{
    red = New-Object Drawing.SolidBrush($Clr.red)
    warn = New-Object Drawing.SolidBrush($Clr.warn)
    head = New-Object Drawing.SolidBrush((Col '#ff6677'))
    fade = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(36, 3, 1, 2))
}

# ---------- UI helpers ----------
function Dbl($o) { $o.GetType().GetProperty('DoubleBuffered', [Reflection.BindingFlags]'Instance,NonPublic').SetValue($o, $true, $null) }
function Ctl($t, $x, $y, $w, $h, $txt, $parent, $font = $Fnt.body, $fore = $Clr.txt) {
    $o = New-Object "Windows.Forms.$t"
    if ($t -eq 'Label') { $o.AutoSize = $false; $o.BackColor = [Drawing.Color]::Transparent }
    $o.SetBounds($x, $y, $w, $h); $o.Text = $txt; $o.Font = $font; $o.ForeColor = $fore
    $parent.Controls.Add($o); $o
}
function Lbl($x, $y, $w, $h, $txt, $parent, $font = $Fnt.body, $fore = $Clr.txt, $al = 'MiddleLeft') {
    $l = Ctl 'Label' $x $y $w $h $txt $parent $font $fore; $l.TextAlign = $al; $l
}
function Btn($x, $y, $w, $h, $txt, $parent, $tag) {
    $b = Ctl 'Button' $x $y $w $h $txt $parent $Fnt.name $Clr.red
    $b.FlatStyle = 'Flat'; $b.UseVisualStyleBackColor = $false; $b.BackColor = $Clr.btn
    $b.FlatAppearance.BorderColor = $Clr.red; $b.FlatAppearance.BorderSize = 1
    $b.FlatAppearance.MouseOverBackColor = $Clr.btnh; $b.FlatAppearance.MouseDownBackColor = $Clr.dim
    $b.Cursor = 'Hand'; $b.Tag = $tag; $b
}
function Card($x, $y, $w, $h, $title, $parent) {
    $p = Ctl 'Panel' $x $y $w $h '' $parent; $p.BackColor = $Clr.panel; Dbl $p
    $p.Add_Paint({ $_.Graphics.DrawRectangle($Pn.red, 0, 0, $this.Width - 1, $this.Height - 1) })
    if ($title) { $hl = Lbl 1 1 ($w - 2) 30 $title $p $Fnt.head $Clr.red 'MiddleCenter'; $hl.BackColor = $Clr.hdr }
    $p
}
function Bar($x, $y, $w, $parent) {
    $p = Ctl 'Panel' $x $y $w 8 '' $parent; $p.BackColor = Col '#240a10'; $p.Tag = 0; Dbl $p
    $p.Add_Paint({
        $wd = [int](($this.Width - 2) * [int]$this.Tag / 100)
        $bb = if ([int]$this.Tag -ge 85) { $Br.warn } else { $Br.red }
        if ($wd -gt 0) { $_.Graphics.FillRectangle($bb, 1, 1, $wd, $this.Height - 2) }
        $_.Graphics.DrawRectangle($Pn.dim, 0, 0, $this.Width - 1, $this.Height - 1)
    })
    $p
}
function New-Emblem {
    $bm = New-Object Drawing.Bitmap(240, 240)
    $g = [Drawing.Graphics]::FromImage($bm); $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAlias'
    $g.DrawEllipse((New-Object Drawing.Pen([Drawing.Color]::FromArgb(45, $Clr.red), 16)), 14, 14, 212, 212)
    $g.DrawEllipse((New-Object Drawing.Pen($Clr.red, 6)), 14, 14, 212, 212)
    $g.DrawEllipse((New-Object Drawing.Pen($Clr.dim, 2)), 36, 36, 168, 168)
    $sf = New-Object Drawing.StringFormat; $sf.Alignment = 'Center'; $sf.LineAlignment = 'Center'
    $g.DrawString('IX-9', (New-Object Drawing.Font('Bahnschrift', 48, [Drawing.FontStyle]::Bold)), $Br.red, (New-Object Drawing.RectangleF(0, 0, 240, 240)), $sf)
    $g.Dispose(); $bm
}
function New-Glow($text, $size, $w, $h) {
    $bm = New-Object Drawing.Bitmap($w, $h)
    $g = [Drawing.Graphics]::FromImage($bm); $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAlias'
    $f = New-Object Drawing.Font('Bahnschrift', $size, [Drawing.FontStyle]::Bold)
    $sf = New-Object Drawing.StringFormat; $sf.Alignment = 'Center'; $sf.LineAlignment = 'Center'
    $halo = New-Object Drawing.SolidBrush([Drawing.Color]::FromArgb(20, $Clr.red))
    foreach ($o in 8, 5, 2) {
        foreach ($dx in (0 - $o), 0, $o) {
            foreach ($dy in (0 - $o), 0, $o) { $g.DrawString($text, $f, $halo, (New-Object Drawing.RectangleF($dx, $dy, $w, $h)), $sf) }
        }
    }
    $g.DrawString($text, $f, $Br.red, (New-Object Drawing.RectangleF(0, 0, $w, $h)), $sf)
    $g.Dispose(); $bm
}
$logo = "$PSScriptRoot\logo.png"
try { $Emblem = if (Test-Path $logo) { [Drawing.Image]::FromFile($logo) } else { New-Emblem } } catch { $Emblem = New-Emblem }

# ---------- system helpers ----------
function SetReg($p, $n, $v, $t = 'DWord') {
    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    Set-ItemProperty -Path $p -Name $n -Value $v -Type $t -Force
}
function PCfg { & powercfg.exe @args 2>&1 | Out-Null }
function Find-Plan { [regex]::Match("$((powercfg /list) -match 'MARSHAL')", $GuidRx).Value }
function Get-MxPlan {
    $g = Find-Plan
    if (-not $g) {
        foreach ($src in 'e9a42b02-d5df-448d-aa00-03f14749eb61', '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c') {
            $g = [regex]::Match("$(powercfg /duplicatescheme $src 2>&1)", $GuidRx).Value
            if ($g) { PCfg /changename $g 'MARSHAL IX-9' 'Max performance (AC)'; break }
        }
    }
    if ($g) { $g } else { 'SCHEME_CURRENT' }
}
function Clean-Dir($d) {
    if (-not (Test-Path $d)) { return 0 }
    $a = (Get-ChildItem $d -Recurse -Force -File -EA SilentlyContinue | Measure-Object Length -Sum).Sum
    Get-ChildItem $d -Force -EA SilentlyContinue | Remove-Item -Recurse -Force -EA SilentlyContinue
    $b = (Get-ChildItem $d -Recurse -Force -File -EA SilentlyContinue | Measure-Object Length -Sum).Sum
    [long][math]::Max(0, [double]$a - [double]$b)
}
function Test-Game {
    foreach ($g in $GameList) { if (Get-Process -Name $g -EA SilentlyContinue) { return $true } }
    $false
}
function Boost-Games {
    $n = 0
    foreach ($g in $GameList) {
        foreach ($p in @(Get-Process -Name $g -EA SilentlyContinue)) {
            try {
                if ($p.PriorityClass -ne 'High') { $p.PriorityClass = 'High'; $n++; Log "HIGH priority -> $($p.ProcessName)" 'ok' }
            } catch {
                if ($script:locked.Add($p.Id)) { Log "Protected, skipped: $($p.ProcessName)" 'warn' }
            }
        }
    }
    $n
}

# ---------- startup manager helpers ----------
function Get-Startup {
    $out = @()
    $A = 'Software\Microsoft\Windows\CurrentVersion'
    $src = @(
        @("HKCU:\$A\Run", "HKCU:\$A\Explorer\StartupApproved\Run"),
        @("HKLM:\$A\Run", "HKLM:\$A\Explorer\StartupApproved\Run"),
        @("HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run", "HKLM:\$A\Explorer\StartupApproved\Run32")
    )
    foreach ($s in $src) {
        $k = Get-Item $s[0] -EA SilentlyContinue
        if (-not $k) { continue }
        foreach ($n in $k.GetValueNames()) {
            if (-not $n) { continue }
            $on = $true
            $st = Get-ItemProperty $s[1] -Name $n -EA SilentlyContinue
            if ($st) { $b = $st.$n; if ($b -and ($b[0] % 2 -eq 1)) { $on = $false } }
            $out += [pscustomobject]@{ Name = $n; On = $on; Key = $s[1] }
        }
    }
    $out
}
function Set-Startup($e, $on) {
    $v = New-Object byte[] 12
    $v[0] = if ($on) { 2 } else { 3 }
    if (-not (Test-Path $e.Key)) { New-Item $e.Key -Force | Out-Null }
    Set-ItemProperty -Path $e.Key -Name $e.Name -Value $v -Type Binary -Force
}
function Apply-Startup($on) {
    $n = 0
    foreach ($li in @($script:lv.CheckedItems)) {
        try {
            Set-Startup $li.Tag $on; $li.Tag.On = $on; $n++
            $li.Text = ('[{0}] {1}' -f $(if ($on) { 'ON ' } else { 'OFF' }), $li.Tag.Name)
            $li.ForeColor = if ($on) { $Clr.txt } else { $Clr.dim }; $li.Checked = $false
        } catch {}
    }
    Log ("Startup: $n item(s) " + $(if ($on) { 'enabled' } else { 'disabled' })) 'ok'
}

# ---------- registry tweaks: group, path, name, value, restore ('DEL' = remove), type ----------
$Tweaks = @()
function Tk($g, $p, $n, $v, $r = $null, $t = 'DWord') { $script:Tweaks += , @($g, $p, $n, $v, $r, $t) }
function Tw($g, $undo = $false) {
    foreach ($t in $Tweaks) {
        if ($t[0] -ne $g) { continue }
        try {
            if (-not $undo) { SetReg $t[1] $t[2] $t[3] $t[5] }
            elseif ($t[4] -eq 'DEL') { Remove-ItemProperty -Path $t[1] -Name $t[2] -EA SilentlyContinue }
            elseif ($null -ne $t[4]) { SetReg $t[1] $t[2] $t[4] $t[5] }
        } catch { Log "skip $($t[2])" 'warn' }
    }
}
$MM = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
$AX = 'HKCU:\Control Panel\Accessibility'
Tk 'game' 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0 1
Tk 'game' 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0 1
Tk 'game' 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
Tk 'game' 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling' 'PowerThrottlingOff' 1 'DEL'
Tk 'game' 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38 2
Tk 'game' $MM 'SystemResponsiveness' 0 20
Tk 'game' "$MM\Tasks\Games" 'GPU Priority' 8 8
Tk 'game' "$MM\Tasks\Games" 'Priority' 6 2
Tk 'game' "$MM\Tasks\Games" 'Scheduling Category' 'High' 'Medium' 'String'
Tk 'game' "$MM\Tasks\Games" 'SFIO Priority' 'High' 'Normal' 'String'
Tk 'gpu' 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2 'DEL'
Tk 'gpu' 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0 1
Tk 'gpu' 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAnimations' 0 1
Tk 'gpu' 'HKCU:\Control Panel\Desktop\WindowMetrics' 'MinAnimate' '0' '1' 'String'
Tk 'input' "$AX\StickyKeys" 'Flags' '506' '510' 'String'
Tk 'input' "$AX\Keyboard Response" 'Flags' '122' '126' 'String'
Tk 'input' "$AX\ToggleKeys" 'Flags' '58' '62' 'String'
Tk 'net' $MM 'NetworkThrottlingIndex' -1 10
$CD = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager'
foreach ($cn in 'SilentInstalledAppsEnabled', 'SystemPaneSuggestionsEnabled', 'SoftLandingEnabled', 'ContentDeliveryAllowed', 'OemPreInstalledAppsEnabled', 'PreInstalledAppsEnabled', 'RotatingLockScreenOverlayEnabled', 'SubscribedContent-338387Enabled', 'SubscribedContent-338388Enabled', 'SubscribedContent-338389Enabled', 'SubscribedContent-338393Enabled', 'SubscribedContent-353694Enabled', 'SubscribedContent-353696Enabled', 'SubscribedContent-310093Enabled') { Tk 'debloat' $CD $cn 0 1 }
$EA = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
Tk 'debloat' 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0 1
Tk 'debloat' $EA 'Start_IrisRecommendations' 0 1
Tk 'debloat' $EA 'ShowSyncProviderNotifications' 0 1
Tk 'debloat' $EA 'TaskbarDa' 0 1
Tk 'debloat' $EA 'TaskbarMn' 0 1
Tk 'debloat' 'HKCU:\Software\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 1 'DEL'
Tk 'debloat' 'HKCU:\Software\Policies\Microsoft\Windows\WindowsAI' 'DisableAIDataAnalysis' 1 'DEL'
Tk 'debloat' 'HKCU:\Software\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 1 'DEL'
Tk 'debloat' 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0 'DEL'
Tk 'debloat' 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'EnableActivityFeed' 0 'DEL'
Tk 'debloat' 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' 'PublishUserActivities' 0 'DEL'
$Tasks = @(
    @('\Microsoft\Windows\Application Experience\', 'Microsoft Compatibility Appraiser'),
    @('\Microsoft\Windows\Application Experience\', 'ProgramDataUpdater'),
    @('\Microsoft\Windows\Customer Experience Improvement Program\', 'Consolidator'),
    @('\Microsoft\Windows\Customer Experience Improvement Program\', 'UsbCeip')
)

# ---------- window ----------
$FW = 1000; $FH = 660
$form = New-Object Windows.Forms.Form
$form.Text = 'MARSHAL IX-9 PROJECT'; $form.FormBorderStyle = 'None'; $form.StartPosition = 'CenterScreen'
$form.AutoScaleDimensions = New-Object Drawing.SizeF(96, 96); $form.AutoScaleMode = 'Dpi'
$form.ClientSize = New-Object Drawing.Size($FW, $FH); $form.BackColor = $Clr.bg; Dbl $form
try { $form.Icon = [Drawing.Icon]::FromHandle((New-Object Drawing.Bitmap($Emblem)).GetHicon()) } catch {}
$form.Add_Paint({
    $r = $this.ClientRectangle
    $gb = New-Object Drawing.Drawing2D.LinearGradientBrush($r, (Col '#2a050b'), (Col '#030102'), [single]55)
    $_.Graphics.FillRectangle($gb, $r); $gb.Dispose()
    $_.Graphics.DrawRectangle($Pn.red, 0, 0, $r.Width - 1, $r.Height - 1)
})

# title bar
$bar = Ctl 'Panel' 0 0 $FW 34 '' $form; $bar.BackColor = Col '#0c0306'
$lblT = Lbl 14 0 500 34 'MARSHAL IX-9 PROJECT   //   v2.0' $bar $Fnt.head $Clr.red
foreach ($o in $bar, $lblT) { $o.Add_MouseDown({ if ($_.Button -eq 'Left') { [MX]::Drag($form.Handle) } }) }
$bMin = Lbl ($FW - 88) 0 44 34 ([string][char]0x2014) $bar $Fnt.head $Clr.txt 'MiddleCenter'
$bClose = Lbl ($FW - 44) 0 44 34 ([string][char]0x2715) $bar $Fnt.head $Clr.txt 'MiddleCenter'
foreach ($o in $bMin, $bClose) {
    $o.Cursor = 'Hand'
    $o.Add_MouseEnter({ $this.ForeColor = $Clr.red }); $o.Add_MouseLeave({ $this.ForeColor = $Clr.txt })
}
$bMin.Add_Click({ $form.WindowState = 'Minimized' }); $bClose.Add_Click({ $form.Close() })

# ---------- login screen (digital rain) ----------
$login = Ctl 'Panel' 0 34 $FW ($FH - 34) '' $form; $login.BackColor = Col '#030102'; Dbl $login
$script:rain = $null
$login.Add_Paint({ if ($script:rain) { $_.Graphics.DrawImageUnscaled($script:rain, 0, 0) } })
$lc = Card (($FW - 460) / 2) 100 460 420 $null $login
$pic = Ctl 'PictureBox' 180 20 100 100 '' $lc; $pic.Image = $Emblem; $pic.SizeMode = 'Zoom'
$gl = Ctl 'PictureBox' 20 124 420 64 '' $lc; $gl.Image = (New-Glow 'MARSHAL IX-9' 64 840 128); $gl.SizeMode = 'Zoom'
[void](Lbl 0 192 460 22 'P R O J E C T     //     A C C E S S   C O N T R O L' $lc $Fnt.body $Clr.dim 'MiddleCenter')
$pw = Ctl 'TextBox' 70 238 320 34 '' $lc $Fnt.big $Clr.txt
$pw.UseSystemPasswordChar = $true; $pw.TextAlign = 'Center'; $pw.BackColor = Col '#1c070d'; $pw.BorderStyle = 'FixedSingle'
$btnLogin = Btn 70 286 320 42 'AUTHENTICATE' $lc $null
$msg = Lbl 0 340 460 22 'ENTER PASSWORD TO CONTINUE' $lc $Fnt.body $Clr.dim 'MiddleCenter'
[void](Lbl 0 388 460 20 'v2.0   //   GAME PC OPTIMIZER' $lc $Fnt.small $Clr.dim 'MiddleCenter')
$form.AcceptButton = $btnLogin

# ---------- main screen ----------
$main = Ctl 'Panel' 0 34 $FW ($FH - 34) '' $form; $main.BackColor = [Drawing.Color]::Transparent; $main.Visible = $false
$lblStatus = Lbl 14 4 320 22 "$($script:dot) STATUS: ONLINE" $main $Fnt.name $Clr.red
$lblUser = Lbl ($FW - 14 - 560) 4 560 22 '' $main $Fnt.body $Clr.dim 'MiddleRight'

# sidebar
$side = Card 12 32 204 580 $null $main
$pic2 = Ctl 'PictureBox' 52 12 100 100 '' $side; $pic2.Image = $Emblem; $pic2.SizeMode = 'Zoom'
$gl2 = Ctl 'PictureBox' 0 112 204 34 '' $side; $gl2.Image = (New-Glow 'MARSHAL' 40 408 68); $gl2.SizeMode = 'Zoom'
[void](Lbl 0 146 204 18 'IX-9  PROJECT' $side $Fnt.body $Clr.dim 'MiddleCenter')
[void](Lbl 12 176 180 18 'SYSTEM MONITOR' $side $Fnt.head $Clr.red)
$lblCpu = Lbl 12 198 180 16 'CPU' $side; $barCpu = Bar 12 216 180 $side
$lblRam = Lbl 12 232 180 16 'RAM' $side; $barRam = Bar 12 250 180 $side
$lblPing = Lbl 12 266 180 16 'PING  --' $side
$graph = Ctl 'Panel' 12 288 180 64 '' $side; $graph.BackColor = Col '#080204'; Dbl $graph
$graph.Add_Paint({
    $g = $_.Graphics; $g.SmoothingMode = 'AntiAlias'; $w = $this.Width - 1; $h = $this.Height - 1
    foreach ($q in 0.25, 0.5, 0.75) { $g.DrawLine($Pn.grid, 0, [int]($h * $q), $w, [int]($h * $q)) }
    $g.DrawRectangle($Pn.dim, 0, 0, $w, $h)
    foreach ($s in @(@($script:hr, $Pn.ram), @($script:hc, $Pn.cpu))) {
        $l = $s[0]; $n = $l.Count
        if ($n -lt 2) { continue }
        $pts = [Drawing.PointF[]]::new($n)
        for ($i = 0; $i -lt $n; $i++) { $pts[$i] = New-Object Drawing.PointF(($w * (60 - $n + $i) / 59), ($h - 2 - ($h - 4) * $l[$i] / 100)) }
        $g.DrawLines($s[1], $pts)
    }
})
$lblInfo = Lbl 12 360 180 112 '' $side $Fnt.small $Clr.dim 'TopLeft'
$tgl = Ctl 'CheckBox' 12 486 180 34 'AUTO-BOOST : OFF' $side $Fnt.name $Clr.red
$tgl.Appearance = 'Button'; $tgl.FlatStyle = 'Flat'; $tgl.TextAlign = 'MiddleCenter'; $tgl.BackColor = $Clr.btn; $tgl.Cursor = 'Hand'
$tgl.FlatAppearance.BorderColor = $Clr.red; $tgl.FlatAppearance.CheckedBackColor = $Clr.dim; $tgl.FlatAppearance.MouseOverBackColor = $Clr.btnh
$btnRestore = Btn 12 528 180 34 'RESTORE DEFAULTS' $side 'restore'

# optimizer card
$mid = Card 228 32 430 580 'SYSTEM OPTIMIZER' $main
$Features = @(
    @('clean', 'DEEP CLEANER', 'Temp, browser/app cache, dumps, bin'),
    @('ram', 'RAM PURGE', 'Trim memory + flush standby list'),
    @('game', 'GAME MODE', 'Max power plan, CPU boost, priority'),
    @('gpu', 'iGPU TUNING', 'HW scheduling, Game DVR off, light UI'),
    @('input', 'INPUT LAG FIX', 'Mouse accel off, key delay, USB power'),
    @('net', 'TCP OPTIMIZER', 'Nagle off, no throttling, TCP tune'),
    @('dns', 'DNS FLUSH', 'Clear DNS cache + ping test'),
    @('debloat', 'WINDOWS DEBLOAT', 'Remove junk apps, ads, Copilot, telemetry'),
    @('startup', 'STARTUP MANAGER', 'Pick which apps launch with Windows')
)
$Names = @{ restore = 'RESTORE DEFAULTS' }
$Rows = @{}
$y = 40
foreach ($ft in $Features) {
    $Names[$ft[0]] = $ft[1]
    $first = if ($ft[0] -eq 'startup') { 'OPEN' } else { 'APPLY' }
    $again = if ($ft[0] -eq 'startup') { 'OPEN' } else { 'RE-RUN' }
    $row = Ctl 'Panel' 8 $y 414 46 '' $mid; $row.BackColor = $Clr.tile
    $acc = Ctl 'Panel' 0 0 3 46 '' $row; $acc.BackColor = $Clr.red
    [void](Lbl 16 3 290 22 $ft[1] $row $Fnt.name $Clr.txt)
    [void](Lbl 16 25 300 17 $ft[2] $row $Fnt.small $Clr.dim)
    $b = Btn 322 7 84 32 $first $row $ft[0]
    $b.Add_Click({ Invoke-Feature $this.Tag })
    $Rows[$ft[0]] = @{ acc = $acc; btn = $b; first = $first; again = $again }
    $y += 50
}
$btnAll = Btn 8 496 414 52 'ACTIVATE ALL' $mid 'all'
$btnAll.Font = $Fnt.big; $btnAll.ForeColor = $Clr.txt; $btnAll.BackColor = Col '#35070f'; $btnAll.FlatAppearance.MouseOverBackColor = $Clr.dim
[void](Lbl 8 552 414 18 'Runs all except Debloat and Startup Manager' $mid $Fnt.small $Clr.dim 'MiddleCenter')

# log card
$rc = Card 670 32 318 580 'LIVE LOG' $main
$rtb = Ctl 'RichTextBox' 8 40 302 532 '' $rc $Fnt.small $Clr.txt
$rtb.ReadOnly = $true; $rtb.BorderStyle = 'None'; $rtb.BackColor = Col '#060103'; $rtb.DetectUrls = $false; $rtb.ScrollBars = 'Vertical'

# busy scanner (top edge)
$scan = Ctl 'Panel' 0 34 $FW 3 '' $form; $scan.BackColor = Col '#2a0a12'; $scan.Tag = 0; Dbl $scan
$scan.Add_Paint({
    if ($script:busy) {
        $x = [int]$this.Tag - 200
        $lg = New-Object Drawing.Drawing2D.LinearGradientBrush((New-Object Drawing.Rectangle($x, 0, 200, $this.Height)), (Col '#2a0a12'), $Clr.red, [Drawing.Drawing2D.LinearGradientMode]::Horizontal)
        $_.Graphics.FillRectangle($lg, $x, 0, 200, $this.Height); $lg.Dispose()
    }
})
$scan.BringToFront()

# ---------- log / status / runner ----------
function Log($m, $k = 'info') {
    $c = switch ($k) {
        'ok' { $Clr.ok }
        'warn' { $Clr.warn }
        'err' { $Clr.red }
        'run' { [Drawing.Color]::White }
        default { $Clr.txt }
    }
    $rtb.SelectionStart = $rtb.TextLength; $rtb.SelectionColor = $Clr.dim; $rtb.AppendText("[$(Get-Date -Format 'HH:mm:ss')] ")
    $rtb.SelectionColor = $c; $rtb.AppendText("$m`n"); $rtb.ScrollToCaret()
    [Windows.Forms.Application]::DoEvents()
}
function Set-Status($s) {
    $lblStatus.Text = "$($script:dot) STATUS: $s"
    $lblStatus.ForeColor = if ($s -eq 'ONLINE') { $Clr.red } else { $Clr.warn }
    $form.UseWaitCursor = ($s -ne 'ONLINE')
    if ($s -eq 'ONLINE') { $anim.Stop(); $scan.Invalidate() } else { $anim.Start() }
    [Windows.Forms.Application]::DoEvents()
}
function Invoke-Feature($k) {
    if ($script:busy -or -not $Run.ContainsKey($k)) { return }
    $script:busy = $true; Set-Status 'BUSY'
    Log "> $($Names[$k])" 'run'
    $ok = $true
    try { $sb = $Run[$k]; & $sb } catch { $ok = $false; Log "ERROR: $($_.Exception.Message)" 'err' }
    if ($k -eq 'restore') { foreach ($r in $Rows.Values) { $r.acc.BackColor = $Clr.red; $r.btn.Text = $r.first } }
    elseif ($Rows.ContainsKey($k)) { $Rows[$k].acc.BackColor = $(if ($ok) { $Clr.ok } else { $Clr.warn }); $Rows[$k].btn.Text = $Rows[$k].again }
    $script:busy = $false; Set-Status 'ONLINE'
}
function Run-All {
    if ($script:busy) { return }
    $ks = 'clean', 'game', 'gpu', 'input', 'net', 'dns', 'ram'; $i = 0
    foreach ($k in $ks) { $i++; $btnAll.Text = "RUNNING  $i / $($ks.Count)"; Invoke-Feature $k }
    $btnAll.Text = 'ACTIVATE ALL'; Log '== ALL DONE ==' 'ok'
}

# ---------- features ----------
$Run = @{}
$Run.clean = {
    $dirs = [ordered]@{
        'User temp' = $env:TEMP
        'Windows temp' = "$env:WINDIR\Temp"
        'Crash dumps' = "$env:LOCALAPPDATA\CrashDumps"
        'Minidump' = "$env:WINDIR\Minidump"
        'Error reports' = "$env:PROGRAMDATA\Microsoft\Windows\WER\ReportQueue"
        'Web cache' = "$env:LOCALAPPDATA\Microsoft\Windows\INetCache"
        'Chrome cache' = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
        'Chrome code' = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache"
        'Edge cache' = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
        'Edge code' = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"
        'Discord cache' = "$env:APPDATA\discord\Cache"
        'Roblox logs' = "$env:LOCALAPPDATA\Roblox\logs"
        'BlueStacks logs' = "$env:PROGRAMDATA\BlueStacks_nxt\Logs"
    }
    $tot = 0
    foreach ($e in $dirs.GetEnumerator()) {
        $n = Clean-Dir $e.Value; $tot += $n
        if ($n -gt 100KB) { Log ('{0,-16}{1,9:N1} MB' -f $e.Key, ($n / 1MB)) }
    }
    $wu = (Get-Service wuauserv -EA SilentlyContinue).Status -eq 'Running'
    Stop-Service wuauserv, bits -Force -EA SilentlyContinue
    $n = Clean-Dir "$env:WINDIR\SoftwareDistribution\Download"; $tot += $n
    if ($n -gt 100KB) { Log ('{0,-16}{1,9:N1} MB' -f 'WinUpdate cache', ($n / 1MB)) }
    if ($wu) { Start-Service wuauserv, bits -EA SilentlyContinue }
    Clear-RecycleBin -Force -EA SilentlyContinue; Log 'Recycle Bin emptied'
    $free = (Get-PSDrive ($env:SystemDrive.Substring(0, 1))).Free / 1GB
    Log ('TOTAL freed {0:N1} MB | free {1:N1} GB' -f ($tot / 1MB), $free) 'ok'
}
$Run.ram = {
    $m = [MX]::Mem(); $u0 = ($m[0] - $m[1]) / 1GB
    $n = [MX]::Trim([string[]]($GameList + 'Idle' + 'System'))
    $ok = [MX]::Purge(); Start-Sleep -Milliseconds 700
    $m = [MX]::Mem(); $u1 = ($m[0] - $m[1]) / 1GB
    Log "Trimmed $n processes (games skipped)" 'ok'
    Log ('Standby list purge: ' + $(if ($ok) { 'OK' } else { 'denied' })) $(if ($ok) { 'ok' } else { 'warn' })
    Log ('RAM in use: {0:N2} GB -> {1:N2} GB' -f $u0, $u1) 'ok'
}
$Run.game = {
    $cur = [regex]::Match("$(powercfg /getactivescheme)", $GuidRx).Value
    $g = Get-MxPlan
    if ($cur -and $cur -ne $g) { SetReg 'HKCU:\Software\MARSHAL-IX9' 'OrigPlan' $cur 'String' }
    foreach ($s in 'PROCTHROTTLEMIN 100', 'PROCTHROTTLEMAX 100', 'CPMINCORES 100', 'PERFBOOSTMODE 2', 'PERFEPP 0') {
        $a = $s.Split(' '); PCfg /setacvalueindex $g SUB_PROCESSOR $a[0] $a[1]
    }
    PCfg /setacvalueindex $g 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    PCfg /setactive $g
    Log 'Power plan: MAX (AC), boost aggressive, no core parking' 'ok'
    Tw 'game'; Log 'Game Mode ON, Game DVR OFF, power throttling OFF' 'ok'
    foreach ($sv in 'DiagTrack', 'dmwappushservice') {
        try { Set-Service $sv -StartupType Disabled -EA Stop; Stop-Service $sv -Force -EA SilentlyContinue } catch {}
    }
    Log 'Telemetry services OFF' 'ok'
    $k = 0
    foreach ($n in $KillList) { foreach ($p in @(Get-Process -Name $n -EA SilentlyContinue)) { try { $p.Kill(); $k++ } catch {} } }
    Log "Closed $k background apps" 'ok'
    if (-not (Boost-Games)) { Log 'No game running. Start it, or enable AUTO-BOOST' 'warn' }
}
$Run.gpu = {
    Tw 'gpu'
    Log 'HW GPU scheduling ON (restart needed)' 'ok'
    Log 'Transparency + animations OFF (sign out to apply)' 'ok'
    Log 'Tip iGPU: lower in-game graphics = biggest gain' 'info'
}
$Run.input = {
    [MX]::Accel($false); Log 'Mouse acceleration OFF (live)' 'ok'
    Tw 'input'; [MX]::Keys(0)
    Log 'Key repeat: shortest delay, fastest rate' 'ok'
    Log 'Sticky/Filter keys popup OFF (after sign-out)' 'ok'
    PCfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
    PCfg /setactive SCHEME_CURRENT; Log 'USB selective suspend OFF (AC)' 'ok'
}
$Run.net = {
    netsh int tcp set global autotuninglevel=normal | Out-Null
    netsh int tcp set global ecncapability=disabled | Out-Null
    netsh int tcp set global rss=enabled | Out-Null
    netsh int tcp set global timestamps=disabled | Out-Null
    Log 'TCP: autotuning normal, ECN off, RSS on' 'ok'
    Tw 'net'; Log 'Network throttling OFF' 'ok'
    $n = 0
    foreach ($a in @(Get-NetAdapter -Physical -EA SilentlyContinue | Where-Object Status -eq 'Up')) {
        $k = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($a.InterfaceGuid)"
        SetReg $k 'TcpAckFrequency' 1; SetReg $k 'TCPNoDelay' 1; $n++
    }
    Log "Nagle disabled on $n adapter(s)" 'ok'
}
$Run.dns = {
    ipconfig /flushdns | Out-Null; Log 'DNS cache flushed' 'ok'
    $r = @()
    foreach ($i in 1..4) { try { $x = $script:png.Send($PingHost, 1500); if ($x.Status -eq 'Success') { $r += $x.RoundtripTime } } catch {} }
    if ($r.Count) { Log ("Ping $PingHost : {0} ms avg" -f [int]($r | Measure-Object -Average).Average) 'ok' } else { Log 'Ping failed - check internet' 'warn' }
}
$Run.debloat = {
    $n = 0
    foreach ($a in $BloatApps) {
        foreach ($p in @(Get-AppxPackage -Name $a -EA SilentlyContinue)) {
            try { Remove-AppxPackage -Package $p.PackageFullName -EA Stop; $n++; Log "Removed $($p.Name)" } catch { Log "Kept (protected): $($p.Name)" 'warn' }
        }
    }
    Log "Junk apps removed: $n" 'ok'
    Tw 'debloat'; Log 'Ads, suggestions, Copilot, Widgets, Bing search OFF' 'ok'
    foreach ($t in $Tasks) { try { [void](Disable-ScheduledTask -TaskPath $t[0] -TaskName $t[1] -EA Stop) } catch {} }
    Log 'Telemetry tasks + activity history OFF' 'ok'
    Log 'Restarting Explorer to apply...'
    Stop-Process -Name explorer -Force -EA SilentlyContinue
    Log 'Removed apps can be reinstalled from Microsoft Store' 'info'
}
$Run.startup = {
    $items = @(Get-Startup)
    if (-not $items.Count) { Log 'No startup entries found' 'warn'; return }
    $d = New-Object Windows.Forms.Form; $script:dlg = $d
    $d.FormBorderStyle = 'None'; $d.StartPosition = 'CenterParent'; $d.ShowInTaskbar = $false
    $d.AutoScaleDimensions = New-Object Drawing.SizeF(96, 96); $d.AutoScaleMode = 'Dpi'
    $d.ClientSize = New-Object Drawing.Size(520, 480); $d.BackColor = $Clr.panel
    $d.Add_Paint({ $_.Graphics.DrawRectangle($Pn.red, 0, 0, $this.Width - 1, $this.Height - 1) })
    $dh = Lbl 1 1 518 34 'STARTUP MANAGER' $d $Fnt.head $Clr.red 'MiddleCenter'; $dh.BackColor = $Clr.hdr
    $dh.Add_MouseDown({ if ($_.Button -eq 'Left') { [MX]::Drag($script:dlg.Handle) } })
    [void](Lbl 14 42 492 36 'Tick the apps, then press DISABLE. Only disable what you recognize (OneDrive, Teams, Spotify, updaters). Takes effect on next boot.' $d $Fnt.small $Clr.dim 'TopLeft')
    $script:lv = Ctl 'ListView' 14 84 492 336 '' $d $Fnt.body $Clr.txt
    $script:lv.View = 'Details'; $script:lv.HeaderStyle = 'None'; $script:lv.CheckBoxes = $true; $script:lv.FullRowSelect = $true
    $script:lv.BackColor = Col '#060103'; $script:lv.BorderStyle = 'None'
    [void]$script:lv.Columns.Add('', 460)
    foreach ($e in $items) {
        $li = New-Object Windows.Forms.ListViewItem(('[{0}] {1}' -f $(if ($e.On) { 'ON ' } else { 'OFF' }), $e.Name))
        $li.Tag = $e; $li.ForeColor = if ($e.On) { $Clr.txt } else { $Clr.dim }
        [void]$script:lv.Items.Add($li)
    }
    $d.Add_Shown({ $script:lv.Columns[0].Width = $script:lv.ClientSize.Width - 6 })
    $b1 = Btn 14 430 190 38 'DISABLE CHECKED' $d $null
    $b2 = Btn 214 430 160 38 'ENABLE CHECKED' $d $null
    $b3 = Btn 384 430 122 38 'CLOSE' $d $null
    $b1.Add_Click({ Apply-Startup $false }); $b2.Add_Click({ Apply-Startup $true }); $b3.Add_Click({ $script:dlg.Close() })
    [void]$d.ShowDialog($form)
}
$Run.restore = {
    foreach ($g in 'game', 'gpu', 'input', 'net', 'debloat') { Tw $g $true }
    foreach ($t in $Tasks) { try { [void](Enable-ScheduledTask -TaskPath $t[0] -TaskName $t[1] -EA Stop) } catch {} }
    [MX]::Accel($true); [MX]::Keys(1)
    foreach ($k in @(Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -EA SilentlyContinue)) {
        foreach ($n in 'TcpAckFrequency', 'TCPNoDelay') { Remove-ItemProperty -Path $k.PSPath -Name $n -EA SilentlyContinue }
    }
    try { Set-Service DiagTrack -StartupType Automatic -EA Stop; Start-Service DiagTrack -EA SilentlyContinue } catch {}
    try { Set-Service dmwappushservice -StartupType Manual -EA Stop } catch {}
    $o = (Get-ItemProperty 'HKCU:\Software\MARSHAL-IX9' -EA SilentlyContinue).OrigPlan
    if (-not $o) { $o = '381b4222-f694-41f0-9685-ff5bb260df2e' }
    $mx = Find-Plan; PCfg /setactive $o; if ($mx) { PCfg /delete $mx }
    Log 'Mouse, keys, power plan, services and tweaks reverted' 'ok'
    Log 'Sign out / restart to finish restoring' 'warn'
}

# ---------- timers & events ----------
$anim = New-Object Windows.Forms.Timer; $anim.Interval = 25
$anim.Add_Tick({ $scan.Tag = ([int]$scan.Tag + 20) % ($scan.Width + 200); $scan.Invalidate() })

$rainT = New-Object Windows.Forms.Timer; $rainT.Interval = 55
$rainT.Add_Tick({
    $w = $login.Width; $h = $login.Height
    if (-not $script:rain) {
        $script:rain = New-Object Drawing.Bitmap($w, $h)
        $g0 = [Drawing.Graphics]::FromImage($script:rain); $g0.Clear((Col '#030102')); $g0.Dispose()
        $sc = $w / $FW
        $script:rf = New-Object Drawing.Font('Consolas', (10 * $sc), [Drawing.FontStyle]::Bold)
        $script:cw = [int](15 * $sc); $script:ch = [int](17 * $sc)
        $n = [int]($w / $script:cw); $script:drops = [int[]]::new($n); $script:rnd = New-Object Random
        for ($i = 0; $i -lt $n; $i++) { $script:drops[$i] = 0 - $script:rnd.Next(0, 40) }
    }
    $g = [Drawing.Graphics]::FromImage($script:rain); $g.TextRenderingHint = 'AntiAlias'
    $g.FillRectangle($Br.fade, 0, 0, $w, $h)
    for ($i = 0; $i -lt $script:drops.Length; $i++) {
        $yy = $script:drops[$i] * $script:ch
        if ($yy -ge 0) { $g.DrawString([string]$RainChars[$script:rnd.Next($RainChars.Length)], $script:rf, $Br.head, ($i * $script:cw), $yy) }
        if ($yy -gt $h -and $script:rnd.NextDouble() -gt 0.97) { $script:drops[$i] = 0 } else { $script:drops[$i]++ }
    }
    $g.Dispose(); $login.Invalidate()
})

$tick = New-Object Windows.Forms.Timer; $tick.Interval = 1000
$tick.Add_Tick({
    $cpu = [MX]::Cpu(); $m = [MX]::Mem(); $used = $m[0] - $m[1]; $pct = [int](100 * $used / $m[0])
    $lblCpu.Text = "CPU  $cpu %"; $barCpu.Tag = $cpu; $barCpu.Invalidate()
    $lblRam.Text = ('RAM  {0:N1} / {1:N1} GB' -f ($used / 1GB), ($m[0] / 1GB)); $barRam.Tag = $pct; $barRam.Invalidate()
    $script:hc.Add($cpu); $script:hr.Add($pct)
    if ($script:hc.Count -gt 60) { $script:hc.RemoveAt(0); $script:hr.RemoveAt(0) }
    $graph.Invalidate()
    $ts = (Get-Date) - $script:boot
    $lblUser.Text = ('USER: {0}  |  UPTIME: {1}d {2:00}h {3:00}m {4:00}s' -f $env:USERNAME, $ts.Days, $ts.Hours, $ts.Minutes, $ts.Seconds)
    $script:pulse = -not $script:pulse
    if (-not $script:busy) { $lblStatus.ForeColor = if ($script:pulse) { $Clr.red } else { $Clr.dim } }
    if ($script:pingTask -and $script:pingTask.IsCompleted) {
        try {
            $rp = $script:pingTask.Result
            if ($rp.Status -eq 'Success') {
                $ms = [int]$rp.RoundtripTime; $lblPing.Text = "PING  $ms ms"
                $lblPing.ForeColor = if ($ms -lt 60) { $Clr.ok } elseif ($ms -lt 120) { $Clr.warn } else { $Clr.red }
            } else { $lblPing.Text = 'PING  --'; $lblPing.ForeColor = $Clr.dim }
        } catch { $lblPing.Text = 'PING  --'; $lblPing.ForeColor = $Clr.dim }
        $script:pingTask = $null
    }
    $script:tn++
    if (-not $script:pingTask -and ($script:tn % 3 -eq 0)) { try { $script:pingTask = $script:png.SendPingAsync($PingHost, 1000) } catch {} }
})

$boost = New-Object Windows.Forms.Timer; $boost.Interval = 4000
$boost.Add_Tick({
    if ($script:busy) { return }
    if (Test-Game) {
        if (-not $script:gameOn) {
            $script:gameOn = $true; Log 'GAME DETECTED - boosting' 'run'
            if (Get-Process -Name 'HD-Player' -EA SilentlyContinue) {
                $cr = [math]::Max(2, [math]::Min(4, [int]([Environment]::ProcessorCount / 2)))
                Log "Tip BlueStacks: $cr cores, 4GB RAM, 60FPS" 'info'
            }
            [void](Boost-Games); Invoke-Feature 'ram'
        } else { [void](Boost-Games) }
    } elseif ($script:gameOn) { $script:gameOn = $false; Log 'Game closed' }
})
$tgl.Add_CheckedChanged({
    $boost.Enabled = $this.Checked
    $this.Text = if ($this.Checked) { 'AUTO-BOOST : ON' } else { 'AUTO-BOOST : OFF' }
    Log ('Auto-boost ' + $(if ($this.Checked) { 'ON - watching for games' } else { 'off' }))
})
$btnRestore.Add_Click({ Invoke-Feature $this.Tag })
$btnAll.Add_Click({ Run-All })

function Start-App {
    $rainT.Stop()
    $cpu = try { (Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim() } catch { 'n/a' }
    $gpu = try { (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name } catch { 'n/a' }
    $os = try { (Get-CimInstance Win32_OperatingSystem).Caption } catch { 'Windows' }
    $script:boot = try { (Get-CimInstance Win32_OperatingSystem).LastBootUpTime } catch { Get-Date }
    $lblInfo.Text = ("CPU : {0}`nGPU : {1}`nRAM : {2:N0} GB`nOS  : {3}" -f $cpu, $gpu, ([MX]::Mem()[0] / 1GB), $os)
    Log 'MARSHAL IX-9 PROJECT online' 'ok'
    Log 'Admin rights : OK' 'ok'
    Log "GPU : $gpu"
    Log 'Press APPLY per feature, or ACTIVATE ALL'
    [void][MX]::Cpu(); $tick.Start()
}
function Shake {
    $o = $form.Location
    foreach ($d in 14, -14, 10, -10, 6, -6, 0) { $form.Location = New-Object Drawing.Point(($o.X + $d), $o.Y); [Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 22 }
}
$btnLogin.Add_Click({
    if ($pw.Text -ceq $Password) {
        $form.AcceptButton = $null; $login.Visible = $false; $main.Visible = $true; Start-App
    } else {
        $script:tries++; $msg.ForeColor = $Clr.red; $msg.Text = "ACCESS DENIED   [$($script:tries)/5]"; $pw.Clear(); Shake
        if ($script:tries -ge 5) { $form.Close() }
    }
})
$form.Add_Shown({ $rainT.Start(); $pw.Focus() })
$form.Add_FormClosing({ $tick.Stop(); $boost.Stop(); $rainT.Stop(); $anim.Stop() })
[Windows.Forms.Application]::Run($form)
try { $script:mtx.ReleaseMutex() } catch {}
