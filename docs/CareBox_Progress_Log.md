# CareBox — Progress Log

> Last updated: 2026-10-26

---

## ✅ Completed

### Project Planning
- [x] Received and analyzed client spec (in French) from Klein
- [x] Defined hardware architecture: ESP32 + SIM800L + DS3231 + SSD1306 + buzzer + LEDs + button
- [x] Decided on modular compartment design (main housing + clip-on compartment modules with JST connectors)
- [x] Defined alarm state machine: IDLE → ALERTING → CONFIRMED / MISSED
- [x] Created `CareBox_Architecture_Plan.md`
- [x] **Architecture decision: WiFi AP Mode → REST HTTP API** (switched from Bluetooth Classic SPP)
  - Reason: `flutter_bluetooth_serial` has AGP 9+ / jcenter() Gradle incompatibility
  - WiFi AP is simpler to implement end-to-end, works anywhere, no pairing needed
  - Upgrade path to home WiFi is minimal (only WiFi init code changes)

### Flutter App — Scaffolding
- [x] Flutter project created at `carebox/`
- [x] All 6 screens created with Samsung One UI styling
- [x] `lib/models/medication.dart` — Medication class with toJson/fromJson/toCommand
- [x] `lib/models/dose_log.dart` — DoseLog class
- [x] `lib/providers/medication_provider.dart` — state management, SharedPreferences persistence
- [x] `main.dart` wired with MultiProvider, all screens connected to provider

### UI Design
- [x] 6 screens designed in Stitch AI
- [x] Samsung One UI style: #F1F3F5 bg, #FFFFFF cards, #1259C3 blue, Outfit font
- [x] Downloaded HTML exports via Stitch MCP, converted to Flutter Dart files

### Verification
- [x] `flutter analyze` — no issues
- [x] `flutter test` — all tests passed
- [x] `flutter run` on Chrome — UI renders (web only)
- [x] Attempted Android build — failed due to `flutter_bluetooth_serial` Gradle incompatibility → decided to drop BT entirely

---

## 🔄 In Progress

### ESP32 Firmware — Phase 1 debug (firmware chat)
- [x] **POST /medications returns 400** — Root cause resolved on app side: JSON payload was serializing time as `timeHour`/`timeMinute`, while ESP32 parser expects `hour`/`minute`. Updated `Medication.toJson()` and `fromJson()` to support `hour` and `minute` with backward compatibility, and made `DoseLog.fromJson()` resilient to partial log responses. Unit tests verified.

---

## ✅ Completed (continued)

### Flutter — Bug fixes & Performance ✅
- [x] **Navbar re-render:** Implemented `IndexedStack` in `MainScaffold` body so all tab screens remain mounted without flickering or rebuilding on tab switch.
- [x] **Payload alignment:** Synced `Medication` JSON schema with ESP32 REST API (`hour`, `minute`, `compartment` 1–4, 7-day array).

### Flutter — WiFi / HTTP migration ✅
- [x] Removed `flutter_bluetooth_serial` from pubspec.yaml
- [x] Added `http: ^1.2.0`, `provider`, `shared_preferences`, `google_fonts`
- [x] `lib/services/api_service.dart` — all HTTP calls to ESP32
- [x] `medication_provider.dart` updated to use ApiService
- [x] `wifi_connect_screen.dart` — two-step WiFi connect UI, calls GET /status to verify
- [x] All 6 screens wired to API (add, delete, mark taken, settings)
- [x] `kDebugMode` bypass button for testing without hardware
- [x] Navbar icons fixed (filled round icons, extracted from Stitch HTML exports)
- [x] App tested on Chrome + Android emulator

### ESP32 Firmware — Phase 1 (mostly working)
- [x] PlatformIO project created — `platform: espressif32`, board: `esp32-c3-devkitm-1`
- [x] `board_build.partitions = no_ota.csv` (prevents flash overflow when adding more libs)
- [x] WiFi AP: SSID `CareBox`, pass `carebox123`, IP `192.168.4.1`
- [x] WebServer on port 80 with all REST endpoints registered
- [x] ArduinoJson v6 for all serialization
- [x] GPIO8 LED debug: 3 blinks = boot, 6 blinks = AP started, solid = idle, blip = request
- [x] Firmware builds and flashes successfully
- [x] GET /status returns correct JSON ✅
- [x] WiFi connect screen in Flutter app connects successfully ✅
- [ ] POST /medications → 400 (under investigation)

---

## ⏳ Not Started

### ESP32 Firmware — Phase 2: NVS persistence
- [ ] `Preferences` library — save/load medications + caregiverPhone to flash
- [ ] Data survives power cycle

### ESP32 Firmware — Phase 3: DS3231 RTC
- [ ] Wire DS3231 on I2C (use GPIO6/GPIO7, NOT GPIO8/GPIO9 — GPIO8 is taken by LED)
- [ ] `rtc_manager` — read time, sync from POST /time
- [ ] GET /status returns real time/date
- [ ] `alarm_engine` — check schedule every second, fire on match

### ESP32 Firmware — Phase 4: Alarm state machine + peripherals
- [ ] State machine: IDLE → ALERTING → CONFIRMED / MISSED
- [ ] LEDs per compartment, buzzer pattern, debounced button, SSD1306 OLED

### ESP32 Firmware — Phase 5: SIM800L SMS
- [ ] AT command wrapper, sendSMS() on MISSED state

### Integration & Testing
- [ ] Full end-to-end app ↔ ESP32 test
- [ ] Demo prep

---

## Key Decisions Made

| Decision | Choice | Reason |
|---|---|---|
| Communication | WiFi AP Mode → REST HTTP | BT package Gradle issues; WiFi simpler, no pairing, works everywhere |
| Upgrade path | AP Mode first, home WiFi later | Only WiFi init changes; full API stays the same |
| ESP32 base URL | `http://192.168.4.1` | Fixed IP in AP mode, no discovery needed |
| HTTP package | `http: ^1.2.0` | Built-in Flutter package, zero compatibility issues |
| State management | provider | Lightweight, matches project scale |
| Font | Outfit (700/600/400) | Clean, modern, Samsung-like |
| Compartment ID | Numbers (1,2,3,4) | Client preference |
| Confirmation | Dual (app button + physical button) | Both call same /taken endpoint |

---

## Key Hardware Notes

- AP mode IP is always `192.168.4.1` — hardcoded in `api_service.dart`
- SIM800L peaks at 2A — needs 1000µF cap on VCC
- DS3231 coin cell keeps RTC running even when main battery is charging
- **GPIO8 = LED (active LOW) on ESP32-C3 Super Mini — also default I2C SDA in Arduino core**
  → For Phase 3, call `Wire.begin(6, 7)` to use GPIO6/GPIO7 for I2C instead
- Serial Monitor has USB CDC disconnect issues on Windows with ESP32-C3 — use LED blinks for debug
- PlatformIO shows as "pioarduino" branding — this is normal, it's the updated espressif32 platform
- Flash is ~76% used at Phase 1 — `no_ota.csv` partition gives ~2MB headroom for Phase 3-5 libs
