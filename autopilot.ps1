<# =======================
   Autopilot (mit Initial-Login)
   - Beim Start: einmaliger Login-Check (mit Retry)
   - Pausen: 10:15, 12:15, 14:15   (s=break)
   - Feierabend: 16:15             (s=logout + Shutdown)
   - Vor jeder Aktion: Random Sleep 1..30s
   - Endlosschleife für Autostart
   - Alle Requests tarnen sich als Chrome
   ======================= #>

# ===== Konfiguration =====
$Base        = "http://10.10.10.7:4555/damago/"
$LoginUrl    = $Base + "index.php?s=login"
$BreakUrl    = $Base + "index.php?s=break"
$LogoutUrl   = $Base + "index.php?s=logout"
$CheckUrl    = $Base + "index.php"        # für einfache Login-Prüfung

$User            = "Your USERNAME"
$PasswordPlain   = "YOUR PASWD"          # nur Testumgebung
$LogFile         = "C:\Scripts\damago-autopilot.log"

# Shutdown/Abbruch
$ShutdownCountdownSec = 6
$AbortFile            = "C:\Scripts\ABBRUCH.txt"  # falls vorhanden, kein Shutdown
$HardShutdown         = $true                      # $true erzwingt, $false sanft

# Initial-Login Retry-Logik (z. B. wenn WLAN/LAN noch nicht bereit)
$InitLoginMaxTries    = 5
$InitLoginDelaySec    = 10

# ===== Header für Tarnung (Chrome unter Windows 10) =====
$Headers = @{
    "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36"
}

# --- Setup Log-Ordner ---
$null = New-Item -ItemType Directory -Force -Path (Split-Path $LogFile) -ErrorAction SilentlyContinue

function Write-Log($msg) {
  $ts = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
  Add-Content -Path $LogFile -Value "[$ts] $msg"
}

function Do-Login([ref]$websess) {
  $body = @{ username = $User; password = $PasswordPlain; login = "1" }
  $respLogin = Invoke-WebRequest -Uri $LoginUrl -Method POST -Body $body -Headers $Headers -SessionVariable tmpSess -UseBasicParsing -TimeoutSec 20
  $websess.Value = $tmpSess
}

function Check-LoggedIn($websess) {
  try {
    $resp = Invoke-WebRequest -Uri $CheckUrl -WebSession $websess -Headers $Headers -UseBasicParsing -TimeoutSec 20
    return ($resp.Content -match "Kursverwaltung|Abmelden|Arbeitszeit|Break")
  } catch { return $false }
}

function Invoke-DamagoAction([ValidateSet("break","logout")]$Action) {
  try {
    # 1) Login + Session
    $sess = $null
    Write-Log "[${Action}] Login..."
    Do-Login ([ref]$sess)

    # 2) Aktion
    if ($Action -eq "break") {
      Write-Log "[break] GET $BreakUrl"
      $resp = Invoke-WebRequest -Uri $BreakUrl -WebSession $sess -Headers $Headers -UseBasicParsing -TimeoutSec 20
      Write-Log "[break] HTTP $($resp.StatusCode)"

      Start-Sleep -Seconds 45 # kurz in Pause bleiben

      Write-Log "[break] Pause Abmelden → GET $BreakUrl"
      $resp2 = Invoke-WebRequest -Uri $BreakUrl -WebSession $sess -Headers $Headers -UseBasicParsing -TimeoutSec 20
      Write-Log "[break] Zweite Antwort (Pause-Ende) HTTP $($resp2.StatusCode)"
      return
    }

    if ($Action -eq "logout") {
      Write-Log "[logout] GET $LogoutUrl"
      $resp = Invoke-WebRequest -Uri $LogoutUrl -WebSession $sess -Headers $Headers -UseBasicParsing -TimeoutSec 20
      Write-Log "[logout] HTTP $($resp.StatusCode)"

      # Shutdown mit Countdown + Abbruchoption
      if (Test-Path $AbortFile) {
        Write-Log "[logout] ABBRUCH-Datei vorhanden. Kein Shutdown."
        return
      }

      Write-Log "[logout] Shutdown in $ShutdownCountdownSec s … (ABBRUCH: $AbortFile)"
      try { msg * "PC fährt in $ShutdownCountdownSec s herunter. Erstelle $AbortFile, um abzubrechen." } catch {}
      Start-Sleep -Seconds $ShutdownCountdownSec

      if (Test-Path $AbortFile) {
        Write-Log "[logout] ABBRUCH-Datei nachträglich gefunden. Kein Shutdown."
        return
      }

      try {
        if ($HardShutdown) { Stop-Computer -Force } else { Stop-Computer }
      } catch {
        Write-Log "[logout] Stop-Computer fehlgeschlagen – Fallback shutdown.exe."
        $args = if ($HardShutdown) { "/s /f /t 0" } else { "/s /t 0" }
        Start-Process -FilePath "$env:SystemRoot\System32\shutdown.exe" -ArgumentList $args -WindowStyle Hidden
      }
      Write-Log "[logout] Shutdown ausgelöst."
      return
    }
  }
  catch {
    Write-Log "[${Action}] FEHLER: $($_.Exception.Message)"
  }
}

function Next-Schedule($now) {
  # Heutige Ziele in Reihenfolge
  $today = $now.Date
  $slots = @(
    @{ At = $today.AddHours(10).AddMinutes(15); Action = 'break'  }
    @{ At = $today.AddHours(12).AddMinutes(15); Action = 'break'  }
    @{ At = $today.AddHours(14).AddMinutes(15); Action = 'break'  }
    @{ At = $today.AddHours(16).AddMinutes(15); Action = 'logout' }
  )

  foreach ($s in $slots) {
    if ($now -lt $s.At) { return $s }
  }

  # Alle vorbei -> ersten Slot von morgen liefern
  $tomorrow = $today.AddDays(1)
  return @{ At = $tomorrow.AddHours(10).AddMinutes(15); Action = 'break' }
}

# ================== Initial-Login beim Start ==================
Write-Log "Autopilot gestartet. Führe Initial-Login aus."
for ($i = 1; $i -le $InitLoginMaxTries; $i++) {
  try {
    $sess = $null
    Do-Login ([ref]$sess)
    if (Check-LoggedIn $sess) {
      Write-Log "[init] Login bestätigt."
      break
    } else {
      Write-Log "[init] Login unklar (Versuch $i/$InitLoginMaxTries)."
    }
  } catch {
    Write-Log "[init] Fehler beim Login (Versuch $i/$InitLoginMaxTries): $($_.Exception.Message)"
  }
  if ($i -lt $InitLoginMaxTries) {
    Start-Sleep -Seconds $InitLoginDelaySec
  } else {
    Write-Log "[init] Gebe auf, fahre mit Zeitplan fort."
  }
}

# ================== Hauptschleife ==================
while ($true) {
  $now = Get-Date
  $next = Next-Schedule -now $now
  $waitSec = [math]::Ceiling(($next.At - (Get-Date)).TotalSeconds)
  if ($waitSec -gt 0) {
    Write-Log "Warte bis $($next.At.ToString('yyyy-MM-dd HH:mm:ss')) für Aktion [$($next.Action)] (${waitSec}s)."
    try { Start-Sleep -Seconds $waitSec } catch {}
  }

  # Vor Aktion: Random-Jitter 1..30 s
  $jitter = Get-Random -Minimum 1 -Maximum 31
  Write-Log "Vorbereitung [$($next.Action)]: Random Sleep ${jitter}s."
  Start-Sleep -Seconds $jitter

  # Falls Zielzeit stark überschritten (z. B. Standby), überspringen
  if ((Get-Date) -gt $next.At.AddMinutes(2)) {
    Write-Log "Zielzeit überschritten, Aktion [$($next.Action)] wird für heute übersprungen."
    continue
  }

  Invoke-DamagoAction -Action $next.Action
}
