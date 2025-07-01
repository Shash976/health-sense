# Bio-AMP: Portable Biosensing System (Flutter + Arduino)

Bio-AMP is an integrated biosensing solution comprising a portable Arduino-based device for electrochemical analysis and a cross-platform Flutter application for intuitive user control, real-time data visualization, and result management. The system is intended for research and educational use in biosensing, clinical diagnostics, and point-of-care testing. It supports tests such as Cyclic Voltammetry (CV), Differential Pulse Voltammetry (DPV), Amperometry, and analyte-specific assays.

---

## Table of Contents

- [Project Overview](#project-overview)
- [System Architecture](#system-architecture)
- [Key Features](#key-features)
- [Hardware (Arduino) Details](#hardware-arduino-details)
  - [Supported Tests](#supported-tests)
  - [Touchscreen UI](#touchscreen-ui)
  - [WiFi Setup](#wifi-setup)
  - [REST API Endpoints](#rest-api-endpoints)
  - [Results Display](#results-display)
  - [Analyte Details](#analyte-details)
- [Flutter App Details](#flutter-app-details)
  - [Page-by-Page Breakdown](#page-by-page-breakdown)
  - [User Workflow Example: CV Test](#user-workflow-example-cv-test)
- [Communication Protocol & Detailed Flow](#communication-protocol--detailed-flow)
- [Project Structure](#project-structure)
- [Installation & Setup](#installation--setup)
  - [Hardware Setup](#hardware-setup)
  - [Arduino Firmware](#arduino-firmware)
  - [Flutter App](#flutter-app)
- [Extending the System](#extending-the-system)
- [Troubleshooting](#troubleshooting)
- [License](#license)
- [Acknowledgements](#acknowledgements)

---

## Project Overview

**Bio-AMP** bridges embedded hardware and mobile software to deliver a seamless biosensing platform. The Arduino device acquires, processes, and displays biosignal data, exposing a simple HTTP/JSON API over WiFi. The Flutter app provides a modern, user-friendly interface for remote configuration, test initiation, live monitoring, and results management.

---

## System Architecture

```
+-------------------------+        WiFi (HTTP/JSON)        +-------------------------+
|   Flutter Mobile App    |  <-------------------------->  |    Arduino Device       |
| (Android/iOS/desktop)   |                                | (bioAmp/bioAmp.ino)     |
+-------------------------+                                +-------------------------+
          |                                                         |
          |                USB/Serial (for programming)             |
          +---------------------------------------------------------+
```

- **Arduino Device**: Reads biosignals using analog front-end, performs electrochemical tests, hosts a touchscreen UI, and exposes a RESTful API over WiFi.
- **Flutter App**: Connects via WiFi, lets users configure and run tests, visualizes real-time data, and displays results.

---

## Key Features

- Portable, battery-powered biosensing hardware (Arduino-based).
- Intuitive touchscreen user interface on the device.
- WiFi connectivity for remote operation and mobile integration.
- Flexible, cross-platform Flutter app (Android, iOS, desktop).
- Real-time data acquisition and graphing.
- Supports CV, DPV, amperometry, and custom analyte assays.
- RESTful API for easy integration and extensibility.
- Local and remote (app-based) control.
- Secure WiFi credential management.

---

## Hardware (Arduino) Details

### Supported Tests

- **Cyclic Voltammetry (CV):** Measures current as a function of a linearly swept voltage.
- **Differential Pulse Voltammetry (DPV):** Enhanced sensitivity via pulse technique.
- **Amperometry:** Measures current at a fixed voltage over time.
- **Analyte-Specific Tests:** Predefined routines for substances such as Bilirubin, ALP, ALT, AST, Phosphorus, Albumin, and Ascorbic Acid.

### Touchscreen UI

The Arduino device features a full-color TFT touchscreen with a graphical menu system:

- **Welcome Screen:** Displays branding/logo; options for Demo or Get Started.
- **WiFi Setup:** Lists available WiFi networks; touchscreen keyboard for password input; “Forget WiFi” and “Exit” buttons.
- **Main Menu:** Access Voltammetry, Amperometry, Analyte Tests, WiFi Settings, or Exit.
- **Test Parameter Entry:** Enter or review test parameters for each mode.
- **Real-Time Graphs:** Live plotting of acquired data (I vs V or I vs Time).
- **Results Display:** Shows detailed results, reference ranges, and interpretation (“Normal”/“Consult Doctor”).
- **Navigation:** All screens support intuitive back, home, and action buttons.

### WiFi Setup

- Configurable via touchscreen.
- Credentials are securely stored in flash memory.
- Device automatically reconnects to known networks; manual override available.

### REST API Endpoints

#### Identification
- `GET /whoami`  
  Returns device name and version info.

#### Test Control
- `POST /cv`  
  Starts a CV test. Expects JSON parameters.
- `POST /dpv`  
  Starts a DPV test.
- `POST /amp`  
  Starts an amperometry test.
- `POST /test`  
  Starts an analyte test.

#### Live Data
- `GET /cvdata`  
  Returns latest CV data point or status.
- `GET /dpvdata`  
  Returns latest DPV data point.
- `GET /ampdata`  
  Returns latest amperometry data point.

#### Results
- `GET /result`  
  Returns final result of last test (value, status, etc).

#### Example API Payloads

```json
// Start CV Test
POST /cv
{
  "startVoltage": 0.0,
  "endVoltage": 2.0,
  "scanRate": 0.1,
  "cycles": 2
}
```

```json
// Live Data Point (CV)
GET /cvdata
{
  "x": 0.17,
  "y": 279.5
}
```

```json
// Final Result
GET /result
{
  "value": 0.91,
  "status": "normal"
}
```

### Results Display

- Real-time data is plotted on the device’s display as the test runs.
- After completion, results screen summarizes:
  - Test type and parameters
  - Measured value(s)
  - Reference range
  - Interpretation (normal/abnormal)
  - Option to return to menu or repeat test

### Analyte Details

- Built-in analyte presets (Bilirubin, ALP, ALT, etc.) with reference values.
- Can be extended for new analytes in code.

---

## Flutter App Details

### Page-by-Page Breakdown

1. **Welcome Page**
   - App logo, project name, and “Get Started” button.

2. **Login Page**
   - (Optional) User authentication. Username/password or skip.

3. **Device Discovery/Connection Page**
   - Scans for devices (via IP/mDNS) or allows manual entry.
   - Shows connection status, device info (from `/whoami`).

4. **Main Menu / Home Page**
   - Buttons for Voltammetry, Amperometry, Analyte Tests, Settings.
   - Device status and info display.

5. **Test Selection & Parameter Input**
   - User chooses test type (CV/DPV/Amperometry/Analyte).
   - Input forms for all relevant parameters (e.g., voltages, scan rate, cycles).
   - Descriptions and validation for each field.

6. **Live Data/Graph Page**
   - Real-time plotting of received data (e.g., I vs V for CV).
   - Progress indicators, STOP button, and status updates.

7. **Result / Summary Page**
   - Final data visualization.
   - Key result values and interpretation.
   - Export/share options (CSV/image, if implemented).

8. **Settings/Device Info**
   - Device firmware/version, WiFi configuration, change device.

---

### User Workflow Example: CV Test

1. **Launch app → Welcome Page → Tap “Get Started”.**
2. **Login (if enabled) → Device Discovery Page.**
3. **Connect to device → Main Menu.**
4. **Tap “Voltammetry” → Select “Cyclic Voltammetry (CV)”.**
5. **Enter parameters:**  
   - Start Voltage: 0.0 V  
   - End Voltage: 2.0 V  
   - Scan Rate: 0.1 V/s  
   - Cycles: 2  
   → Tap “Start Test”
6. **App sends POST `/cv` with parameters.**
7. **Device starts test; App switches to Live Data Page.**
8. **App polls `/cvdata` for new points, updating the graph in real time.**
9. **When test completes, device and app both display results.**
10. **App offers export/save, or user returns to Main Menu.**

---

## Communication Protocol & Detailed Flow

This section elaborates the full device/app communication cycle, including discovery, API usage, error handling, and real-time interaction.

### 1. Device Discovery and Scanning

- **mDNS/Bonjour (Recommended):**  
  - The Arduino can advertise itself on the network using mDNS (Multicast DNS) as `bioamp.local` or similar.  
  - The Flutter app scans for mDNS services on the local network.
  - When found, the app displays the device’s name and IP.
- **Manual Entry:**  
  - If mDNS is unavailable, the user can input the Arduino’s IP address manually (shown on the Arduino display after WiFi setup).

### 2. Initial Connection & Verification

- The app attempts a connection to the device by sending a `GET /whoami` request to the discovered IP.
- Device responds with its identity (`{ "name": "BioAMP", ... }`).
- If successful, the app stores this as the current device and enables further navigation.  
- Failed connections are handled gracefully, prompting the user to retry or select a different device/IP.

### 3. Test Session Initiation

- User selects a test and enters parameters in the app.
- The app sends a `POST` request to the relevant endpoint (`/cv`, `/dpv`, `/amp`, `/test`) with JSON parameters.
- The device parses the JSON, configures its hardware, and changes its UI to reflect test initiation.
- Device responds with a JSON status (`{ "status": "cv_started" }`, etc).
- If the device is busy or parameters are invalid, it responds with an error, which the app displays to the user.

### 4. Real-Time Data Streaming

- As the test executes, the device collects data points (e.g., voltage/current pairs for CV).
- The app enters a polling loop, regularly sending `GET` requests (e.g., `/cvdata`):
  - If new data is available, the device returns the latest point (`{ "x": ..., "y": ... }`).
  - If not ready, device returns `{ "status": "waiting" }` or similar.
  - If the test is complete, the device responds with `{ "status": "cv_done" }`.
  - The polling interval is tuned for smooth real-time updates without overloading the device/network.
- The app updates the graph in real time as each point arrives.

### 5. Test Control and Synchronization

- Both the app and device UI allow stopping/aborting the test.
- If the user presses STOP in the app:
  - The app sends a command to the device (if supported), or simply stops polling and informs the user.
- If the user stops the test on the device’s touchscreen, the device will return a “done” or “aborted” status at the next API poll, and the app updates accordingly.
- This ensures tight synchronization and robust error handling.

### 6. Results Retrieval

- After completion, the app fetches the summary result from `/result` (e.g., final value, interpretation).
- The results page displays the full data, stats, and any device-side interpretation (e.g., “Normal”, “Consult Doctor”).

### 7. Error Handling & Status Reporting

- The device always responds to API requests with a clear status and/or error message.
- The app displays connection/test errors, busy statuses, or API errors to the user and can retry, reset, or guide the user as needed.

### 8. Security and Network Considerations

- By default, the device API is open on the local network. If used in a sensitive environment, add local network restrictions or simple authentication.
- The app and device both display the current WiFi network and connection status for easy troubleshooting.

---

### Example: Full Communication Sequence (CV Test)

1. **Device advertises via mDNS as `bioamp.local`.**
2. **App scans and finds device.**
3. **App sends `GET http://bioamp.local/whoami` — verifies device.**
4. **User configures CV test in app; app sends:**
   ```
   POST http://bioamp.local/cv
   {
     "startVoltage": 0.0,
     "endVoltage": 2.0,
     "scanRate": 0.1,
     "cycles": 2
   }
   ```
5. **Device replies `{ "status": "cv_started" }` and begins test.**
6. **App enters polling loop:**
   - `GET /cvdata` → `{ "x": ..., "y": ... }` (data point)
   - Updates graph.
   - Repeat until `{ "status": "cv_done" }`
7. **App requests results: `GET /result` → `{ "value": ..., "status": ... }`**
8. **App displays summary to user.**
9. **User returns to main menu or configures next test.**

---

## Project Structure

```
bio-amp/
├── bioAmp/                  # Arduino firmware and related files
│   ├── bioAmp.ino           # Main Arduino sketch
│   └── logo_bitmap.h        # Logo for TFT display
├── lib/                     # Flutter app source code
│   ├── main.dart            # Flutter app entry point
│   ├── welcome.dart         # Welcome Page UI
│   ├── login.dart           # Login Page UI
│   └── ...                  # Other Dart files
├── android/                 # Android-specific Flutter project files
├── ios/                     # iOS-specific Flutter project files
├── pubspec.yaml             # Flutter dependencies and metadata
└── README.md                # (This file)
```

---

## Installation & Setup

### Hardware Setup

- Supported Arduino board (with WiFiNINA or compatible).
- Attach TFT display (ILI9341), XPT2046 touchscreen, DAC (MCP4725), ADC (ADS1115), and sensor interface as per schematics (not provided here).

### Arduino Firmware

1. Install Arduino IDE.
2. Install required libraries:
   - SPI, Wire, Adafruit_GFX, Adafruit_ILI9341, XPT2046_Touchscreen, Adafruit_MCP4725, Adafruit_ADS1X15, WiFiNINA, ArduinoJson, FlashStorage.
3. Open `bioAmp/bioAmp.ino` and upload to your board.
4. Power the device and follow on-screen instructions for WiFi setup.

### Flutter App

1. Install [Flutter SDK](https://flutter.dev/docs/get-started/install).
2. Clone this repo:  
   `git clone https://github.com/Shash976/bio-amp.git`
3. In the project root, get dependencies:  
   `flutter pub get`
4. Run the app:  
   `flutter run`
5. Connect to the same WiFi network as the device.

---

## Extending the System

- **To add new tests or analytes:**  
  Update the analyte array and routines in `bioAmp.ino`.
- **To support new data visualizations:**  
  Extend the Flutter app with new UI/graph widgets.
- **To add security:**  
  Implement API key or local network whitelisting on the Arduino.

---

## Troubleshooting

- **Device not found:** Ensure Arduino and phone are on the same WiFi network.
- **API errors:** Check serial monitor on Arduino for error logs.
- **WiFi setup fails:** Use “Forget WiFi” on device to reset credentials.
- **App crashes:** Run `flutter doctor` to check your environment.

---

## License

[MIT](LICENSE)

---

## Acknowledgements

- Inspired by open-source biosensing research and portable diagnostics.
- Built using Flutter, Arduino, Adafruit, and community libraries.
- Special thanks to all contributors and testers.

---

For detailed circuit diagrams, advanced use, or contributions, please open an issue or pull request on [GitHub](https://github.com/Shash976/bio-amp).
