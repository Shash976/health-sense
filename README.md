# BioAMP: Portable WiFi Potentiostat & Mobile Analysis Suite

BioAMP is an open-source portable electrochemical biosensing platform built on an Arduino-based potentiostat and a Flutter mobile app. The device creates its own WiFi hotspot; the app connects directly-no router required.

Supported techniques: **Cyclic Voltammetry (CV)**, **Differential Pulse Voltammetry (DPV)**, **Amperometry (AMP)**, and **Analyte-specific diagnostics**.

---

## Table of Contents

- [Features](#features)
- [How It Works](#how-it-works)
- [Hardware](#hardware)
- [File Structure](#file-structure)
- [Setup](#setup)
  - [Firmware](#firmware)
  - [Mobile App](#mobile-app)
- [REST API Reference](#rest-api-reference)
- [Built-in Analytes](#built-in-analytes)
- [CV Calibration & Analysis](#cv-calibration--analysis)
- [Extending the Platform](#extending-the-platform)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Features

| | |
|---|---|
|  **AP-mode WiFi** | Device creates its own hotspot - no router or internet needed |
|  **Three electrochemical techniques** | CV, DPV, and Amperometry |
|  **Analyte diagnostics** | Built-in calibrated tests for 7 blood analytes |
|  **Live data stream** | Real-time (x, y) point streaming to the app at 100 ms intervals |
|  **CSV export** | One-tap download of raw data; CV files tagged with concentration |
|  **On-device calibration analysis** | Load multiple CV CSVs, plot concentration vs. current, fit a regression line |
|  **Onboard touchscreen** | Live graph and mode switching directly on the device |
|  **Simple REST API** | All control via JSON over HTTP - easy to integrate with scripts or other tools |

---

## How It Works

```
┌──────────────────────────────────────────────────────────────────┐
│  BioAMP Device (Arduino)                                         │
│                                                                  │
│  WiFi AP "BioAMP" ──► REST API on 192.168.4.1:80               │
│       │                                                          │
│  DAC (MCP4725) ──► electrochemical cell ──► ADC (ADS1115)       │
│       │                                         │                │
│  TFT touchscreen (live graph + mode control)    │                │
└──────────────────────────────────────────────────────────────────┘
                   ▲                ▼
           POST config          GET data
                   │                │
┌──────────────────────────────────────────────────────────────────┐
│  Flutter Mobile App                                              │
│                                                                  │
│  Connect to "BioAMP" WiFi                                        │
│       │                                                          │
│  Ping /whoami  ──►  Confirm BioAMP identity                      │
│       │                                                          │
│  Select test  ──►  POST config  ──►  Poll /[mode]data            │
│       │                                    │                     │
│  Show live list / dashboard            Download CSV              │
│       │                                                          │
│  Analysis page: load CSVs, regression, export chart JPG         │
└──────────────────────────────────────────────────────────────────┘
```

### Typical session

1. Power on the BioAMP device. It starts the "BioAMP" hotspot.
3. On your phone, join **BioAMP** (password: `bioamp123`).
4. Open the app → tap **Connect to BioAMP** (auto-detects `192.168.4.1`).
5. Choose a test mode, fill in parameters, tap **Start**.
6. Watch data stream in real time; download CSV when done.
7. For analyte tests, the result and normal-range interpretation appear automatically.

---

## Hardware

| Component | Part |
|---|---|
| Microcontroller | Arduino (WiFiNINA-compatible, e.g. Arduino Nano 33 IoT / MKR WiFi 1010) |
| DAC | Adafruit MCP4725 (I²C, address `0x60`) |
| ADC | Adafruit ADS1115 (I²C, gain `TWOTHIRDS` → ±6.144 V) |
| Display | ILI9341 2.8" TFT (CS=10, DC=8, RST=9) |
| Touch | XPT2046 resistive touch (CS=7) |
| Voltage reference | V_REF = 4.8 V (level-shifted: −1 V .. +1 V → 0 V .. 2 V for DAC) |
| Feedback resistor | 1 kΩ (transimpedance amplifier) |

### Wiring summary

```
Arduino  ──SPI──►  TFT (ILI9341)   CS=10  DC=8  RST=9
Arduino  ──SPI──►  Touchscreen     CS=7
Arduino  ──I²C──►  DAC (MCP4725)   0x60
Arduino  ──I²C──►  ADC (ADS1115)   default addr
```

---

## File Structure

```
healthSense/
│
├── healthSense/                  # Arduino sketch folder
│   ├── healthSense.ino           # setup(), loop(), all global state
│   ├── config.h                  # Pin defines and hardware constants
│   ├── types.h                   # Analyte struct, Mode enum
│   ├── display_ui.ino            # All TFT drawing functions + plotPoint/mapFloat
│   ├── cv_mode.ino               # Cyclic Voltammetry step engine
│   ├── dpv_mode.ino              # Differential Pulse Voltammetry step engine
│   ├── amp_mode.ino              # Amperometry step engine
│   ├── analyte_mode.ino          # Analyte test execution + result display
│   ├── routes.ino                # HTTP endpoint handlers
│   ├── comms.ino                 # respondJSON, getContentLength, readRequestBody
│   ├── touch_handler.ino         # handleTouch() - full touch event dispatch
│   └── logo_bitmap.h             # Splash screen bitmap
│
└── lib/                          # Flutter app source
    ├── main.dart                 # App entry point; loads analyte config
    ├── welcome.dart              # Splash / landing page
    ├── wifi_scan_page.dart       # Device discovery and connection
    ├── options.dart              # Mode selection hub
    ├── cv_config_page.dart       # Cyclic Voltammetry config form
    ├── dpv_config_page.dart      # DPV config form
    ├── amp_config_page.dart      # Amperometry config form
    ├── volt_config_page.dart     # Generic config form + HTTP POST (shared)
    ├── volt_dashboard.dart       # Live data stream + CSV export
    ├── analyteTasks.dart         # Analyte selection and test launch
    ├── analyte_dashboard.dart    # Analyte result display with normal-range bar
    ├── analysis_page.dart        # Offline CV calibration analysis + regression
    └── analyte_constants.dart    # Analyte data model + SharedPreferences persistence
```

---

## Setup

### Firmware

**Dependencies** (install via Arduino Library Manager):

| Library | Purpose |
|---|---|
| `WiFiNINA` | WiFi AP and TCP server |
| `Adafruit GFX` | TFT graphics primitives |
| `Adafruit ILI9341` | TFT driver |
| `XPT2046_Touchscreen` | Resistive touch driver |
| `Adafruit MCP4725` | DAC control |
| `Adafruit ADS1X15` | ADC control |
| `ArduinoJson` | JSON parsing for REST requests |

**Flash the firmware:**

1. Open `healthSense/healthSense.ino` in Arduino IDE 2.x.
2. Select your board (e.g. **Arduino Nano 33 IoT**).
3. The sketch folder now contains multiple `.ino` and `.h` files - Arduino IDE handles them automatically.
4. Upload. Open Serial Monitor at **115200 baud** to confirm startup.

Expected serial output:
```
Starting AP: BioAMP
AP IP: 192.168.4.1
```

### Mobile App

**Requirements:** Flutter SDK ≥ 3.7, Android or iOS device.

```sh
git clone https://github.com/Shash976/bio-amp.git
cd bio-amp
flutter pub get
flutter run
```

Grant local network access when prompted (required for direct AP-mode communication).

**Key dependencies:**

| Package | Use |
|---|---|
| `http` | REST communication with device |
| `fl_chart` | Calibration curve chart |
| `file_picker` | CSV file selection for analysis |
| `flutter_downloader` | CSV save-to-downloads |
| `shared_preferences` | Analyte config persistence |
| `path_provider` | File paths |

---

## REST API Reference

Base URL: `http://192.168.4.1` (when connected to BioAMP hotspot)

All request bodies and responses are **JSON**. All responses include `Access-Control-Allow-Origin: *`.

### Identity

| Method | Endpoint | Response |
|---|---|---|
| GET | `/whoami` | `{"name":"BioAMP"}` |

### Analyte test

#### Start test
```http
POST /test
Content-Type: application/json

{
  "task":               "BIL",
  "oxidationPotential": 0.15,
  "normalMinMGDL":      0.1,
  "normalMaxMGDL":      1.2,
  "conversionFactor":   17.1,
  "time":               1000,
  "calibSlope":         9.2609e-9,
  "calibConstant":      7.276e-7
}
```
Response: `{"status":"started"}`

#### Poll result
```http
GET /result
```
Responses:
- `{"status":"not_started"}` - no test running
- `{"status":"processing"}` - test in progress (poll again in 2 s)
- `{"value":0.85}` - result in mg/dL (one-time; cleared on read)

---

### Cyclic Voltammetry (CV)

#### Start
```http
POST /cv
Content-Type: application/json

{
  "startVoltage": -1.0,
  "endVoltage":    1.0,
  "scanRate":      0.1,
  "cycles":        3
}
```
Voltages are in the **−1.0 V .. +1.0 V** range (firmware adds the 1 V level shift internally).  
Response: `{"status":"cv_started"}`

#### Stream data
```http
GET /cvdata
```
Responses:
- `{"x":-0.995,"y":0.012}` - next unread (x = voltage V, y = current µA)
- `{"status":"waiting"}` - no new point yet; poll again
- `{"status":"cv_done"}` - sweep complete

---

### Differential Pulse Voltammetry (DPV)

#### Start
```http
POST /dpv
Content-Type: application/json

{
  "startVoltage": -1.0,
  "endVoltage":    1.0,
  "stepHeight":    0.01,
  "stepTime":      100,
  "pulseHeight":   0.05,
  "pulseWidth":    500
}
```
Response: `{"status":"dpv_started"}`

#### Stream data
```http
GET /dpvdata
```
Responses mirror CV: `{"x":...,"y":...}` | `{"status":"waiting"}` | `{"status":"dpv_done"}`

---

### Amperometry (AMP)

#### Start
```http
POST /amp
Content-Type: application/json

{
  "oxidationPotential": 0.0,
  "runTime":            100,
  "measureInterval":    100
}
```
`runTime` and `measureInterval` are in **milliseconds**.  
Response: `{"status":"amp_started"}`

#### Stream data
```http
GET /ampdata
```
Responses: `{"x":1,"y":0.00312}` (x = time s, y = current µA) | `{"status":"waiting"}` | `{"status":"amp_done"}`

---

## Built-in Analytes

| Analyte | Code | Ox. Potential | Normal Range | Conv. Factor |
|---|---|---|---|---|
| Bilirubin | BIL | 0.15 V | 0.1 - 1.2 mg/dL | 17.1 µmol/L per mg/dL |
| ALP | ALP | 0.25 V | 44 – 147 mg/dL | - |
| ALT | ALT | 0.30 V | 7 – 56 mg/dL | - |
| AST | AST | 0.27 V | 10 – 40 mg/dL | - |
| Phosphorus | PHO | 0.22 V | 2.5 – 4.5 mg/dL | 0.32 µmol/L |
| Albumin | ALB | 0.18 V | 3.5 – 5.0 mg/dL | 150 µmol/L |
| Ascorbic Acid | ASC | 0.20 V | 0.4 – 1.5 mg/dL | 56.78 µmol/L |

Calibration constants (`calibSlope`, `calibConstant`) are shared defaults. Update them per instrument after running a calibration sweep.

Custom analytes can be added in the app (tap **+** on the analyte page) and are saved to device storage via SharedPreferences.

---

## CV Calibration & Analysis

The **Analysis** page (accessible from the options screen) allows you to build a calibration curve from multiple CV runs:

1. Run CV tests at several known concentrations.
2. For each run, download the CSV and name it `cv_data_<concentration>.csv`  
   (e.g. `cv_data_0_5.csv` → 0.5 µM; underscores become decimal points).
3. In the Analysis page, enter the **voltage** and **cycle number** to extract the peak current from each file.
4. Tap **Upload CSV Files** and select all calibration CSVs.
5. The app plots current vs. concentration, fits a least-squares regression, and reports **slope**, **intercept**, and **R²**.
6. Tap **Save as JPG** to export the chart.

Copy the fitted slope and intercept into `calibSlope` / `calibConstant` for a given analyte to enable quantitative diagnostics.

---

## Extending the Platform

### Add a new analyte (app only)
Tap **+** on the Analyte page and fill in the form. The analyte is persisted across sessions.

To add a default analyte that ships with the app, append it to `_defaultAnalytes` in `lib/analyte_constants.dart`.

### Add a new test endpoint (firmware)
1. Declare new global state variables in `healthSense.ino`.
2. Implement the step engine in a new `mymode.ino` file.
3. Add route handlers in `routes.ino`.
4. Dispatch in `loop()` (in `healthSense.ino`) and in `handleTouch()` (in `touch_handler.ino`).

### Add a new app config screen
Subclass the existing pattern: create `mymode_config_page.dart` that builds a list of `VoltConfigField` objects and passes them to `VoltConfigPage`. The generic page handles validation, HTTP POST, and loading state automatically.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| "No response from 192.168.4.1" | Phone not on BioAMP WiFi | Connect to **BioAMP** (password `bioamp123`) first |
| Device found but test never starts | Serial timeout / firmware hung | Reset Arduino; check Serial Monitor for errors |
| Data stream stops mid-test | 5 s HTTP timeout exceeded | Reduce polling interval or increase firmware step time |
| CSV has mismatched x/y lengths | Race condition during export | Fixed in current version (snapshot taken before export) |
| Analysis page shows NaN R² | All current values identical | Verify calibration CSVs contain variation; check sensor connections |
| "Chart not ready" on JPG export | Widget not yet rendered | Scroll chart into view before tapping Save |
| Analyte result is wildly off | Wrong `calibSlope`/`calibConstant` | Run a calibration sweep and update values in the app |
| `flutter run` fails | Missing dependencies | Run `flutter pub get`; confirm Flutter ≥ 3.7 (`flutter --version`) |

---

## License

MIT License - see [LICENSE](LICENSE) for details.

---

*For commit history and releases, see the [GitHub repository](https://github.com/Shash976/bio-amp).*
