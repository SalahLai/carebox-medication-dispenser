# CareBox — System Architecture & Project Plan

---

## 1. System Architecture

### 1.1 Hardware Architecture

The CareBox hardware is built around an **ESP32 microcontroller** as the central processing unit. All peripherals connect directly to it. The system is designed to operate fully autonomously after initial configuration — no internet, no external server, no cloud dependency.

```
┌─────────────────────────────────────────────────────┐
│                      ESP32                          │
│                                                     │
│  BT Classic ◄──── Flutter App (configuration)      │
│                                                     │
│  I2C ──────────► DS3231 RTC (timekeeping)          │
│  I2C ──────────► SSD1306 OLED (display)            │
│  UART ──────────► SIM800L GSM (SMS alerts)         │
│                                                     │
│  GPIO ──────────► Active Buzzer                    │
│  GPIO ──────────► Modular LEDs (per compartment)   │
│  GPIO ◄────────── PRIS Button (confirmation)       │
│                                                     │
│  3.3V ◄────────── TP4056 + Li-ion 18650 (power)   │
└─────────────────────────────────────────────────────┘
```

**Modular compartment design:**
The CareBox is physically split into two parts:
- **Main housing** — contains all electronics (ESP32, SIM800L, RTC, OLED, battery, button)
- **Compartment modules** — each has one LED indicator; modules clip onto the main housing. The number of compartments is configurable — the firmware handles any count.

**Power design:**
- Li-ion 18650 cell → TP4056 charge controller → 3.3V regulator → ESP32 and peripherals
- SIM800L requires its own stable 4V supply (separate LDO or boost from battery)
- Target autonomy: 24–48h between charges

---

### 1.2 Software Architecture

The software is split across two platforms: **ESP32 firmware** and the **Flutter mobile app**.

#### ESP32 Firmware

Built on Arduino framework (ESP-IDF compatible). Organized into the following modules:

```
firmware/
├── main.ino                  # Entry point, task scheduler
├── bluetooth/
│   └── bt_spp.cpp/h          # Bluetooth Classic SPP server
├── storage/
│   └── nvs_manager.cpp/h     # Schedule + SMS number persistence
├── rtc/
│   └── rtc_manager.cpp/h     # DS3231 read/write, time sync
├── alarm/
│   └── alarm_engine.cpp/h    # Schedule matching, alarm state machine
├── display/
│   └── oled_manager.cpp/h    # OLED rendering (u8g2 library)
├── gsm/
│   └── sim800l.cpp/h         # AT command handler, SMS send
└── ui/
    └── peripherals.cpp/h     # LED, buzzer, button control
```

**Alarm state machine:**

```
IDLE ──► (time matches schedule) ──► ALERTING
          │                              │
          │                        LED ON + Buzzer ON
          │                        OLED shows name + dose
          │                              │
          │                    ┌─────────┴──────────┐
          │                    │                    │
          │             Button pressed         10 min elapsed
          │                    │                    │
          │               CONFIRMED             MISSED
          │            Log taken in NVS      Log missed in NVS
          │                    │            Send SMS via SIM800L
          │                    │                    │
          └────────────────────┴────────────────────┘
                                    │
                                  IDLE
```

**Data stored in NVS (Non-Volatile Storage):**
- Medication entries: name, dose, time (HH:MM), compartment number, days of week
- Caregiver phone number
- Dose log: timestamp, status (taken / missed)

#### Flutter Mobile App

Built with Flutter (Dart). Minimal dependency footprint.

```
lib/
├── main.dart
├── providers/
│   └── bluetooth_provider.dart     # Connection state, send commands
├── screens/
│   ├── connection_screen.dart      # Scan + pair with CareBox
│   ├── medications_screen.dart     # List of all scheduled meds
│   ├── add_medication_screen.dart  # Form to add new entry
│   └── settings_screen.dart       # Caregiver phone number
└── models/
    └── medication.dart             # Data model
```

**Packages:**
- `flutter_bluetooth_serial` — Bluetooth Classic SPP communication
- `provider` — lightweight state management

---

### 1.3 How They Work Together

#### Configuration flow (app → ESP32)

```
User fills form on app
        │
        ▼
App serializes to command string
"ADD:Paracetamol:500mg:08:30:1:1111111"
 CMD : name     : dose : time:comp:days
        │
        ▼
Sent over Bluetooth Classic SPP
        │
        ▼
ESP32 receives string → parses it → stores in NVS
        │
        ▼
ESP32 sends ACK back → app shows success
```

**Command protocol (plain text over BT serial):**

| Command | Format | Description |
|---|---|---|
| Add medication | `ADD:name:dose:HH:MM:compartment:days` | days = 7-char binary string (1111111 = every day) |
| Delete medication | `DEL:index` | Remove entry by index |
| Set SMS number | `SMS:+213XXXXXXXXX` | Caregiver number |
| Sync time | `TIME:HH:MM:DD:MM:YYYY` | Sync RTC to phone time |
| Request list | `LIST` | ESP32 replies with all entries |

#### Alarm flow (autonomous, no phone needed)

```
DS3231 RTC ticks every second
        │
ESP32 checks current time against NVS schedule
        │
Match found?
        │
        ▼
LED of compartment N turns ON
Buzzer sounds (intermittent beep)
OLED displays: medication name + dose
        │
        ├── Button pressed within 10 min → TAKEN → log + silence
        │
        └── No press after 10 min → MISSED → log + SMS via SIM800L
```

---

## 2. Hardware Components

| # | Component | Role | Notes |
|---|---|---|---|
| 1 | ESP32 (38-pin dev board) | Main microcontroller | Bluetooth Classic built-in |
| 2 | SIM800L GSM module | SMS on missed dose | Needs stable 3.7–4.2V supply |
| 3 | DS3231 RTC module | Autonomous timekeeping | Battery-backed, I2C, very accurate |
| 4 | SSD1306 OLED 128×64 | Display med name + dose | I2C, 3.3V compatible |
| 5 | Active buzzer | Audio alarm | GPIO direct drive |
| 6 | LEDs (N × compartments) | Compartment indicator | One per compartment, 3mm or 5mm |
| 7 | 220Ω resistors | LED current limiting | One per LED |
| 8 | Push button (momentary) | PRIS confirmation | Pull-up resistor on GPIO |
| 9 | Li-ion 18650 cell | Main power source | 3.7V, 2000–3000mAh |
| 10 | TP4056 module | Battery charge controller | Micro-USB or USB-C input |
| 11 | 3.3V LDO regulator | Regulated supply for ESP32 | AMS1117-3.3 or similar |
| 12 | LDO/capacitor for SIM800L | Stable 4V for GSM module | SIM800L needs high peak current |
| 13 | SIM card (prepaid) | SMS network access | Any local operator |
| 14 | Plastic enclosure | Main housing | Custom cut or off-the-shelf |
| 15 | Compartment modules | Physical pill storage | Modular, clip-on design |
| 16 | Perfboard or custom PCB | Circuit assembly | PCB preferred for final build |
| 17 | Pin headers + JST connectors | Modular compartment wiring | One JST per compartment LED |

---

## 3. Tasks & Project Execution Plan

### Timeline overview — 10 days

| Phase | Days | Focus |
|---|---|---|
| 1 — Setup & foundation | D1–D2 | Hardware assembly + dev environment |
| 2 — ESP32 core firmware | D3–D4 | BT, NVS, RTC, alarm engine |
| 3 — Peripherals + alerts | D5–D6 | OLED, LED, buzzer, button, SIM800L |
| 4 — Flutter app | D7–D8 | 4 screens, BT communication |
| 5 — Integration + testing | D9–D10 | End-to-end, edge cases, demo polish |

---

### Phase 1 — Setup & foundation (D1–D2)

- [ ] Gather all components and verify against BOM
- [ ] Wire up breadboard prototype (ESP32 + RTC + OLED)
- [ ] Verify I2C communication with DS3231 and SSD1306
- [ ] Set up Arduino IDE / PlatformIO with ESP32 board support
- [ ] Install all firmware libraries:
  - `BluetoothSerial` (built-in)
  - `RTClib` (DS3231)
  - `U8g2` (OLED)
  - `Preferences` (NVS)
- [ ] Install Flutter + flutter_bluetooth_serial
- [ ] Hello world test: OLED prints text, RTC reads time

---

### Phase 2 — ESP32 core firmware (D3–D4)

- [ ] Implement `bt_spp` module — receive and parse command strings
- [ ] Implement `nvs_manager` — save/load medications and phone number
- [ ] Implement `rtc_manager` — read time, sync from BT TIME command
- [ ] Implement `alarm_engine` — compare RTC time to schedule every second
- [ ] Implement state machine: IDLE → ALERTING → CONFIRMED / MISSED
- [ ] Test: manually trigger alarm at a set time, confirm NVS logging

---

### Phase 3 — Peripherals + alerts (D5–D6)

- [ ] Implement `peripherals` module — LED control per compartment, buzzer pattern
- [ ] Implement `oled_manager` — idle screen (clock), alert screen (name + dose)
- [ ] Wire SIM800L, implement `sim800l` AT command handler
- [ ] Test SMS send: trigger missed dose → confirm SMS received
- [ ] Wire and test PRIS button with debounce
- [ ] Full alarm cycle test on breadboard: alert fires → button press → log

---

### Phase 4 — Flutter app (D7–D8)

- [ ] Build `connection_screen` — scan, pair, connect to CareBox
- [ ] Build `medications_screen` — list all entries, delete button
- [ ] Build `add_medication_screen` — form with name, dose, time picker, compartment, days
- [ ] Build `settings_screen` — caregiver phone number input
- [ ] Implement send commands over BT serial for each action
- [ ] Implement LIST command → parse response → populate medications screen
- [ ] Test full config flow: add medication on app → alarm fires on CareBox

---

### Phase 5 — Integration & testing (D9–D10)

- [ ] End-to-end test: configure via app → alarm fires → button press → logged as taken
- [ ] End-to-end test: configure via app → alarm fires → no press → SMS sent
- [ ] Edge cases:
  - [ ] Multiple medications same day
  - [ ] Bluetooth disconnects mid-config
  - [ ] Battery low behavior
  - [ ] RTC keeps time after power cycle
- [ ] Move from breadboard to perfboard / PCB
- [ ] Clean up enclosure wiring
- [ ] Demo run: simulate a full day schedule

---

### Deliverables checklist

- [ ] Functional prototype (hardware assembled)
- [ ] ESP32 firmware (source code + compiled binary)
- [ ] Flutter app (APK for demo)
- [ ] Wiring schematic
- [ ] This document (architecture + plan)

---

## Notes

- SIM800L peak current draw can reach 2A — ensure power supply is stable. Use a large capacitor (1000µF) across its VCC/GND if using a shared supply.
- DS3231 has a backup coin cell — RTC keeps time even when main battery is dead or charging.
- For demo: pre-load one or two medications via the app before presenting, so the alarm fires live during the demo.
- Modular compartment LEDs should be wired with JST connectors so compartment count can be changed without modifying the main PCB.
