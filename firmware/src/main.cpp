#include <Arduino.h>
#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

// ---------- Config ----------
const char* AP_SSID = "CareBox";
const char* AP_PASS = "carebox123";
WebServer server(80);

#define LED_PIN 8  // ESP32-C3 Super Mini onboard LED, active LOW
// NOTE: GPIO8/GPIO9 are the default I2C pins (SDA/SCL) in the Arduino core.
// The LED shares GPIO8, so in Phase 3 call Wire.begin(SDA, SCL) with other pins
// (e.g. GPIO6 / GPIO7).

#define MAX_MEDS 20
#define MAX_LOGS 20

void setLed(bool on) { digitalWrite(LED_PIN, on ? LOW : HIGH); }
void flashLed(int times = 1) {
  for (int i = 0; i < times; i++) { setLed(true); delay(150); setLed(false); delay(150); }
}

// ---------- Data ----------
struct Medication {
  String id, name, dose;
  int hour, minute, compartment;
  bool days[7];
};
Medication medications[MAX_MEDS];
int medCount = 0;

struct DoseLog {
  String medicationId, medicationName, status, scheduledTime, date, confirmedAt;
};
DoseLog logs[MAX_LOGS];
int logCount = 0;
String caregiverPhone = "";

void addLog(const String& id, const String& name, const String& status) {
  if (logCount >= MAX_LOGS) {  // drop oldest, keep last 20
    for (int i = 0; i < MAX_LOGS - 1; i++) logs[i] = logs[i + 1];
    logCount = MAX_LOGS - 1;
  }
  logs[logCount++] = { id, name, status, "", "", "" };
}

// ---------- Helpers ----------
void sendJson(int code, const String& json) {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET,POST,DELETE,OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  server.send(code, "application/json", json);
  setLed(false); delay(30); setLed(true);  // short blink per request
}

void sendError(int code, const char* msg) {
  String out = String("{\"status\":\"error\",\"message\":\"") + msg + "\"}";
  sendJson(code, out);
}

// Parse JSON body; sends error and returns false on failure
bool parseBody(JsonDocument& doc) {
  String body = server.arg("plain");
  if (body.isEmpty()) {
    Serial.println("DEBUG: no plain arg, trying raw client read");
    WiFiClient client = server.client();
    unsigned long timeout = millis() + 200;
    while (client.available() == 0 && millis() < timeout) delay(1);
    if (client.available()) body = client.readString();
  }
  if (body.isEmpty()) {
    Serial.println("ERROR: empty body");
    Serial.print("Content-Type: "); Serial.println(server.header("Content-Type"));
    sendError(400, "missing body"); return false;
  }
  Serial.print("Body: "); Serial.println(body);
  DeserializationError err = deserializeJson(doc, body);
  if (err) {
    Serial.print("JSON error: "); Serial.println(err.c_str());
    sendError(400, "invalid json"); return false;
  }
  return true;
}

int findMed(const String& id) {
  for (int i = 0; i < medCount; i++) if (medications[i].id == id) return i;
  return -1;
}

// ---------- Handlers ----------
void handleStatus() {
  DynamicJsonDocument doc(512);
  doc["status"] = "ok";
  doc["time"] = "08:30";
  doc["date"] = "15/10/2026";
  doc["alarmActive"] = false;
  doc["nextDose"] = (const char*)nullptr;  // JSON null
  String out; serializeJson(doc, out);
  sendJson(200, out);
}

void handleTimeSync() {
  DynamicJsonDocument doc(128);
  if (!parseBody(doc)) return;
  if (!doc["timestamp"].is<long long>() && !doc["timestamp"].is<unsigned long>()) {
    sendError(400, "timestamp required"); return;
  }
  // Phase 3: rtc.adjust(DateTime(timestamp))
  sendJson(200, "{\"status\":\"ok\"}");
}

void handleGetMedications() {
  // 20 meds x ~270 bytes of pool each -> 4096 overflowed; use 8192
  DynamicJsonDocument doc(8192);
  doc["status"] = "ok";
  JsonArray arr = doc.createNestedArray("medications");
  for (int i = 0; i < medCount; i++) {
    JsonObject m = arr.createNestedObject();
    m["id"] = medications[i].id;
    m["name"] = medications[i].name;
    m["dose"] = medications[i].dose;
    m["hour"] = medications[i].hour;
    m["minute"] = medications[i].minute;
    m["compartment"] = medications[i].compartment;
    JsonArray d = m.createNestedArray("days");
    for (int j = 0; j < 7; j++) d.add(medications[i].days[j]);
  }
  if (doc.overflowed()) { sendError(500, "response too large"); return; }
  String out; serializeJson(doc, out);
  sendJson(200, out);
}

void handleAddMedication() {
  if (medCount >= MAX_MEDS) {
    Serial.println("ERROR: max reached");
    sendError(400, "max reached"); return;
  }
  DynamicJsonDocument doc(768);
  if (!parseBody(doc)) return;

  String id = doc["id"].as<String>();
  int hour = doc["hour"] | -1;
  int minute = doc["minute"] | -1;
  int comp = doc["compartment"] | -1;
  JsonArray days = doc["days"].as<JsonArray>();

  Serial.printf("Parsed: id='%s' hour=%d minute=%d comp=%d daysNull=%d daysSize=%u\n",
                id.c_str(), hour, minute, comp, (int)days.isNull(), (unsigned)days.size());

  if (id.length() == 0 || id == "null") {
    Serial.println("ERROR: id required");
    sendError(400, "id required"); return;
  }
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
    Serial.println("ERROR: bad time (wrong type, e.g. string instead of int, or out of range)");
    sendError(400, "bad time"); return;
  }
  if (comp < 1 || comp > 4) {
    Serial.println("ERROR: bad compartment (is the app sending 0-based 0-3?)");
    sendError(400, "bad compartment"); return;
  }
  if (days.isNull() || days.size() != 7) {
    Serial.println("ERROR: days must have 7 items");
    sendError(400, "days must have 7 items"); return;
  }
  if (findMed(id) >= 0) {
    Serial.println("ERROR: duplicate id");
    sendError(409, "duplicate id"); return;
  }

  Medication& m = medications[medCount];
  m.id = id;
  m.name = doc["name"].as<String>();
  m.dose = doc["dose"].as<String>();
  m.hour = hour; m.minute = minute; m.compartment = comp;
  for (int d = 0; d < 7; d++) m.days[d] = days[d].as<bool>();
  medCount++;
  sendJson(200, "{\"status\":\"ok\"}");
}

void handleDeleteMedication() {
  String id = server.uri().substring(String("/medications/").length());
  int idx = findMed(id);
  if (idx < 0) { sendError(404, "not found"); return; }
  for (int j = idx; j < medCount - 1; j++) medications[j] = medications[j + 1];
  medCount--;
  sendJson(200, "{\"status\":\"ok\"}");
}

void handleMarkTaken() {
  // URI: /medications/{id}/taken
  String uri = server.uri();
  String id = uri.substring(String("/medications/").length(), uri.length() - String("/taken").length());
  int idx = findMed(id);
  if (idx < 0) { sendError(404, "not found"); return; }
  addLog(id, medications[idx].name, "taken");
  sendJson(200, "{\"status\":\"ok\"}");
}

void handleGetLogs() {
  DynamicJsonDocument doc(4096);
  doc["status"] = "ok";
  JsonArray arr = doc.createNestedArray("logs");
  for (int i = 0; i < logCount; i++) {
    JsonObject l = arr.createNestedObject();
    l["medicationId"] = logs[i].medicationId;
    l["medicationName"] = logs[i].medicationName;
    l["status"] = logs[i].status;
  }
  if (doc.overflowed()) { sendError(500, "response too large"); return; }
  String out; serializeJson(doc, out);
  sendJson(200, out);
}

void handlePostSettings() {
  DynamicJsonDocument doc(256);
  if (!parseBody(doc)) return;
  caregiverPhone = doc["caregiverPhone"].as<String>();
  if (caregiverPhone == "null") caregiverPhone = "";
  sendJson(200, "{\"status\":\"ok\"}");
}

void handleGetSettings() {
  DynamicJsonDocument doc(256);
  doc["status"] = "ok";
  doc["caregiverPhone"] = caregiverPhone;
  String out; serializeJson(doc, out);
  sendJson(200, out);
}

void handleNotFound() {
  String uri = server.uri();
  HTTPMethod method = server.method();
  if (method == HTTP_OPTIONS) { sendJson(204, ""); return; }
  if (method == HTTP_DELETE && uri.startsWith("/medications/") && uri.length() > 13) {
    handleDeleteMedication(); return;
  }
  if (method == HTTP_POST && uri.startsWith("/medications/") && uri.endsWith("/taken") &&
      uri.length() > 13 + 6) {
    handleMarkTaken(); return;
  }
  sendError(404, "not found");
}

// ---------- Setup / loop ----------
void setup() {
  Serial.begin(115200);
  pinMode(LED_PIN, OUTPUT);
  setLed(false);
  flashLed(3);
  delay(1000);

  WiFi.mode(WIFI_AP);
  WiFi.softAPConfig(IPAddress(192, 168, 4, 1), IPAddress(192, 168, 4, 1), IPAddress(255, 255, 255, 0));
  WiFi.softAP(AP_SSID, AP_PASS);
  // Many Super Mini boards have a poor antenna; lower TX power improves stability.
  // If clients still can't connect, try WIFI_POWER_11dBm or comment this out.
  WiFi.setTxPower(WIFI_POWER_8_5dBm);

  server.on("/status",      HTTP_GET,  handleStatus);
  server.on("/time",        HTTP_POST, handleTimeSync);
  server.on("/medications", HTTP_GET,  handleGetMedications);
  server.on("/medications", HTTP_POST, handleAddMedication);
  server.on("/logs",        HTTP_GET,  handleGetLogs);
  server.on("/settings",    HTTP_POST, handlePostSettings);
  server.on("/settings",    HTTP_GET,  handleGetSettings);
  server.onNotFound(handleNotFound);
  const char* hdrs[] = {"Content-Type"};
  server.collectHeaders(hdrs, 1);  // so parseBody can print Content-Type
  server.begin();

  Serial.print("AP IP: ");
  Serial.println(WiFi.softAPIP());
  flashLed(6);
  setLed(true);
}

void loop() {
  server.handleClient();
  delay(1);
}