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

Dieses Projekt dient **nur Demonstrations- und Lerneffekten**.  
Es zeigt, wie Automatisierung und Skripting mit PowerShell umgesetzt werden können, und welche **Sicherheitsaspekte** bei Web-Applikationen (z. B. fehlendes HTTPS, kein CSRF-Schutz) relevant sind.
