# CareBox — Full Execution Plan

> Last updated: 2026-10-15
> Project: Smart medication reminder box for elderly patients (client: Klein)
> Stack: ESP32 firmware (Arduino) + Flutter Android app

---

## Project Overview

A standalone medication reminder device. The ESP32 runs autonomously — it stores a schedule, fires alarms (LED + buzzer + OLED) at the right times, waits for button confirmation, and sends an SMS via SIM800L if the dose is missed. A Flutter Android app communicates with the ESP32 over WiFi (AP mode) via a REST HTTP API to configure the schedule.

---

## Communication Architecture

### Phase 1 — WiFi AP Mode (current target)
ESP32 creates its own hotspot. Phone connects to it directly.
- ESP32 SSID: `CareBox`, Password: `carebox123`
- ESP32 IP: always `192.168.4.1` (fixed in AP mode)
- Flutter base URL: `http://192.168.4.1`
- No router, no internet, works anywhere (ideal for demo)

### Phase 2 — Home WiFi upgrade (future)
- ESP32: swap `WiFi.softAP()` → `WiFi.begin(ssid, pass)` + WiFiManager
- Flutter: swap hardcoded IP → `http://carebox.local` (mDNS) or user-entered IP in settings
- REST API, all screens, all firmware logic: **unchanged**

---

## REST API — Full Specification

Base URL: `http://192.168.4.1`
Content-Type: `application/json`
All responses include `"status": "ok"` or `"status": "error", "message": "..."`

### Endpoints

| Method | Endpoint | Description |
|---|---|---|
| GET | `/status` | Device status, next dose, current time |
| POST | `/time` | Sync RTC to phone time |
| GET | `/medications` | All scheduled medications |
| POST | `/medications` | Add a medication |
| DELETE | `/medications/{id}` | Delete by ID |
| POST | `/medications/{id}/taken` | Mark dose as taken (from app) |
| GET | `/logs` | Recent dose history (last 20) |
| POST | `/settings` | Update caregiver phone number |
| GET | `/settings` | Get current settings |

---

### Request / Response Schemas

**GET /status**
```json
{
  "status": "ok",
  "time": "08:30",
  "date": "15/10/2026",
  "alarmActive": false,
  "nextDose": {
    "id": "1728900000000",
    "name": "Paracetamol",
    "dose": "500mg",
    "time": "09:00",
    "compartment": 1
  }
}
```
`nextDose` is `null` if no upcoming dose today.

---

**POST /time**
```json
{ "timestamp": 1728900000 }
```
Response: `{ "status": "ok" }`

---

**GET /medications**
```json
{
  "status": "ok",
  "medications": [
    {
      "id": "1728900000000",
      "name": "Paracetamol",
      "dose": "500mg",
      "hour": 8,
      "minute": 30,
      "compartment": 1,
      "days": [true, true, true, true, true, false, false]
    }
  ]
}
```
`days` index: 0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri, 5=Sat, 6=Sun

---

**POST /medications**
```json
{
  "id": "1728900000000",
  "name": "Paracetamol",
  "dose": "500mg",
  "hour": 8,
  "minute": 30,
  "compartment": 1,
  "days": [true, true, true, true, true, false, false]
}
```
Response: `{ "status": "ok", "id": "1728900000000" }`

---

**DELETE /medications/{id}**
Response: `{ "status": "ok" }`

---

**POST /medications/{id}/taken**
Response: `{ "status": "ok" }`

---

**GET /logs**
```json
{
  "status": "ok",
  "logs": [
    {
      "medicationId": "1728900000000",
      "medicationName": "Paracetamol",
      "scheduledTime": "08:30",
      "date": "15/10/2026",
      "status": "taken",
      "confirmedAt": "08:32"
    }
  ]
}
```

---

**POST /settings**
```json
{ "caregiverPhone": "+213XXXXXXXXX" }
```
Response: `{ "status": "ok" }`

**GET /settings**
```json
{ "status": "ok", "caregiverPhone": "+213XXXXXXXXX" }
```

---

## Hardware

| Component | Role |
|---|---|
| ESP32 (38-pin) | Main MCU, WiFi built-in |
| SIM800L | SMS alert on missed dose |
| DS3231 RTC | Autonomous timekeeping (battery-backed) |
| SSD1306 OLED 128×64 | Display med name + dose during alarm |
| Active buzzer | Audio alarm |
| LEDs (1 per compartment) | Visual compartment indicator |
| Push button (PRIS) | Dose confirmation |
| TP4056 + 18650 Li-ion | Battery power |
| 1000µF cap on SIM800L VCC | Stabilize 2A peak current draw |

---

## Flutter App — Screens & State

**6 screens:**
1. `wifi_connect_screen.dart` — instructions to join "CareBox" WiFi + ping /status to verify
2. `dashboard_screen.dart` — today's schedule, next dose, mark as taken
3. `medications_screen.dart` — full list, delete button
4. `add_medication_screen.dart` — form: name, dose, time, compartment, days
5. `settings_screen.dart` — caregiver phone number
6. `missed_dose_modal.dart` — alert display

**Packages (updated):**
```yaml
http: ^1.2.0
provider: ^6.1.2
permission_handler: ^11.0.0
shared_preferences: ^2.2.2
google_fonts: ^6.1.0
```
`flutter_bluetooth_serial` removed.

**Design:** Samsung One UI — #F1F3F5 bg, #FFFFFF cards, #1259C3 primary blue, Outfit font, 20px card radius, pill buttons, filled round icons

---

## Flutter App — Remaining Tasks (in order)

### Step 1 — Cleanup ✅ (partially done)
- [x] Data models: `medication.dart`, `dose_log.dart`
- [x] `medication_provider.dart` with SharedPreferences
- [ ] Remove `flutter_bluetooth_serial` from pubspec.yaml
- [ ] Add `http: ^1.2.0`
- [ ] Run `flutter pub get`

### Step 2 — API Service Layer
- [ ] Create `lib/services/api_service.dart`
  - `static const String baseUrl = 'http://192.168.4.1'`
  - `Future<bool> checkConnection()` → GET /status, returns true if 200
  - `Future<void> syncTime()` → POST /time with current Unix timestamp
  - `Future<List<Medication>> getMedications()` → GET /medications
  - `Future<void> addMedication(Medication m)` → POST /medications
  - `Future<void> deleteMedication(String id)` → DELETE /medications/{id}
  - `Future<void> markAsTaken(String id)` → POST /medications/{id}/taken
  - `Future<List<DoseLog>> getLogs()` → GET /logs
  - `Future<void> saveSettings(String phone)` → POST /settings
  - `Future<String?> getSettings()` → GET /settings
  - All methods throw descriptive exceptions on failure

### Step 3 — Provider Update
- [ ] Update `medication_provider.dart`:
  - Add `ApiService _api`
  - `loadFromDevice()` → calls `_api.getMedications()` + `_api.syncTime()`
  - `addMedication()` → calls `_api.addMedication()` then refreshes list
  - `deleteMedication()` → calls `_api.deleteMedication()` then refreshes list
  - `markAsTaken()` → calls `_api.markAsTaken()` then refreshes
  - Keep SharedPreferences as offline cache fallback

### Step 4 — WiFi Connect Screen
- [ ] Replace `bluetooth_pairing_screen.dart` with `wifi_connect_screen.dart`
  - Step 1 instruction card: "Open phone Settings → WiFi → connect to 'CareBox'"
  - Step 2: "Tap Connect below"
  - On tap: calls `checkConnection()`, shows spinner
  - Success → navigate to Dashboard + call `loadFromDevice()` + `syncTime()`
  - Failure → show error "CareBox not found. Make sure you're connected to the CareBox WiFi network."

### Step 5 — Wire Screens to API
- [ ] Dashboard: loads from provider, "Mark as Taken" calls `markAsTaken()`
- [ ] Medications screen: lists from provider, delete calls `deleteMedication()`
- [ ] Add medication form: submit calls `addMedication()`
- [ ] Settings screen: loads phone from `getSettings()`, save calls `saveSettings()`

### Step 6 — Build & Test
- [ ] `flutter build apk --release`
- [ ] Test on Android: connect to CareBox hotspot → verify each screen works

---

## ESP32 Firmware Tasks (in order)

### Step 1 — Dev Environment
- [ ] Arduino IDE or PlatformIO with ESP32 board support
- [ ] Install libraries:
  - `ESPAsyncWebServer` + `AsyncTCP`
  - `ArduinoJson` (v6)
  - `RTClib` (DS3231)
  - `U8g2` (OLED)
  - `Preferences` (NVS)

### Step 2 — WiFi AP + Web Server
- [ ] `WiFi.softAP("CareBox", "carebox123")`
- [ ] Instantiate `AsyncWebServer server(80)`
- [ ] Implement all REST endpoints (GET/POST/DELETE handlers)
- [ ] JSON serialization/deserialization with ArduinoJson
- [ ] Test with Postman/browser before touching Flutter

### Step 3 — Core Firmware Modules
- [ ] `nvs_manager` — save/load medication list + caregiver number using Preferences
- [ ] `rtc_manager` — read DS3231, sync from POST /time
- [ ] `alarm_engine` — compare RTC time to schedule every second, trigger alarm

### Step 4 — Alarm State Machine
```
IDLE → (time matches) → ALERTING
ALERTING + button / POST taken → CONFIRMED → log NVS → IDLE
ALERTING + 10min timeout → MISSED → log NVS → SMS via SIM800L → IDLE
```

### Step 5 — Peripherals
- [ ] LED per compartment (GPIO), buzzer pattern, button debounce
- [ ] OLED: idle screen (time + date), alarm screen (med name + dose)

### Step 6 — SIM800L SMS
- [ ] AT command wrapper, `sendSMS(number, message)`
- [ ] Test: trigger missed dose → verify SMS received

---

## Integration & Testing

- [ ] Add med via app → verify GET /medications returns it
- [ ] Alarm fires at scheduled time → LED + buzzer + OLED activate
- [ ] Button press → CONFIRMED → GET /logs shows "taken"
- [ ] No press after 10 min → MISSED → SMS sent
- [ ] App Mark as Taken → same as button press
- [ ] WiFi disconnect mid-session → ESP32 keeps schedule, reconnect works
- [ ] Power cycle → RTC keeps time, NVS schedule survives

---

## Demo Prep

- Pre-load 2–3 medications via app before presenting
- Set one alarm 2–3 minutes away to fire live during demo
- Have a phone ready to receive the SMS
- Print a one-page summary for the client

---

## File Locations

- Flutter project: `C:\Users\Informatics\Documents\Zelectro\Medication Box\Android App\carebox\`
- Stitch HTML exports: `C:\Users\Informatics\Documents\Zelectro\Medication Box\Android App\screens\`
- Architecture doc: `CareBox_Architecture_Plan.md`
