# WorkTimeAutomation

# Autopilot

Ein Automatisierungs-Skript (ursprünglich in PowerShell, später auch portierbar nach Linux/Python), das wiederkehrende Aktionen in einem webbasierten Zeiterfassungssystem automatisch durchführt.

## Funktionsumfang

- **Automatischer Login** ins Kurssystem beim Systemstart
- **Zeitgesteuerte Aktionen**:
  - 10:15 Uhr → Pause (sofortige Abmeldung nach 45s)
  - 12:15 Uhr → Pause (sofortige Abmeldung nach 45s)
  - 14:15 Uhr → Pause (sofortige Abmeldung nach 45s)
  - 16:15 Uhr → Logout + optionaler Shutdown des Rechners
- **Random Delay (1–30 Sekunden)** vor jeder Aktion, um ein menschlicheres Muster zu simulieren
- **Logging** aller Aktionen in einer Logdatei (`...-autopilot.log`)
- **Abbruch-Mechanismus** über eine Datei (`ABBRUCH.txt`), um den Shutdown zu verhindern
- **Tarnung des User-Agents** (Chrome), damit Requests im Server-Log wie normale Browser-Aufrufe wirken

## Technik

- Implementiert in **PowerShell 5.1** (Windows), mit Unterstützung für Session-Cookies via `Invoke-WebRequest`
- Shutdown via `Stop-Computer` oder Fallback `shutdown.exe`
- Konfigurierbare Parameter:
  - Benutzername & Passwort
  - Zeitpunkte für Pausen/Logout
  - Länge des Pause-Intervalls
  - Abbruchdatei, Shutdown-Modus (hart/weich)
- Modular aufgebaut → einfache Portierung nach **Linux (Bash/Python)** möglich

## Sicherheitshinweise

- Passwörter werden aktuell im Skript im Klartext hinterlegt → für Produktionsbetrieb unsicher  
- Kommunikation erfolgt per **HTTP** (kein HTTPS), daher sind Sessions und Passwörter abfangbar  
- Keine zusätzliche Integritätsprüfung der Serverantworten implementiert  
- Projekt entstand **im Rahmen einer Umschulung/Projektarbeit** und dient **Lernzwecken**.  

## Ausblick / Geplante Erweiterungen

- Portierung nach **Python** mit `requests` und `schedule`
- Verwendung verschlüsselter Credentials (Windows Credential Manager oder Keyring)
- Config-Datei (JSON/YAML) statt Hardcoding
- Unterstützung für Linux-Systeme (z. B. via `systemd` oder Cron)
- Erweiterte Logik für Ausnahmedateien (z. B. Pausen überspringen)

## Hinweis

⚠️  Dieses Projekt dient **nur Demonstrations- und Lerneffekten**.  
Es zeigt, wie Automatisierung und Skripting mit PowerShell umgesetzt werden können, und welche **Sicherheitsaspekte** bei Web-Applikationen (z. B. fehlendes HTTPS, kein CSRF-Schutz) relevant sind.

===============================================================================================================================================================================================================

# Autopilot

A learning project developed during a retraining program, written in PowerShell.  
The script automates recurring actions in a web-based time tracking system (Kursverwaltung).

## Features

- Automatic **login** on system startup (with retry logic if the network is not yet available)
- Scheduled **break check-ins and immediate check-outs** at predefined times (10:15, 12:15, 14:15)
- **Logout** and optional **system shutdown** at 16:15
- **Randomized delays** before actions (1–30 seconds) to mimic human behavior
- **Logging** to file with timestamps
- **Abort mechanism**: if a special file exists, the shutdown will be canceled
- **User-Agent spoofing** to appear as a Chrome browser in server logs

## Technical Details

- Implemented in **PowerShell 5.1/7+**
- Uses `Invoke-WebRequest` with session cookies for authentication
- Random delays and daily schedule handled via PowerShell loops
- Local log file (`...-autopilot.log`) for transparency
- Shutdown via `Stop-Computer` or fallback to `shutdown.exe`

## Security Considerations

⚠️ This project is for **educational purposes only**.  
It demonstrates automation, scheduling, and HTTP interaction with a legacy web system.

Known limitations:
- **Plaintext credentials** in the script (insecure for production)
- **HTTP only** – credentials and cookies are sent unencrypted
- No CSRF protection or additional security checks on the server side
- Logs grow indefinitely unless rotated
- Running with elevated rights for shutdown introduces risks

## Planned Improvements

- Porting to **Python** for better cross-platform support (Linux, macOS)
- Using a **configuration file** for schedules and credentials
- Encrypted credential storage (e.g., DPAPI, Credential Manager)
- Improved logging with rotation
- Linux version using `curl`/`requests` and `systemd` timers
- Optional GUI for configuration

---

### Disclaimer
⚠️ This repository is part of a **training and learning exercise**.  
It is **not meant for production use**. Any resemblance to real systems is coincidental.
