// Combined Arduino Project: WiFi AP + CV + Analyte + Communication
#include <SPI.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_ILI9341.h>
#include <XPT2046_Touchscreen.h>
#include <Adafruit_MCP4725.h>
#include <Adafruit_ADS1X15.h>
#include <WiFiNINA.h>
#include <ArduinoJson.h>
#include "logo_bitmap.h"

// --- Access Point credentials ---
#define AP_SSID     "BioAMP"
#define AP_PASSWORD "bioamp123"

// --- Pin Configuration ---
#define TFT_CS   10
#define TFT_DC    8
#define TFT_RST   9
#define TOUCH_CS  7
#define TOUCH_IRQ 255

Adafruit_ILI9341 tft(TFT_CS, TFT_DC, TFT_RST);
XPT2046_Touchscreen ts(TOUCH_CS, TOUCH_IRQ);
Adafruit_MCP4725 dac;
Adafruit_ADS1115 ads;

// --- Touch Calibration ---
int TS_MINX;
int TS_MAXX;
int TS_MINY;
int TS_MAXY;

#define SCREEN_WIDTH  240
#define SCREEN_HEIGHT 320

#define V_REF 4.8 // From Touchscreen_CV, not same as that in Touch_BILLI (4.45) [CROSS-CHECK]
#define DAC_RESOLUTION 4095
#define ADS_GAIN 0.1875
#define FEEDBACK_RESISTOR 1000.0

// Voltage range shifted: -1V to +1V = 0V to 2V for MCP4725
float V_SHIFT = 1.0;

float START_VOLTAGE;
float END_VOLTAGE;
float SCAN_RATE;
int NUM_CYCLES;
bool cvRunning = false;
bool rerunRequested = false;

int graphX = 20;
int graphY = 30;
int graphWidth = 200;
int graphHeight = 220;

// Analyte struct
struct Analyte {
  String name;
  float oxidationPotential;
  float normalMin_mgdL;
  float normalMax_mgdL;
  float conversionFactor;
  unsigned long voltageGenTime;  // New parameter for voltage generation time
  float calibSlope;
  float calibConstant;
};

Analyte analyte;

double result = 0.0;
bool resultReady = false; // true once performTest() has stored a valid result
bool processing = false;
bool processingStarted = false;

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

float STEP_HEIGHT;
float PULSE_HEIGHT;
int PULSE_WIDTH;
int STEP_TIME;

bool dpvRunning = false;
bool dpvRequested = false;
bool newDPVPointAvailable = false;
bool axesDrawn = false;
float dpvVoltage;

bool ampRunning = false;
bool ampRequested = false;
bool newAmpPointAvailable = false;
int ampIndex = 0;
int ampSteps = 0;
float ampCurrent;
int ampTime;

float OX_POTENTIAL;
int AMP_RUN_TIME;
int MEASURE_INTERVAL;

WiFiServer server(80);

enum Mode {
  OPTIONS,
  V_OPTIONS,
  CV,
  DPV,
  AMPEROMETRY,
  ANALYTE,
  ANALYTE_PAGE,
  PARAM,
  WELCOME,
  NONE
};

enum Mode currentMode;
bool demoMode = false;

// demo vals
int analyteCurrentPage = 0;

Analyte analytes[] = {
  {"Bilirubin", 0.15, 0.1, 1.2, 17.1, 1000, 9.2609e-9, 7.276e-7},  // 1000 ms for Bilirubin
  {"ALP",       0.25, 44, 147, 0, 800, 9.2609e-9, 7.276e-7},       // 800 ms for ALP
  {"ALT",       0.30, 7, 56, 0, 1200, 9.2609e-9, 7.276e-7},        // 1200 ms for ALT
  {"AST",       0.27, 10, 40, 0, 1100, 9.2609e-9, 7.276e-7},       // 1100 ms for AST
  {"Phosphorus",0.22, 2.5, 4.5, 0.3229, 900, 9.2609e-9, 7.276e-7}, // 900 ms for Phosphorus
  {"Albumin",   0.18, 3.5, 5.0, 150, 1500, 9.2609e-9, 7.276e-7},  // 1500 ms for Albumin
  {"Ascorbic",  0.20, 0.4, 1.5, 56.78, 700, 9.2609e-9, 7.276e-7}  // 700 ms for Ascorbic
};
const int NUM_ANALYTES = sizeof(analytes)/sizeof(analytes[0]);




void waitForTouchRelease() {
  while (ts.touched()) {
    delay(10);
  }
  delay(100);
}

void drawWelcomeScreen() {
  tft.fillScreen(ILI9341_WHITE);

  // Title bar
  tft.fillRoundRect(3, 5, 235, 30, 8, ILI9341_ORANGE);
  tft.setTextColor(ILI9341_BLACK);
  tft.setTextSize(2);
  tft.setCursor(45, 12);
  tft.print("Health-Sense");

  // Logo
  int logoX = (tft.width() - LOGO_WIDTH) / 2;
  tft.drawRGBBitmap(logoX, 40, logoBitmap, LOGO_WIDTH, LOGO_HEIGHT);

  // AP info box
  tft.fillRoundRect(5, 185, 230, 60, 6, ILI9341_LIGHTGREY);
  tft.setTextColor(ILI9341_BLACK);
  tft.setTextSize(1);
  tft.setCursor(10, 193);
  tft.print("Connect phone to Wi-Fi:");
  tft.setTextSize(2);
  tft.setCursor(10, 205);
  tft.print(AP_SSID);
  tft.setTextSize(1);
  tft.setCursor(10, 225);
  tft.print("Password: "); tft.print(AP_PASSWORD);
  tft.setCursor(10, 237);
  tft.print("IP: 192.168.4.1");

  // Demo button
  tft.fillRoundRect(15, 258, 100, 45, 8, ILI9341_BLUE);
  tft.setTextColor(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.setCursor(30, 272);
  tft.print("Demo");

  // Start button
  tft.fillRoundRect(125, 258, 100, 45, 8, ILI9341_GREEN);
  tft.setTextColor(ILI9341_BLACK);
  tft.setTextSize(2);
  tft.setCursor(140, 272);
  tft.print("Start");

  Serial.println("Welcome screen drawn");
}

//=== Graph UI=====

void drawGraphAxes() {
  tft.fillScreen(ILI9341_WHITE);

  // Draw graph box
  tft.drawRect(graphX, graphY, graphWidth, graphHeight, ILI9341_BLACK);
  String mode = (currentMode==CV) ? "CV" : "DPV";
  String heading  = mode + " V vs I (uA)";
  // Title
  tft.setTextSize(2);
  tft.setTextColor(ILI9341_BLACK);
  tft.setCursor(5, 5);
  if (currentMode == CV) {
    tft.print("CV: I (uA) vs V (mV)");
  } else if (currentMode == DPV) {
    tft.print("DPV: I (uA) vs V (mV)");
  } else if (currentMode == AMPEROMETRY){
    tft.print("Amperometric: I (uA) vs Time (s)");
  }

  if (currentMode == DPV | currentMode == CV) {
    // === Y-axis: -1000 to +1000 uA with ticks at every 500 ===
    int yTicks[] = {1000, 500, 0, -500, -1000};
    for (int i = 0; i < 5; i++) {
      int uA = yTicks[i];
      int yPos = mapFloat(uA, 1000, -1000, graphY, graphY + graphHeight);

      // Tick line
      tft.drawFastHLine(graphX - 3, yPos, 3, ILI9341_BLACK);

      // Grid line
      tft.drawFastHLine(graphX, yPos, graphWidth, ILI9341_LIGHTGREY);

      // Label
      tft.setTextSize(1);
      if (uA == 0) {
        tft.setTextColor(ILI9341_BLUE); // Highlight 0
        tft.setCursor(3, yPos - 4);
        tft.print("  0");
        tft.setTextColor(ILI9341_BLACK); // Reset
      } else {
        tft.setCursor(0, yPos - 4);
        tft.print(uA);
      }
    }

    // === X-axis: -1V to +1V with ticks every 0.5 ===
    float xVolts[] = {-1.0, -0.5, 0.0, 0.5, 1.0};
    for (int i = 0; i < 5; i++) {
      float v = xVolts[i];
      int xPos = mapFloat(v, -1.0, 1.0, graphX, graphX + graphWidth);

      // Tick line
      tft.drawFastVLine(xPos, graphY + graphHeight, 3, ILI9341_BLACK);

      // Grid line
      tft.drawFastVLine(xPos, graphY, graphHeight, ILI9341_LIGHTGREY);

      // Label
      tft.setTextSize(1);
      tft.setCursor(xPos - 8, graphY + graphHeight + 5);
      tft.print(v, 1);
      tft.print("V");
    }
  } else {
    for (int uA = 1000; uA >= -1000; uA -= 500) {
      int y = mapFloat(uA, 1000, -1000, graphY, graphY + graphHeight);
      tft.drawFastHLine(graphX, y, graphWidth, ILI9341_LIGHTGREY);
      tft.setTextSize(1);
      tft.setCursor(0, y - 4);
      tft.print(uA);
    }
    Serial.println(AMP_RUN_TIME);
    for (int i = 0; i <= AMP_RUN_TIME; i += AMP_RUN_TIME / 4) {
      int x = map(i, 0, AMP_RUN_TIME, graphX, graphX + graphWidth);
      tft.drawFastVLine(x, graphY, graphHeight, ILI9341_LIGHTGREY);
      tft.setCursor(x - 5, graphY + graphHeight + 2);
      tft.print(i);
    }
  }


  // STOP button
  tft.fillRoundRect(0, 280, 80, 40, 8, ILI9341_ORANGE);
  tft.setCursor(15, 295);
  tft.setTextColor(ILI9341_WHITE); 
  tft.print("HOME");

  // HOME button
  tft.fillRoundRect(160, 280, 80, 40, 8, ILI9341_RED);
  tft.setCursor(180, 295);
  tft.setTextColor(ILI9341_WHITE); 
  tft.print("STOP");
  axesDrawn = true;
}

// ==== Demo Screens =====

void drawAnalyteDemoMenu(int page) {
  tft.fillScreen(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.setTextColor(ILI9341_DARKCYAN);
  tft.setCursor(10, 10);
  tft.print("Select Tests");

  int startIdx = page * 4;
  int endIdx = min(startIdx + 4, NUM_ANALYTES);

  for (int i = startIdx; i < endIdx; i++) {
    int y = 40 + (i - startIdx) * 60;
    tft.setCursor(10, y);
    tft.setTextColor(ILI9341_BLACK);
    tft.print(analytes[i].name);

    tft.fillRoundRect(150, y, 80, 35, 6, ILI9341_NAVY);
    tft.drawRoundRect(150, y, 80, 35, 6, ILI9341_CYAN);
    tft.setCursor(170, y + 12);
    tft.setTextColor(ILI9341_WHITE);
    tft.print("Test");
  }

  // Navigation
  if (page > 0) {
    tft.fillRoundRect(0, 280, 80, 40, 5, ILI9341_ORANGE); // Prev
    tft.setCursor(25, 295);
    tft.setTextColor(ILI9341_WHITE);
    tft.print("<");
  }

  tft.fillRoundRect(80, 280, 80, 40, 5, ILI9341_DARKGREEN);  // Home
  tft.setCursor(95, 295);
  tft.setTextColor(ILI9341_WHITE); tft.print("Home");

  if ((page + 1) * 4 < NUM_ANALYTES) {
    tft.fillRoundRect(0, 280, 80, 40, 5, ILI9341_ORANGE);
    tft.fillRoundRect(160, 280, 80, 40, 5, ILI9341_ORANGE); // Next
    tft.setCursor(210, 295);
    tft.setTextColor(ILI9341_WHITE);
    tft.print(">");
  }
}

void drawDemoInputScreen() {
  tft.fillScreen(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.setTextColor(ILI9341_BLACK);


  if (currentMode == CV) {
    START_VOLTAGE -= V_SHIFT;
    END_VOLTAGE -= V_SHIFT;
    tft.setCursor(10, 20);  tft.print("CV Potentiostat");
    tft.setCursor(10, 60);  tft.print("Start V: "); tft.print(START_VOLTAGE, 2);
    tft.setCursor(10, 90);  tft.print("Peak V:  "); tft.print(END_VOLTAGE, 2);
    tft.setCursor(10, 120); tft.print("Scan Rate: "); tft.print(SCAN_RATE, 2);
    tft.setCursor(10, 150); tft.print("Cycles: "); tft.print(NUM_CYCLES);
    START_VOLTAGE+= V_SHIFT;
    END_VOLTAGE += V_SHIFT;

  } else if (currentMode == DPV) {
    START_VOLTAGE -= V_SHIFT;
    END_VOLTAGE -= V_SHIFT;
    tft.setCursor(10, 20);  tft.print("DPV Potentiostat");
    tft.setCursor(10, 60);  tft.print("Start V: "); tft.print(START_VOLTAGE, 2);
    tft.setCursor(10, 90);  tft.print("End V:   "); tft.print(END_VOLTAGE, 2);
    tft.setCursor(10, 120); tft.print("Step Height: "); tft.print(STEP_HEIGHT, 2);
    tft.setCursor(10, 150); tft.print("Pulse Height: "); tft.print(PULSE_HEIGHT, 2);
    tft.setCursor(10, 180); tft.print("Step Time: "); tft.print(STEP_TIME);
    tft.setCursor(10, 210); tft.print("Pulse Width: "); tft.print(PULSE_WIDTH);
    START_VOLTAGE += V_SHIFT;
    END_VOLTAGE += V_SHIFT;
  } else if (currentMode == AMPEROMETRY) {
    tft.setCursor(10, 20);  tft.print("Amperometry");
    tft.setCursor(10, 60);  tft.print("Ox. Pot: "); tft.print(OX_POTENTIAL, 2);
    tft.setCursor(10, 90);  tft.print("Run Time: "); tft.print(AMP_RUN_TIME); tft.print("s");
  }

  // START Button (common to all)
  tft.fillRoundRect(60, 260, 120, 40, 10, ILI9341_GREEN);
  tft.setTextColor(ILI9341_WHITE);
  tft.setCursor(90, 275); 
  tft.print("START");
}


//================= SETUP ==============

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

  // Start access point — phone connects directly, no router needed.
  Serial.print("Starting AP: "); Serial.println(AP_SSID);
  WiFi.beginAP(AP_SSID, AP_PASSWORD);
  delay(1000);
  server.begin();
  Serial.print("AP IP: "); Serial.println(WiFi.localIP());

  drawWelcomeScreen();
  currentMode = Mode::WELCOME;
}

void respondJSON(WiFiClient& client, const String& json, int code = 200) {
  client.println("HTTP/1.1 " + String(code) + " OK");
  client.println("Content-Type: application/json");
  client.println("Access-Control-Allow-Origin: *");
  client.println("Connection: close");
  client.println();
  client.println(json);
  Serial.print("Sent response: "); Serial.println(json);
}

void loop() {
  // put your main code here, to run repeatedly:
  WiFiClient client = server.available();
  if (client && client.connected()) {
    Serial.println("Server is on");
    String req = client.readStringUntil('\r');
    client.readStringUntil('\n');
    Serial.println("🔎 " + req);

    if (req.startsWith("GET /whoami")) handleWhoAmI(client);
    else if (req.startsWith("GET /result")) handleGetResult(client);
    else if (req.startsWith("POST /test")) handlePostTest(client);
    else if (req.startsWith("POST /cv")) handleCV(client);
    else if (req.startsWith("GET /cvdata")) handleCVData(client);
    else if (req.startsWith("POST /dpv")) handleDPV(client);
    else if (req.startsWith("GET /dpvdata")) handleDPVData(client);
    else if (req.startsWith("POST /amp")) handleAmp(client);
    else if (req.startsWith("GET /ampdata")) handleAmpData(client);
    else respondJSON(client, "{\"status\":\"error\",\"message\":\"unknown endpoint\"}", 404);

    client.stop();
  }

  if (cvRequested) {
    cvRequested = false;
    startCV();
  }

  if (cvRunning) performCVStep();

  if (processingStarted) {
    processingStarted = false;
    performTest(analyte);
    Serial.print("testing is done on analyte");
  }

  if (dpvRequested) {
    dpvRequested = false;
    startDPV();
  }

  if (dpvRunning) {
    if ((START_VOLTAGE < END_VOLTAGE && dpvVoltage <= END_VOLTAGE) || (START_VOLTAGE > END_VOLTAGE && dpvVoltage >= END_VOLTAGE)){
      Serial.println("\t performing step");
      performDPVStep();
      Serial.println("\t step completed");
    } else {
      dpvRunning = false;
    }
  }

  if (ampRequested) {
    Serial.println("Amperometry requested... starting");
    ampRequested = false;
    startAmp();
  }

  if (ampRunning) {
    if (ampIndex < ampSteps) {
      ampStep();
      ampIndex++;
      Serial.println("New step");
    } else {
      ampRunning = false;
      Serial.println("Stopped amperometry process");
    }
  }

  if (ts.touched()) {
    TS_Point p = ts.getPoint();
    pinMode(TOUCH_CS, OUTPUT);
    digitalWrite(TOUCH_CS, HIGH);
    
    int x;
    int y;
    //Serial.print("Pressure: "); Serial.println(p.z);
    

    Serial.println(currentMode);
    
    if (currentMode == WELCOME) {
      TS_MINX = 732;
      TS_MAXX  = 3379;
      TS_MINY = 624;
      TS_MAXY = 3135;
      x = map(p.x, TS_MAXX, TS_MINX, 0, SCREEN_WIDTH);
      y = map(p.y, TS_MAXY, TS_MINY, 0, SCREEN_HEIGHT);

      // Start button — AP is already running, go straight to options.
      if (x >= 125 && x <= 225 && y >= 258 && y <= 303) {
        Serial.println("Start tapped — entering options.");
        demoMode = false;
        drawGeneralOptionsScreen();
        currentMode = OPTIONS;
      }
      // Demo button
      if (x >= 15 && x <= 115 && y >= 258 && y <= 303) {
        Serial.println("Demo mode selected.");
        demoMode = true;
        drawGeneralOptionsScreen();
        currentMode = OPTIONS;
      }
    } else if (currentMode == CV){
        TS_MINX = 732;
        TS_MAXX = 3379;
        TS_MINY = 624;
        TS_MAXY = 3135;
        x = map(p.x, TS_MINX, TS_MAXX, 0, tft.width());
        y = map(p.y, TS_MAXY, TS_MINY, 0, tft.height());
        Serial.print("X: "); Serial.print(x); Serial.print(", Y: "); Serial.println(y);

        Serial.println("Current Mode: CV");
        if (!cvRunning && !cvRequested && !axesDrawn) {
          if (demoMode) {
            if (x > 60 && x < 180 && y > 260 && y < 300) {
              cvRequested=true;
              drawGraphAxes();
            }
          } else {
            waitForParametersScreen("CV");
            currentMode = PARAM;
          }
        } else {
          // STOP => rerun from beginning
          if (x > 0 && x < 80 && y > 280 && y < 320) {
            rerunRequested = true;
            cvRunning = false;
          }
        }
        if (axesDrawn){
            // HOME button returns to setup screen
            if (x > 160 && x < 240 && y > 280 && y < 320) {
              rerunRequested = false;
              cvRunning = false;
              cvRequested = false;
              Serial.println("Home screen");
              axesDrawn = false;
              drawGeneralOptionsScreen();
              currentMode = OPTIONS;
            }
          }
    } else if (currentMode == DPV) {
      TS_MINX = 732;
      TS_MAXX = 3379;
      TS_MINY = 624;
      TS_MAXY = 3135;
      x = map(p.x, TS_MINX, TS_MAXX, 0, tft.width());
      y = map(p.y, TS_MAXY, TS_MINY, 0, tft.height());
      Serial.print("X: "); Serial.print(x); Serial.print(", Y: "); Serial.println(y);

      Serial.println("Current Mode: DPV");
      if (!dpvRunning && !dpvRequested && !axesDrawn) {
        if (demoMode){
          if (x > 60 && x < 180 && y > 260 && y < 300) {
              dpvRequested=true;
              drawGraphAxes();
            }
        } else {
          waitForParametersScreen("DPV");
          currentMode = PARAM;
        }
      }
      if (axesDrawn && !dpvRunning && !dpvRequested){
        if (x > 160 && x < 240 && y > 280 && y < 320) {
          dpvRunning = false;
          Serial.println("Home screen");
          axesDrawn = false;
          drawGeneralOptionsScreen();
          currentMode = OPTIONS;
        }
      }
    } else if (currentMode == OPTIONS) { 
        Serial.println("Mode: options");
        TS_Point p = ts.getPoint();
        pinMode(TOUCH_CS, OUTPUT);
        digitalWrite(TOUCH_CS, HIGH);
        TS_MINX = 329;
        TS_MAXX = 3835;
        TS_MINY = 530;
        TS_MAXY = 3800;

        x = map(p.x, TS_MAXX, TS_MINX, 0, SCREEN_WIDTH);
        y = map(p.y, TS_MAXY, TS_MINY, 0, SCREEN_HEIGHT);

        Serial.print("X: "); Serial.print(x); Serial.print(", Y: "); Serial.println(y);
        
        
        if (x > 20 && x < 220) {
          if (y > 70 && y < 120) {
            Serial.println("Switching to V Options");
            drawVoltammetryOptionsScreen();
            currentMode = Mode::V_OPTIONS;
            return;
          } else if (y > 135 && y < 185) {
            Serial.println("Switching to Analyte");
            if (demoMode) drawAnalyteDemoMenu(analyteCurrentPage);
            currentMode = Mode::ANALYTE;
            return;
          } else if (y > 200 && y < 250) {
            Serial.println("Exit — back to welcome screen.");
            drawWelcomeScreen();
            currentMode = Mode::WELCOME;
            return;
          }
        }
    } else if (currentMode == V_OPTIONS) {
      Serial.println("Voltammetry Options");
      TS_Point p = ts.getPoint();
      pinMode(TOUCH_CS, OUTPUT);
      digitalWrite(TOUCH_CS, HIGH);
      TS_MINX = 329;
      TS_MAXX = 3835;
      TS_MINY = 530;
      TS_MAXY = 3800;

      x = map(p.x, TS_MAXX, TS_MINX, 0, SCREEN_WIDTH);
      y = map(p.y, TS_MAXY, TS_MINY, 0, SCREEN_HEIGHT);
      Serial.print("X: "); Serial.print(x); Serial.print(", Y: "); Serial.println(y);

      if (x>20 && x<220) {
        if (y > 60 && y < 120){
          Serial.println("Switching to CV");
          currentMode = Mode::CV;
          if (demoMode){
            START_VOLTAGE = 0.0;
            END_VOLTAGE = 2.0;
            SCAN_RATE = 0.1;
            NUM_CYCLES = 2;
            drawDemoInputScreen();
          }
        }
        else if (y>130 && y<190){
          Serial.println("Switching to DPV");
          currentMode = Mode::DPV;
          if (demoMode) {
            STEP_HEIGHT = 0.01;       // Step height in volts (10 mV)
            PULSE_HEIGHT = 0.05;      // Pulse height in volts (50 mV)
            PULSE_WIDTH = 500;           // Pulse width in milliseconds
            STEP_TIME = 100;            // Step time in milliseconds

            // User-defined parameters
            START_VOLTAGE = 0.0;
            END_VOLTAGE = 2.0;
            drawDemoInputScreen();
          }
          
        }
        else if (y>210 && y<250){
          Serial.println("Switching to Amperometry");
          currentMode = Mode::AMPEROMETRY;
          if (demoMode) {
            OX_POTENTIAL = 0.5; // Demo Ox. Potential
            AMP_RUN_TIME = 10; // Demo Run Time
            drawDemoInputScreen();
            }
        }
        else if (y>255 && y<290){
          Serial.println("Going back to options");
          drawGeneralOptionsScreen();
          currentMode = Mode::OPTIONS;
        }
      }

    } else if (currentMode == ANALYTE || currentMode == ANALYTE_PAGE){
        TS_MINX = 732;
        TS_MAXX = 3379;
        TS_MINY = 624;
        TS_MAXY = 3135;
        x = map(p.x, TS_MINX, TS_MAXX, 0, tft.width());
        y = map(p.y, TS_MAXY, TS_MINY, 0, tft.height());
        Serial.println("Selected Analyte");
        
        if (demoMode){
          Serial.println("Analyte is in demo mode");
          if (y > 280 && y < 320) {
            // Navigation area
            if (currentMode == ANALYTE){
              if (x >= 0 && x < 80 && analyteCurrentPage == 0) {
                // Next Button (only on page 0)
                analyteCurrentPage++;
                drawAnalyteDemoMenu(analyteCurrentPage);
                waitForTouchRelease();
                return;
              } else if (x >= 160 && x < 240 && analyteCurrentPage == 1) {
              // Prev Button (only on page 1)
                analyteCurrentPage--;
                drawAnalyteDemoMenu(analyteCurrentPage);
                waitForTouchRelease();
                return;
              }
            } else if (x >= 80 && x < 160) {
              if (currentMode == ANALYTE){
                // Home Button
                drawGeneralOptionsScreen();
                currentMode = OPTIONS;
              } else if (currentMode == ANALYTE_PAGE) {
                drawAnalyteDemoMenu(analyteCurrentPage);
                currentMode = ANALYTE;
              }
              
              return;
            }
          }
          // Test Buttons
          int index = -1;
          int startIdx = analyteCurrentPage * 4;
          int endIdx = min(startIdx + 4, NUM_ANALYTES);
          for (int i = startIdx; i < endIdx; i++) {
            int yBtn = -35 + (i - startIdx) * 70;
            if (x >= -5 && x <= 100 && y >= yBtn && y <= yBtn + 40) {
              index = i;
              break;
            }
          }

          if (index >= 0 && index < NUM_ANALYTES) {
            waitForTouchRelease();
            performTest(analytes[index]);
            currentMode = ANALYTE_PAGE;
          }
          delay(300); // debounce
        } else {
          Serial.print("Processing Started: "); Serial.print(processingStarted); Serial.print(", Processing: "); Serial.println(processing);
          if (!processing && !processingStarted){
            waitForParametersScreen("Analyte");
            Serial.println("Done");
            currentMode = PARAM;
          }
        }

    } else if (currentMode == PARAM){
      TS_Point p = ts.getPoint();
      pinMode(TOUCH_CS, OUTPUT); digitalWrite(TOUCH_CS, LOW); // Required reset

      TS_MINX = 329;
      TS_MAXX = 3835;
      TS_MINY = 530;
      TS_MAXY = 3800;

      p.x = map(p.x, TS_MINX, TS_MAXX, 0, tft.width());
      p.y = map(p.y, TS_MINY, TS_MAXY, 0, tft.height());
      Serial.println("Current Mode: Param");
      Serial.print("X: "); Serial.print(p.x); Serial.print(" , Y: "); Serial.println(p.y);
      if (p.x >= 60 && p.x <= 180 && p.y >= 80 && p.y <= 90) {
        Serial.println("Going back to option screen");
        drawGeneralOptionsScreen();
        currentMode = OPTIONS;
      }
    } else if (currentMode == AMPEROMETRY) {
      TS_MINX = 732;
      TS_MAXX = 3379;
      TS_MINY = 624;
      TS_MAXY = 3135;
      x = map(p.x, TS_MINX, TS_MAXX, 0, tft.width());
      y = map(p.y, TS_MAXY, TS_MINY, 0, tft.height());
      Serial.print("X: "); Serial.print(x); Serial.print(", Y: "); Serial.println(y);
      Serial.println("Current Mode: Amperometry Calib");
      if (axesDrawn && !ampRunning && !ampRequested){
        if (x > 160 && x < 240 && y > 280 && y < 320) {
          ampRunning = false;
          Serial.println("Home screen");
          axesDrawn = false;
          drawGeneralOptionsScreen();
          currentMode = OPTIONS;
        }
      }
      Serial.print(ampRunning); Serial.print(ampRequested); Serial.println(axesDrawn);
      if (!ampRunning && !ampRequested && !axesDrawn) {
        Serial.println(demoMode);
        if (demoMode){
          Serial.println("Demo mode for Amperometry Calib");
          if (x > 60 && x < 180 && y > 260 && y < 300) {
            ampRequested = true;
            delay(10);
            Serial.println("Starting demo Amperometry");
            drawGraphAxes();
          } 
        } else {
          waitForParametersScreen("Amperometry");
          currentMode = PARAM;
        }
      }
      
    } else {
        Serial.println("None");
        currentMode = OPTIONS;
      }
  }
}

// ========== CV Ops ==========

void startCV() {
  STEP_TIME = 10; //CONSTANT
  float totalTime = abs(END_VOLTAGE - START_VOLTAGE) / SCAN_RATE;
  totalSteps = totalTime * 1000.0 / STEP_TIME;
  stepSize = (END_VOLTAGE - START_VOLTAGE) / totalSteps;
  stepIndex = 0;
  currentCycle = 0;
  sweepingForward = true;
  cvRunning = true;
  lastStepTime = millis();
}

void performCVStep() {
  if (!cvRunning || newCVPointAvailable) return;
  if (millis() - lastStepTime < STEP_TIME) return;
  lastStepTime = millis();

  float v;
  if (sweepingForward) {
    v = START_VOLTAGE + stepIndex * stepSize;
  } else {
    v = END_VOLTAGE - stepIndex * stepSize;
  }

  int dacVal = (int)((v / V_REF) * DAC_RESOLUTION);
  dac.setVoltage(dacVal, false);

  int16_t adc = ads.readADC_SingleEnded(0) * -1;
  float mV = adc * ADS_GAIN;
  float current_uA = (mV / FEEDBACK_RESISTOR) / 1000.0;

  currentVoltage = v-V_SHIFT; // moves back to -1.0 to 1.0
  currentCurrent = current_uA;
  newCVPointAvailable = true;

  plotPoint(v, current_uA);
  Serial.print("New Point: "); Serial.print(v - V_SHIFT); Serial.print("V, "); Serial.print(current_uA); Serial.println("uA");

  stepIndex++;
  if (stepIndex >= totalSteps) {
    stepIndex = 0;
    if (sweepingForward) {
      sweepingForward = false;
    } else {
      sweepingForward = true;
      currentCycle++;
      if (currentCycle >= NUM_CYCLES) {
        cvRunning = false;
      }
    }
  }
}

float scanStepSize() {
  float totalTime = abs(END_VOLTAGE - START_VOLTAGE) / SCAN_RATE;
  Serial.print("Total Time: "); Serial.println(totalTime);
  int steps = totalTime * 1000.0 / STEP_TIME;
  Serial.print("Steps: "); Serial.println(steps);
  return (END_VOLTAGE - START_VOLTAGE) / steps;
}

void plotPoint(float xVal, float current_uA) {
  float xNorm;

  if (currentMode == CV || currentMode == DPV ) {
    xNorm = mapFloat(xVal, START_VOLTAGE, END_VOLTAGE, 0, graphWidth - 1);
  } else if (currentMode == AMPEROMETRY) {
    xNorm = mapFloat(xVal, 0, AMP_RUN_TIME, 0, graphWidth - 1);
  } else {
    return; // unknown mode
  }

  float yNorm = mapFloat(current_uA, -1000, 1000, graphHeight - 1, 0);

  int x = graphX + (int)xNorm;
  int y = graphY + (int)yNorm;

  if (x >= graphX && x < graphX + graphWidth && y >= graphY && y < graphY + graphHeight) {
    uint16_t color = (currentMode == AMPEROMETRY) ? ILI9341_BLUE : ILI9341_RED;
    tft.drawPixel(x, y, color);
    Serial.print("Plotted point: "); Serial.print(xVal); Serial.print(" , "); Serial.println(current_uA);
  } else {
    Serial.print("Skipped point (out of bounds): "); Serial.print(x); Serial.print(" , "); Serial.print(y); 
    Serial.print(" Graph Params: graphX -> "); Serial.print(graphX); Serial.print(" graphX + graphWidth -> "); Serial.print(graphX+graphWidth); Serial.print(" graphY -> "); Serial.print(graphY); Serial.print(" graphY + graphHeight -> "); Serial.println(graphY+graphHeight);
  }
}

float mapFloat(float x, float in_min, float in_max, float out_min, float out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

void showDone() {
  tft.setTextSize(2);
  tft.setTextColor(ILI9341_GREEN);
  tft.setCursor(20, 255);
  tft.print("Measurement Done");
}

// ========== DPV =============

void startDPV() {
  dpvVoltage = START_VOLTAGE; // in range from 0.0 to 2.0
  dpvRunning = true;
  currentCurrent = 0;
  Serial.print("Start Voltage: "); Serial.println(START_VOLTAGE);
  Serial.print("End Voltage: "); Serial.println(END_VOLTAGE);
  Serial.print("Step Height: "); Serial.println(STEP_HEIGHT);
  Serial.print("Step Time: "); Serial.println(STEP_TIME);
  Serial.print("Pulse Height: "); Serial.println(PULSE_HEIGHT);
  Serial.print("Pulse Width"); Serial.println(PULSE_WIDTH);

}

void performDPVStep(){
  // Shift voltage by +1V for level shifter
  float shiftedVoltage = dpvVoltage; // in range of 0 to 2
  // Set the base dpvVoltage for the step
  int dacValue = voltageToDAC(shiftedVoltage);
  dac.setVoltage(dacValue, false);
  delay(STEP_TIME);
  // Measure current before the pulse
  float currentBefore_mV = averageADCReading();
  // Apply the pulse
  dacValue = voltageToDAC(shiftedVoltage + PULSE_HEIGHT);
  dac.setVoltage(dacValue, false);
  delay(PULSE_WIDTH);
  // Measure current after the pulse
  float currentAfter_mV = averageADCReading();
  // Calculate differential current (I after - I before)
  float differentialCurrent_mA = (currentAfter_mV - currentBefore_mV) / 1000.0;
  // Send data to Serial Monitor
  Serial.print("dpvVoltage: ");
  Serial.print(dpvVoltage-V_SHIFT, 2);
  Serial.print(" V, Differential Current: ");
  Serial.print(differentialCurrent_mA, 6);
  Serial.println(" mA");
  currentCurrent = differentialCurrent_mA*1000; // in uA
  currentVoltage = dpvVoltage - V_SHIFT; // shifted to -1.0 to 1.0
  newDPVPointAvailable = true;
  // Display data on OLED
  plotPoint(dpvVoltage, currentCurrent); // plot point function needs points in 0 to 2 and current in uA
  // Increment dpvVoltage by step height
  if (START_VOLTAGE < END_VOLTAGE) {
    dpvVoltage += STEP_HEIGHT;
  } else {
    dpvVoltage -= STEP_HEIGHT;
  }
}

int voltageToDAC(float voltage) {
  return (int)((voltage / V_REF) * DAC_RESOLUTION);
}

float adsToMilliVoltage(int16_t adsValue) {
  return adsValue * ADS_GAIN;
}

// Function to take multiple ADC readings and average them for better accuracy
float averageADCReading() {
  const int NUM_READINGS = 10;
  long sum = 0;
  for (int i = 0; i < NUM_READINGS; i++) {
    sum += ads.readADC_SingleEnded(0);
    delay(1);  // Short delay between readings
  }
  return (sum / (float)NUM_READINGS) * ADS_GAIN;
} 

// ========== Analyte =============

void performTest(Analyte a) {
  tft.fillRect(60, 140, 120, 40, ILI9341_YELLOW);
  tft.setCursor(75, 150);
  tft.setTextColor(ILI9341_BLACK);
  tft.setTextSize(2);
  tft.print("Testing...");
  delay(800);
  Serial.println("Starting test");
  Serial.print("Name: "); Serial.println(a.name);
  Serial.print("Oxidation Potential: "); Serial.println(a.oxidationPotential);
  Serial.print("Normal Min: "); Serial.print(a.normalMin_mgdL); Serial.println(" mg/dl ");
  Serial.print("Normal Max: "); Serial.print(a.normalMax_mgdL); Serial.println(" mg/dl ");

  
  // Set DAC voltage based on oxidation potential
  int dacVal = (((a.oxidationPotential+1)/ V_REF) * DAC_RESOLUTION);
  dac.setVoltage(dacVal, false);

  // Use the analyte-specific voltage generation time
  delay(a.voltageGenTime);  // This is where we use the voltage generation time

  int16_t adc = ads.readADC_SingleEnded(0);
  float mV = 1 * adc * ADS_GAIN * 0.2;
  float current_mA = mV / FEEDBACK_RESISTOR;
  float current_uA = current_mA *1000;
  float Concentration = (current_uA-a.calibConstant) / a.calibSlope; // y=mx+c -> x = (y-c)/m
  result = Concentration;
  resultReady = true;
  Serial.println("Test is done");
  showResult(a, Concentration, current_mA);
}

void showResult(Analyte a, float mgdL, float current_mA) {
  tft.fillScreen(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.setTextColor(ILI9341_DARKCYAN);
  tft.setCursor(10, 10);
  tft.print("Result: ");
  tft.print(a.name);

  tft.setCursor(10, 40);
  tft.setTextSize(3);
  tft.setTextColor(ILI9341_BLACK);
  tft.print(mgdL, 2);
  tft.print(" mg/dL");
  Serial.println("Testing is complete. Showing result");
  tft.setTextSize(1);
  tft.setCursor(10, 80);
  if (a.conversionFactor > 0) {
    float umol = mgdL * a.conversionFactor;
    tft.setTextColor(ILI9341_DARKGREY);
    tft.print(umol, 1);
    tft.print(" umol/L");
  }

  tft.setCursor(10, 110);
  tft.setTextColor(ILI9341_MAROON);
  tft.print("Current: ");
  tft.print(current_mA * 1000, 2);
  tft.print(" uA");

  tft.setCursor(10, 140);
  tft.setTextColor(ILI9341_BLUE);
  tft.print("Normal: ");
  tft.print(a.normalMin_mgdL);
  tft.print(" - ");
  tft.print(a.normalMax_mgdL);
  tft.print(" mg/dL");

  bool normal = mgdL >= a.normalMin_mgdL && mgdL <= a.normalMax_mgdL;
  tft.fillRoundRect(10, 180, 220, 30, 4, normal ? ILI9341_GREEN : ILI9341_RED);
  tft.setCursor(40, 188);
  tft.setTextColor(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.print(normal ? "Level is Normal" : "Consult Doctor");

  int backBtnY = 285;
  tft.fillRoundRect(60, backBtnY, 120, 40, 10, ILI9341_NAVY);
  tft.drawRoundRect(60, backBtnY, 120, 40, 10, ILI9341_WHITE);
  tft.setCursor(100, backBtnY + 15);
  tft.setTextColor(ILI9341_WHITE);
  tft.print("Back");

  // while (true) {
  //   if (ts.touched()) {
  //     Serial.println("...");
  //     TS_Point p = ts.getPoint();
  //     int x = map(p.x, TS_MINX, TS_MAXX, 0, SCREEN_WIDTH);
  //     int y = map(p.y, TS_MAXY, TS_MINY, 0, SCREEN_HEIGHT);
  //     if (x > 60 && x < 180 && y > backBtnY && y < backBtnY + 40) {
  //       waitForTouchRelease();
  //       return;
  //     }
  //   }
  // }
  Serial.println("Done, returning to main loop.");
}

// Amperometry Calib

void startAmp(){
  ampIndex = 0;
  ampCurrent = 0.0;
  ampTime = 0;
  ampSteps = AMP_RUN_TIME * 1000 / MEASURE_INTERVAL;
  // Operator-precedence fix: add V_SHIFT first, then divide — same pattern as performTest().
  int dacVal = (int)(((OX_POTENTIAL + 1.0) / V_REF) * DAC_RESOLUTION);
  dac.setVoltage(dacVal, false);
  ampRunning = true;
}

void ampStep() {
  int16_t adc = ads.readADC_SingleEnded(0);
  float mV = adc * ADS_GAIN;
  float current_uA = (mV / FEEDBACK_RESISTOR) / 1000.0;
  float time_s = ampIndex * MEASURE_INTERVAL / 1000.0;
  Serial.print("Ox. Potential: "); Serial.println(OX_POTENTIAL);
  Serial.print("Run Time: "); Serial.println(AMP_RUN_TIME);
  Serial.print("Measure Interval: "); Serial.println(MEASURE_INTERVAL);
  ampCurrent = current_uA;
  ampTime = time_s;
  plotPoint(time_s, current_uA);
  newAmpPointAvailable = true;
  delay(MEASURE_INTERVAL);
}

// ========== OPTIONS ==========

void drawGeneralOptionsScreen() {
  tft.fillScreen(ILI9341_WHITE);
  tft.setTextColor(ILI9341_BLACK);
  tft.setTextSize(2);
  tft.setCursor(10, 20);
  tft.print("Select Option:");

  tft.fillRoundRect(20, 70, 200, 50, 8, ILI9341_CYAN);
  tft.setCursor(40, 88);
  tft.setTextColor(ILI9341_BLACK);
  tft.print("Voltammetry");

  tft.fillRoundRect(20, 135, 200, 50, 8, ILI9341_GREEN);
  tft.setCursor(35, 153);
  tft.setTextColor(ILI9341_WHITE);
  tft.print("Analyte Test");

  tft.fillRoundRect(20, 200, 200, 50, 8, ILI9341_RED);
  tft.setCursor(80, 218);
  tft.setTextColor(ILI9341_WHITE);
  tft.print("Exit");
}

void drawVoltammetryOptionsScreen() {
  tft.fillScreen(ILI9341_WHITE);
  tft.setTextColor(ILI9341_BLACK);
  tft.setTextSize(2);
  tft.setCursor(10, 20);
  tft.print("Select Option:");

  // Draw 4 buttons
  tft.fillRoundRect(20, 60, 200, 60, 8, ILI9341_BLUE);
  tft.setCursor(25, 65);
  tft.setTextColor(ILI9341_WHITE);
  tft.print("Cyclic");
  tft.setCursor(25,85);
  tft.setTextColor(ILI9341_WHITE);
  tft.print("Voltammetry");
  tft.setCursor(25, 100);
  tft.setTextColor(ILI9341_WHITE);
  tft.print("(CV)");

  tft.fillRoundRect(20, 130, 200, 80, 8, ILI9341_CYAN);
  tft.setCursor(25, 135);
  tft.setTextColor(ILI9341_BLACK);
  tft.print("Differential ");
  tft.setCursor(25, 155);
  tft.setTextColor(ILI9341_BLACK);
  tft.print("Pulse");
  tft.setCursor(25, 170);
  tft.setTextColor(ILI9341_BLACK);
  tft.print("Voltammetry");
  tft.setCursor(25, 190);
  tft.setTextColor(ILI9341_BLACK);
  tft.print("(DPV)");

  tft.fillRoundRect(20, 220, 200, 40, 8, ILI9341_ORANGE);
  tft.setCursor(45, 230);
  tft.setTextColor(ILI9341_WHITE);
  tft.print("Amperometry");

  tft.fillRoundRect(20, 265, 200, 35, 8, ILI9341_RED);
  tft.setCursor(85, 275);
  tft.setTextColor(ILI9341_WHITE);
  tft.print("Exit");

}

void waitForParametersScreen(String type) {
  tft.fillScreen(ILI9341_WHITE);
  tft.setTextColor(ILI9341_BLACK);
  tft.setTextSize(2);
  tft.setCursor(10, 120);
  tft.print("Waiting for ");
  tft.print(type);
  tft.setCursor(10, 150);
  tft.print("parameters...");
  
  // Draw back button
  tft.fillRoundRect(60, 200, 120, 40, 10, ILI9341_RED);
  tft.setCursor(80, 215);
  tft.setTextColor(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.print("Back");
}


// ========== ROUTES ==========

void handleWhoAmI(WiFiClient& client) {
  respondJSON(client, "{\"name\":\"BioAMP\"}");
}

void handleGetResult(WiFiClient& client) {
  if (resultReady) {
    // Consume the result — clear before responding so a second poll gets not_started.
    double val = result;
    result = 0.0;
    resultReady = false;
    processing = false;
    processingStarted = false;
    respondJSON(client, "{\"value\":" + String(val, 2) + "}");
    Serial.println(val);
  } else if (processing || processingStarted) {
    respondJSON(client, "{\"status\":\"processing\"}");
  } else {
    respondJSON(client, "{\"status\":\"not_started\"}");
  }
}

void handlePostTest(WiFiClient& client) {
  int len = getContentLength(client);
  if (len <= 0) return respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid Content-Length\"}");

  String body = readRequestBody(client, len);
  StaticJsonDocument<256> doc;
  if (deserializeJson(doc, body)) return respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid JSON\"}", 400);

  analyte.name = (const char*)doc["task"];
  analyte.oxidationPotential = doc["oxidationPotential"].as<float>();
  analyte.normalMin_mgdL = doc["normalMinMGDL"].as<float>();
  analyte.normalMax_mgdL = doc["normalMaxMGDL"].as<float>();
  analyte.conversionFactor = doc["conversionFactor"].as<float>();
  analyte.voltageGenTime = doc["time"].as<unsigned long>();
  analyte.calibSlope = doc["calibSlope"].as<float>();
  analyte.calibConstant = doc["calibConstant"].as<float>();

  Serial.println(body);
  result = 0.0;
  resultReady = false;
  Analyte a = analyte;

  processing = true;
  processingStarted = true;
  currentMode = ANALYTE;

  respondJSON(client, "{\"status\":\"started\"}");
}

void handleCV(WiFiClient& client) {
  int len = getContentLength(client);
  if (len <= 0) return respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid Content-Length\"}");
  String body = readRequestBody(client, len);
  StaticJsonDocument<256> doc;
  if (deserializeJson(doc, body)) return respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid JSON\"}", 400);
  
  START_VOLTAGE = doc["startVoltage"] ;
  END_VOLTAGE = doc["endVoltage"];
  SCAN_RATE = doc["scanRate"];
  NUM_CYCLES = doc["cycles"];

  START_VOLTAGE += V_SHIFT;
  END_VOLTAGE += V_SHIFT;

  cvRequested = true;
  respondJSON(client, "{\"status\":\"cv_started\"}");
  delay(10);
  currentMode = CV;
  drawGraphAxes();

}

void handleCVData(WiFiClient& client) {
  if (newCVPointAvailable) {
    String json = "{\"x\":" + String(currentVoltage, 3) + ",\"y\":" + String(currentCurrent, 3) + "}";
    respondJSON(client, json);
    newCVPointAvailable = false;
  } else if (!cvRunning) {
    respondJSON(client, "{\"status\":\"cv_done\"}");
  } else {
    respondJSON(client, "{\"status\":\"waiting\"}");
  }
}

void handleDPV(WiFiClient& client){
  int len = getContentLength(client);
  if (len <= 0) return respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid Content-Length\"}");
  String body = readRequestBody(client, len);
  StaticJsonDocument<256> doc;
  if (deserializeJson(doc, body)) return respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid JSON\"}", 400);
  
  START_VOLTAGE = doc["startVoltage"] ;
  END_VOLTAGE = doc["endVoltage"];

  START_VOLTAGE += V_SHIFT;
  END_VOLTAGE += V_SHIFT;

  STEP_HEIGHT = doc["stepHeight"] | 0.01;
  PULSE_HEIGHT = doc["pulseHeight"] | 0.05;
  PULSE_WIDTH = doc["pulseWidth"] | 500;
  STEP_TIME = doc["stepTime"] | 100; //milliseconds

  dpvRequested = true;
  respondJSON(client, "{\"status\":\"dpv_started\"}");
  delay(10);
  currentMode = DPV;
  drawGraphAxes();
  
}

void handleDPVData(WiFiClient& client){
  if (newDPVPointAvailable) {
    String json = "{\"x\":" + String(currentVoltage, 8) + ",\"y\":" + String(currentCurrent, 8) + "}";
    respondJSON(client, json);
    newDPVPointAvailable = false;
  } else if (!dpvRunning && !dpvRequested) {
    respondJSON(client, "{\"status\":\"dpv_done\"}");
  } else {
    respondJSON(client, "{\"status\":\"waiting\"}");
  }
}

void handleAmp(WiFiClient& client){
  int len = getContentLength(client);
  if (len <= 0) return respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid Content-Length\"}");
  String body = readRequestBody(client, len);
  StaticJsonDocument<256> doc;
  if (deserializeJson(doc, body)) return respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid JSON\"}", 400);
  
  OX_POTENTIAL = doc["oxidationPotential"] | 0.1;
  AMP_RUN_TIME = doc["runTime"];
  MEASURE_INTERVAL = doc["measureInterval"] | 150;

  ampRequested = true;
  respondJSON(client, "{\"status\":\"amp_started\"}");
  delay(10);
  currentMode = AMPEROMETRY;
  drawGraphAxes();
}

void handleAmpData(WiFiClient& client){
  if (newAmpPointAvailable) {
    String json = "{\"x\":" + String(ampTime) + ",\"y\":" + String(ampCurrent, 5) + "}";
    respondJSON(client, json);
    newAmpPointAvailable = false;
  } else if (!ampRunning && !ampRequested) {
    respondJSON(client, "{\"status\":\"amp_done\"}");
  } else {
    respondJSON(client, "{\"status\":\"waiting\"}");
  }
}

//============Comms Utlis==========

int getContentLength(WiFiClient& client) {
  int contentLength = 0;
  while (client.available()) {
    String line = client.readStringUntil('\n');
    line.trim();
    if (line.length() == 0) break;
    line.toLowerCase();
    if (line.startsWith("content-length:")) {
      contentLength = line.substring(line.indexOf(':') + 1).toInt();
    }
  }
  return contentLength;
}

String readRequestBody(WiFiClient& client, int length) {
  uint8_t buffer[256];
  int read = client.readBytes(buffer, length);
  return String((char*)buffer).substring(0, read);
}
