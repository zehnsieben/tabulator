# Lizenzfreie Offline-Version: Task Plan

## Ziel

Die App soll als lizenzfreie, lokal laufende Version ausgeliefert werden. Alle bisherigen Pro-/Premium-Funktionen werden normale Produktfunktionen. Die App soll im normalen Betrieb keine Verbindung zum Internet, zu Update-Servern, Feedback-Endpunkten, Crash-Reporting-Diensten oder anderen Geräten aufbauen.

Diese Planung geht davon aus, dass die Lizenzierung als Produktentscheidung entfernt wird, nicht dass eine fremde Lizenzpruefung umgangen wird.

## Nicht-Ziele

- Keine neue Paywall, Trial-Logik oder Aktivierungslogik einfuehren.
- Keine Remote-Aktivierung, Remote-Validierung oder Remote-Deaktivierung behalten.
- Keine Hintergrund-Updates, Telemetrie, Crash-Uploads oder Feedback-POSTs behalten.
- Developer ID, Team ID, Bundle ID und Signatur-/Keychain-Invarianten nicht nebenbei aendern.
- Keine alten Lizenzdaten aktiv loeschen, wenn das fuer Nutzer einen Keychain-Prompt oder andere UX-Probleme verursachen kann.

## Gewuenschtes Verhalten

- Alle bisherigen Pro-Funktionen sind sofort verfuegbar.
- Pro-Badges, Upgrade-Prompts, Trial-Tage, Hard-Gates und Downgrades verschwinden aus UI und Runtime.
- Bestehende Pro-Praeferenzen bleiben erhalten und werden nicht mehr auf Free-Werte zurueckgesetzt.
- App-Start, normale Nutzung und App-Ende oeffnen keine Netzwerkverbindung.
- Online-orientierte UI-Flows werden entfernt oder durch lokale Alternativen ersetzt.
- Die gebaute App ist weiterhin eine normale macOS `.app`, kann nach `/Applications` gelegt werden und startet per Doppelklick.
- Tests koennen beweisen, dass Pro-Gates weg sind und keine Netzwerk-Clients automatisch starten.

## Bestehende App-Kompatibilitaet

- Das Xcode-Projekt erzeugt bereits `AltTab.app` als macOS Application Product.
- `ai/build.sh` baut die Debug-App nach `DerivedData/Build/Products/Debug/AltTab.app`.
- `scripts/build_app.sh` baut die Release-App und prueft das Binary unter `AltTab.app/Contents/MacOS/AltTab`.
- `src/util/MoveToApplicationsFolder.swift` enthaelt bereits eine lokale "Move to Applications folder"-Logik.
- `src/App.swift` ruft `MoveToApplicationsFolder.promptIfNeeded()` beim Start auf. Diese Kompatibilitaet muss beim Entfernen von Lizenz-, Update- und Telemetriecode erhalten bleiben.

## Aktuelle Hotspots

- Lizenzsystem: `src/pro/license/LicenseManager.swift`, `LicenseState.swift`, `LicenseAPI.swift`, `RemoteLicenseClient.swift`, `LicenseCookie.swift`, `Keychain.swift`, `MachineFingerprint.swift`, `Clock.swift`.
- Pro-Gates: `src/pro/ProFeature.swift`, `src/preferences/PreferenceDefinition.swift`, `src/events/PreferencesEvents.swift`, `src/preferences/settings-window/LabelAndControl.swift`, `ShortcutEditor.swift`, `ControlsTab.swift`, `AppearanceTab.swift`, `src/switcher/ShortcutAction.swift`, `src/switcher/main-window/TilesView.swift`.
- Pro-UIs: `src/preferences/settings-window/tabs/UpgradeTab.swift`, `src/pro/ui/*`, `src/pro/scheduling/*`, Menubar-Pro-Status.
- Netzwerk: `src/pro/license/RemoteLicenseClient.swift`, `src/secondary-windows/FeedbackWindow.swift`, Sparkle in `src/App.swift`/`src/vendors/SparkleDelegate.swift`, AppCenter in `src/vendors/AppCenterCrashes.swift` und `src/vendors/AppCenterApplication.*`.
- Konfiguration/Projekt: `src/api/Endpoints.swift`, `src/api/Secrets.swift`, `Info.plist`, `appcast.xml`, `alt-tab-macos.xcodeproj/project.pbxproj`, `vendor/Sparkle`, `vendor/AppCenter`, Release-Skripte.

## Umsetzung

### 1. Feature-Modell von Lizenzierung entkoppeln

- `ProFeature` in ein normales Feature-Register oder eine reine Copy-/Preference-Hilfe umwandeln.
- `ProFeature.isAvailable` immer als verfuegbar behandeln oder die Abfrage komplett entfernen.
- `ProFeature.isLocked` und `attemptUse()` entfernen oder zu no-op/true migrieren.
- Alle Call-Sites entfernen, die bei gesperrten Features zu `UpgradeTab.navigateToUpgradeTab()` springen.
- Specs/Tests fuer Search, Lock Search, Extra Shortcuts, Auto Size und Appearance Styles aktualisieren.

### 2. Lizenzmanager und Remote-Lizenz-API entfernen

- `LicenseManager.shared.initialize()`, `activate`, `deactivate`, `validate`, `revalidateWithServer` und alle State-Change-Hooks aus dem App-Start entfernen.
- `RemoteLicenseClient`, `LicenseAPI`, `LicenseState`, `LicenseCookie`, `MachineFingerprint` und lizenzspezifische Tests/Specs aus dem Build nehmen.
- Keychain-Zugriffe nur entfernen, wenn sie ausschliesslich fuer Lizenzdaten genutzt werden.
- `QAMenu`-Aktionen fuer Pro-Mocking, Revalidation und Lizenz-Keychain-Cleanup entfernen.
- URL-Handling fuer automatische Lizenzaktivierung aus `App.swift` entfernen.

### 3. Pro-Transition und Upgrade-UI entfernen

- `ProTransitionManager`, `ProTransitionScheduler`, `ProTransitionState`, Day-X-Fenster/Popover und `ProPromptHost` aus dem App-Start und dem Build entfernen.
- Upgrade-Tab aus der Settings-Sidebar entfernen oder in eine lokale Support-/About-Seite ohne Netzwerkaktion umwandeln.
- Menubar-Status fuer Trial/Pro/Expired entfernen.
- Pro-Badges und Pro-spezifische Conversion-Copy aus Settings und Prompt-Flows entfernen.
- Persistierte `remembered*` Pro-Downgrade-Werte nicht mehr fuer Runtime-Entscheidungen verwenden.

### 4. Praeferenz-Migration fuer ehemals Pro-gated Settings

- Beim ersten Start nach der Umstellung keine Pro-Werte degradieren.
- Falls Nutzer durch fruehere Versionen auf Free-Werte zurueckgesetzt wurden und `remembered*` Werte existieren, diese einmalig wiederherstellen.
- Danach alte `proTransition.*`, Trial- und Lizenz-Defaults passiv ignorieren oder in einer sicheren Migration entfernen.
- Specs fuer Preference-Migrationen ergaenzen.

### 5. Sparkle-Updates vollstaendig deaktivieren oder entfernen

- `SPUStandardUpdaterController`-Initialisierung und `startUpdater()` aus `App.swift` entfernen.
- Update-Policy-Preferences und Sparkle-Wiring aus `PreferencesEvents`, `UserDefaultsEvents` und `GeneralTab` entfernen.
- `SparkleDelegate.swift`, Sparkle Framework-Referenzen und den `Copy Sparkle Helpers` Build Phase aus dem Xcode-Projekt entfernen, wenn keine manuellen Offline-Updatepakete gebraucht werden.
- `appcast.xml` und updatebezogene Release-Skripte als nicht mehr produktrelevant markieren oder entfernen.

### 6. AppCenter und Crash-Upload entfernen

- `App` von `AppCenterApplication` auf die normale App-Basisklasse migrieren.
- `AppCenterCrash`-Initialisierung aus `App.swift` entfernen.
- `src/vendors/AppCenterApplication.*`, `AppCenterCrashes.swift`, AppCenter Framework-Referenzen und `AppCenterSecret` aus `Info.plist` entfernen.
- Lokale Crash-Hinweise koennen bleiben, duerfen aber nichts hochladen.

### 7. Feedback-Flow offline machen

- `FeedbackWindow` darf keinen Update-Preflight und keinen `URLSession.shared.dataTask` mehr ausloesen.
- Feedback-UI entweder entfernen, als lokale Diagnose-Export-Funktion umsetzen, oder einen lokal erzeugten Bericht anzeigen, den Nutzer selbst weitergeben koennen.
- Entsprechend `Endpoints.feedbackUrl` und zugehoerige Secrets/Strings entfernen.

### 8. Netzwerk-Endpunkte und Transports auditieren

- `Endpoints.licenseApiBaseUrl`, `Endpoints.feedbackUrl` und nicht mehr benoetigte Remote-Konstanten entfernen.
- Statische Suche nach `URLSession`, `http://`, `https://`, `NWConnection`, `NWBrowser`, `Bonjour`, `MultipeerConnectivity`, `socket`, Sparkle und AppCenter durchfuehren.
- Fuer verbleibende Treffer dokumentieren, ob sie nur Doku/Release-Skripte sind oder Runtime-Code.
- Keine neue Netzwerk-Abstraktion einfuehren, wenn das Produkt komplett offline bleiben soll.

### 9. Projektdateien bereinigen

- Entfernte Swift-/ObjC-Dateien aus `alt-tab-macos.xcodeproj/project.pbxproj` nehmen.
- Nicht mehr benoetigte lokale Packages `vendor/Sparkle` und `vendor/AppCenter` aus Package-Referenzen entfernen.
- Build Phases, Frameworks, Embed-Frameworks und Script-Phases bereinigen.
- Lokalisierungsstrings fuer Pro, Trial, Upgrade, License, Update und Feedback entfernen oder umformulieren.

### 10. App-Bundle und Applications-Installation erhalten

- Sicherstellen, dass `AltTab.app` nach der Bereinigung weiterhin als `com.apple.product-type.application` gebaut wird.
- `CFBundleExecutable`, `CFBundleIdentifier`, Icon, Kategorie, Entitlements und Login-Item-Verhalten unveraendert lassen, sofern kein separater Migrationsgrund existiert.
- `MoveToApplicationsFolder.promptIfNeeded()` behalten oder durch eine gleichwertige lokale Installationshilfe ersetzen.
- Keine Update-, Lizenz- oder Telemetrie-Abhaengigkeit in den ersten Doppelklick-Start aus `/Applications` einbauen.
- Verifizieren, dass die App aus `DerivedData/Build/Products/Debug/AltTab.app` per Finder-Doppelklick startet.
- Verifizieren, dass die App nach dem Kopieren nach `/Applications/AltTab.app` per Doppelklick startet.
- Falls ein Release-Artefakt erzeugt wird, dokumentieren, wo die fertige `.app` liegt und ob sie manuell nach `/Applications` kopiert werden kann.

### 11. Tests und Specs aktualisieren

- Alte Lizenz-/ProTransition-Tests entfernen oder durch Migrations-/Regressionstests ersetzen.
- Specs fuer ehemals gated Features aktualisieren: die Features sind jetzt normale Funktionen.
- Tests fuer Settings-Interaktionen ergaenzen: Pro-Optionen sind klickbar und navigieren nicht zur Upgrade-Seite.
- Tests fuer Switcher-Aktionen ergaenzen: Search, Lock Search und Extra Shortcuts funktionieren ohne Lizenzstatus.
- Test oder Audit-Skript ergaenzen, das Runtime-Netzwerk-Hotspots im Source erkennt.

### 12. Verifikation

- Befehle aus `ai/build.sh` ausfuehren.
- Relevante Unit-Tests fuer Settings, Preferences, Switcher und Migrationen ausfuehren.
- `rg -n "URLSession|SPUStandardUpdaterController|AppCenter|RemoteLicenseClient|LicenseManager|UpgradeTab|isProLocked|isProAvailable|https?://"` auswerten.
- `file DerivedData/Build/Products/Debug/AltTab.app/Contents/MacOS/AltTab` pruefen.
- `open DerivedData/Build/Products/Debug/AltTab.app` lokal testen; fuer finale Verifikation die `.app` nach `/Applications` kopieren und per Doppelklick starten.
- App starten und mit einem lokalen Netzwerkmonitor oder macOS-Firewallprofil pruefen, dass beim Start und bei normaler Nutzung keine ausgehenden Verbindungen entstehen.

## Reihenfolge

1. Erst Pro-Gates auf no-op stellen und Tests fuer frei verfuegbare Features stabilisieren.
2. Danach ProTransition-/Upgrade-UI entfernen.
3. Danach Lizenzmanager und Remote-Lizenz-API aus dem Build nehmen.
4. Danach Sparkle, AppCenter und Feedback-POST entfernen.
5. Danach bestaetigen, dass `AltTab.app` weiter als normale macOS-App startet und nach `/Applications` gelegt werden kann.
6. Zum Schluss Projektdatei, Lokalisierung, Docs und Release-Skripte bereinigen.

## Offene Entscheidungen

- Soll die Upgrade-Seite komplett verschwinden oder zu einer lokalen Support-/Donation-Seite werden?
- Soll Feedback komplett entfernt oder als lokaler Diagnose-Export behalten werden?
- Sollen alte Lizenz-Keychain-Eintraege unangetastet bleiben oder per expliziter Nutzeraktion entfernt werden?
- Sollen Sparkle/AppCenter-Vendor-Verzeichnisse sofort geloescht oder nur aus dem Build genommen werden?
