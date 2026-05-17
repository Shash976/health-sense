// BioAMP Health Sense — main sketch
// Responsibilities: hardware init, global state, setup(), loop().
// All other logic lives in the module files (*.ino) in this folder.

#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>
#include <XPT2046_Touchscreen.h>
#include <Adafruit_MCP4725.h>
#include <Adafruit_ADS1X15.h>
#include <WiFiNINA.h>
#include <ArduinoJson.h>

#include "config.h"
#include "types.h"
#include "logo_bitmap.h"

// ── Hardware objects ──────────────────────────────────────────────────────────
Adafruit_ILI9341 tft(TFT_CS, TFT_DC, TFT_RST);
XPT2046_Touchscreen ts(TOUCH_CS, TOUCH_IRQ);
Adafruit_MCP4725 dac;
Adafruit_ADS1115 ads;
WiFiServer server(80);

// ── Touch calibration ─────────────────────────────────────────────────────────
int TS_MINX;
int TS_MAXX;
int TS_MINY;
int TS_MAXY;

// ── Graph layout ──────────────────────────────────────────────────────────────
int graphX = 20;
int graphY = 30;
int graphWidth = 200;
int graphHeight = 220;

// ── App state ─────────────────────────────────────────────────────────────────
Mode currentMode;
bool demoMode = false;

// ── Analyte state ─────────────────────────────────────────────────────────────
Analyte analyte;
double result = 0.0;
bool resultReady = false;
bool processing = false;
bool processingStarted = false;

const Analyte ANALYTE_TABLE[] = {
  {"Bilirubin",  0.15,  0.1,   1.2,  17.1,   1000, 9.2609e-9, 7.276e-7},
  {"ALP",        0.25, 44.0, 147.0,   0.0,    800, 9.2609e-9, 7.276e-7},
  {"ALT",        0.30,  7.0,  56.0,   0.0,   1200, 9.2609e-9, 7.276e-7},
  {"AST",        0.27, 10.0,  40.0,   0.0,   1100, 9.2609e-9, 7.276e-7},
  {"Phosphorus", 0.22,  2.5,   4.5,  0.3229,  900, 9.2609e-9, 7.276e-7},
  {"Albumin",    0.18,  3.5,   5.0, 150.0,   1500, 9.2609e-9, 7.276e-7},
  {"Ascorbic",   0.20,  0.4,   1.5,  56.78,   700, 9.2609e-9, 7.276e-7},
};
const int NUM_ANALYTES = sizeof(ANALYTE_TABLE) / sizeof(ANALYTE_TABLE[0]);
int analyteCurrentPage = 0;

// ── CV state ──────────────────────────────────────────────────────────────────
float START_VOLTAGE;
float END_VOLTAGE;
float SCAN_RATE;
int NUM_CYCLES;
bool cvRunning = false;
bool rerunRequested = false;
bool cvRequested = false;
bool newCVPointAvailable = false;
float currentVoltage = 0;
float currentCurrent = 0;
int totalSteps = 0;
int stepIndex = 0;
int currentCycle = 0;
bool sweepingForward = true;
float stepSize = 0;
unsigned long lastStepTime = 0;

// ── DPV state ─────────────────────────────────────────────────────────────────
float STEP_HEIGHT;
float PULSE_HEIGHT;
int PULSE_WIDTH;
int STEP_TIME;
bool dpvRunning = false;
bool dpvRequested = false;
bool newDPVPointAvailable = false;
bool axesDrawn = false;
float dpvVoltage;

// ── AMP state ─────────────────────────────────────────────────────────────────
float OX_POTENTIAL;
int AMP_RUN_TIME;
int MEASURE_INTERVAL;
bool ampRunning = false;
bool ampRequested = false;
bool newAmpPointAvailable = false;
int ampIndex = 0;
int ampSteps = 0;
float ampCurrent;
int ampTime;

// Voltage shift: maps -1V..+1V to 0V..2V for MCP4725.
float V_SHIFT = 1.0;

// ── Setup ─────────────────────────────────────────────────────────────────────
void setup() {
  Serial.begin(115200);
  delay(500);

  if (WiFi.status() == WL_NO_MODULE) {
    Serial.println("WiFi module not found!");
    while (true);
  }

  tft.begin();
  ts.begin();
  ts.setRotation(0);
  tft.setRotation(0);
  tft.fillScreen(ILI9341_WHITE);

  dac.begin(0x60);
  ads.setGain(GAIN_TWOTHIRDS);
  ads.begin();

  Serial.print("Starting AP: "); Serial.println(AP_SSID);
  WiFi.beginAP(AP_SSID, AP_PASSWORD);
  delay(1000);
  server.begin();
  Serial.print("AP IP: "); Serial.println(WiFi.localIP());

  drawWelcomeScreen();
  currentMode = WELCOME;
}

// ── Loop ──────────────────────────────────────────────────────────────────────
void loop() {
  WiFiClient client = server.available();
  if (client && client.connected()) {
    Serial.println("Client connected");
    String req = client.readStringUntil('\r');
    client.readStringUntil('\n');
    Serial.println("REQ: " + req);

    if      (req.startsWith("GET /whoami"))   handleWhoAmI(client);
    else if (req.startsWith("GET /result"))   handleGetResult(client);
    else if (req.startsWith("POST /test"))    handlePostTest(client);
    else if (req.startsWith("POST /cv"))      handleCV(client);
    else if (req.startsWith("GET /cvdata"))   handleCVData(client);
    else if (req.startsWith("POST /dpv"))     handleDPV(client);
    else if (req.startsWith("GET /dpvdata"))  handleDPVData(client);
    else if (req.startsWith("POST /amp"))     handleAmp(client);
    else if (req.startsWith("GET /ampdata"))  handleAmpData(client);
    else respondJSON(client, "{\"status\":\"error\",\"message\":\"unknown endpoint\"}", 404);

    client.stop();
  }

  if (cvRequested)      { cvRequested = false;   startCV(); }
  if (cvRunning)          performCVStep();

  if (processingStarted) {
    processingStarted = false;
    performTest(analyte);
  }

  if (dpvRequested)     { dpvRequested = false;  startDPV(); }
  if (dpvRunning) {
    if ((START_VOLTAGE < END_VOLTAGE && dpvVoltage <= END_VOLTAGE) ||
        (START_VOLTAGE > END_VOLTAGE && dpvVoltage >= END_VOLTAGE)) {
      performDPVStep();
    } else {
      dpvRunning = false;
    }
  }

  if (ampRequested)     { ampRequested = false;  startAmp(); }
  if (ampRunning) {
    if (ampIndex < ampSteps) {
      ampStep();
      ampIndex++;
    } else {
      ampRunning = false;
      Serial.println("Amperometry complete");
    }
  }

  handleTouch();
}
