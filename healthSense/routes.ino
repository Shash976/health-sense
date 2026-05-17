// routes.ino — HTTP endpoint handlers.

void handleWhoAmI(WiFiClient& client) {
  respondJSON(client, "{\"name\":\"BioAMP\"}");
}

void handleGetResult(WiFiClient& client) {
  if (resultReady) {
    double val = result;
    result = 0.0;
    resultReady = false;
    processing = false;
    processingStarted = false;
    respondJSON(client, "{\"value\":" + String(val, 2) + "}");
  } else if (processing || processingStarted) {
    respondJSON(client, "{\"status\":\"processing\"}");
  } else {
    respondJSON(client, "{\"status\":\"not_started\"}");
  }
}

void handlePostTest(WiFiClient& client) {
  int len = getContentLength(client);
  if (len <= 0) {
    respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid Content-Length\"}", 400);
    return;
  }
  String body = readRequestBody(client, len);
  StaticJsonDocument<256> doc;
  if (deserializeJson(doc, body)) {
    respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid JSON\"}", 400);
    return;
  }

  analyte.name              = (const char*)doc["task"];
  analyte.oxidationPotential = doc["oxidationPotential"].as<float>();
  analyte.normalMin_mgdL    = doc["normalMinMGDL"].as<float>();
  analyte.normalMax_mgdL    = doc["normalMaxMGDL"].as<float>();
  analyte.conversionFactor  = doc["conversionFactor"].as<float>();
  analyte.voltageGenTime    = doc["time"].as<unsigned long>();
  analyte.calibSlope        = doc["calibSlope"].as<float>();
  analyte.calibConstant     = doc["calibConstant"].as<float>();

  result = 0.0;
  resultReady = false;
  processing = true;
  processingStarted = true;
  currentMode = ANALYTE;

  respondJSON(client, "{\"status\":\"started\"}");
}

void handleCV(WiFiClient& client) {
  int len = getContentLength(client);
  if (len <= 0) {
    respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid Content-Length\"}", 400);
    return;
  }
  String body = readRequestBody(client, len);
  StaticJsonDocument<256> doc;
  if (deserializeJson(doc, body)) {
    respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid JSON\"}", 400);
    return;
  }

  START_VOLTAGE = (float)doc["startVoltage"] + V_SHIFT;
  END_VOLTAGE   = (float)doc["endVoltage"]   + V_SHIFT;
  SCAN_RATE     = doc["scanRate"];
  NUM_CYCLES    = doc["cycles"];

  cvRequested = true;
  currentMode = CV;
  drawGraphAxes();
  respondJSON(client, "{\"status\":\"cv_started\"}");
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

void handleDPV(WiFiClient& client) {
  int len = getContentLength(client);
  if (len <= 0) {
    respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid Content-Length\"}", 400);
    return;
  }
  String body = readRequestBody(client, len);
  StaticJsonDocument<256> doc;
  if (deserializeJson(doc, body)) {
    respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid JSON\"}", 400);
    return;
  }

  START_VOLTAGE = (float)doc["startVoltage"] + V_SHIFT;
  END_VOLTAGE   = (float)doc["endVoltage"]   + V_SHIFT;
  STEP_HEIGHT   = doc["stepHeight"]  | 0.01f;
  PULSE_HEIGHT  = doc["pulseHeight"] | 0.05f;
  PULSE_WIDTH   = doc["pulseWidth"]  | 500;
  STEP_TIME     = doc["stepTime"]    | 100;

  dpvRequested = true;
  currentMode = DPV;
  drawGraphAxes();
  respondJSON(client, "{\"status\":\"dpv_started\"}");
}

void handleDPVData(WiFiClient& client) {
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

void handleAmp(WiFiClient& client) {
  int len = getContentLength(client);
  if (len <= 0) {
    respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid Content-Length\"}", 400);
    return;
  }
  String body = readRequestBody(client, len);
  StaticJsonDocument<256> doc;
  if (deserializeJson(doc, body)) {
    respondJSON(client, "{\"status\":\"error\",\"message\":\"invalid JSON\"}", 400);
    return;
  }

  OX_POTENTIAL     = doc["oxidationPotential"] | 0.1f;
  AMP_RUN_TIME     = doc["runTime"];
  MEASURE_INTERVAL = doc["measureInterval"] | 150;

  ampRequested = true;
  currentMode = AMPEROMETRY;
  drawGraphAxes();
  respondJSON(client, "{\"status\":\"amp_started\"}");
}

void handleAmpData(WiFiClient& client) {
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
