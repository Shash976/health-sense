// display_ui.ino — TFT drawing functions and shared rendering utilities.

float mapFloat(float x, float in_min, float in_max, float out_min, float out_max) {
  return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

void waitForTouchRelease() {
  while (ts.touched()) delay(10);
  delay(100);
}

void drawWelcomeScreen() {
  tft.fillScreen(ILI9341_WHITE);

  tft.fillRoundRect(3, 5, 235, 30, 8, ILI9341_ORANGE);
  tft.setTextColor(ILI9341_BLACK);
  tft.setTextSize(2);
  tft.setCursor(45, 12);
  tft.print("Health-Sense");

  int logoX = (tft.width() - LOGO_WIDTH) / 2;
  tft.drawRGBBitmap(logoX, 40, logoBitmap, LOGO_WIDTH, LOGO_HEIGHT);

  tft.fillRoundRect(5, 185, 230, 60, 6, ILI9341_LIGHTGREY);
  tft.setTextColor(ILI9341_BLACK);
  tft.setTextSize(1);
  tft.setCursor(10, 193); tft.print("Connect phone to Wi-Fi:");
  tft.setTextSize(2);
  tft.setCursor(10, 205); tft.print(AP_SSID);
  tft.setTextSize(1);
  tft.setCursor(10, 225); tft.print("Password: "); tft.print(AP_PASSWORD);
  tft.setCursor(10, 237); tft.print("IP: 192.168.4.1");

  tft.fillRoundRect(15, 258, 100, 45, 8, ILI9341_BLUE);
  tft.setTextColor(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.setCursor(30, 272); tft.print("Demo");

  tft.fillRoundRect(125, 258, 100, 45, 8, ILI9341_GREEN);
  tft.setTextColor(ILI9341_BLACK);
  tft.setTextSize(2);
  tft.setCursor(140, 272); tft.print("Start");

  Serial.println("Welcome screen drawn");
}

void drawGraphAxes() {
  tft.fillScreen(ILI9341_WHITE);
  tft.drawRect(graphX, graphY, graphWidth, graphHeight, ILI9341_BLACK);

  tft.setTextSize(2);
  tft.setTextColor(ILI9341_BLACK);
  tft.setCursor(5, 5);
  if      (currentMode == CV)          tft.print("CV: I (uA) vs V (mV)");
  else if (currentMode == DPV)         tft.print("DPV: I (uA) vs V (mV)");
  else if (currentMode == AMPEROMETRY) tft.print("AMP: I (uA) vs Time (s)");

  if (currentMode == DPV || currentMode == CV) {
    int yTicks[] = {1000, 500, 0, -500, -1000};
    for (int i = 0; i < 5; i++) {
      int uA = yTicks[i];
      int yPos = mapFloat(uA, 1000, -1000, graphY, graphY + graphHeight);
      tft.drawFastHLine(graphX - 3, yPos, 3, ILI9341_BLACK);
      tft.drawFastHLine(graphX, yPos, graphWidth, ILI9341_LIGHTGREY);
      tft.setTextSize(1);
      if (uA == 0) {
        tft.setTextColor(ILI9341_BLUE);
        tft.setCursor(3, yPos - 4); tft.print("  0");
        tft.setTextColor(ILI9341_BLACK);
      } else {
        tft.setCursor(0, yPos - 4); tft.print(uA);
      }
    }
    float xVolts[] = {-1.0, -0.5, 0.0, 0.5, 1.0};
    for (int i = 0; i < 5; i++) {
      float v = xVolts[i];
      int xPos = mapFloat(v, -1.0, 1.0, graphX, graphX + graphWidth);
      tft.drawFastVLine(xPos, graphY + graphHeight, 3, ILI9341_BLACK);
      tft.drawFastVLine(xPos, graphY, graphHeight, ILI9341_LIGHTGREY);
      tft.setTextSize(1);
      tft.setCursor(xPos - 8, graphY + graphHeight + 5);
      tft.print(v, 1); tft.print("V");
    }
  } else {
    for (int uA = 1000; uA >= -1000; uA -= 500) {
      int y = mapFloat(uA, 1000, -1000, graphY, graphY + graphHeight);
      tft.drawFastHLine(graphX, y, graphWidth, ILI9341_LIGHTGREY);
      tft.setTextSize(1);
      tft.setCursor(0, y - 4); tft.print(uA);
    }
    for (int i = 0; i <= AMP_RUN_TIME; i += AMP_RUN_TIME / 4) {
      int x = map(i, 0, AMP_RUN_TIME, graphX, graphX + graphWidth);
      tft.drawFastVLine(x, graphY, graphHeight, ILI9341_LIGHTGREY);
      tft.setCursor(x - 5, graphY + graphHeight + 2); tft.print(i);
    }
  }

  tft.fillRoundRect(0, 280, 80, 40, 8, ILI9341_ORANGE);
  tft.setCursor(15, 295); tft.setTextColor(ILI9341_WHITE); tft.print("HOME");

  tft.fillRoundRect(160, 280, 80, 40, 8, ILI9341_RED);
  tft.setCursor(180, 295); tft.setTextColor(ILI9341_WHITE); tft.print("STOP");

  axesDrawn = true;
}

void drawGeneralOptionsScreen() {
  tft.fillScreen(ILI9341_WHITE);
  tft.setTextColor(ILI9341_BLACK);
  tft.setTextSize(2);
  tft.setCursor(10, 20); tft.print("Select Option:");

  tft.fillRoundRect(20, 70,  200, 50, 8, ILI9341_CYAN);
  tft.setCursor(40, 88); tft.setTextColor(ILI9341_BLACK); tft.print("Voltammetry");

  tft.fillRoundRect(20, 135, 200, 50, 8, ILI9341_GREEN);
  tft.setCursor(35, 153); tft.setTextColor(ILI9341_WHITE); tft.print("Analyte Test");

  tft.fillRoundRect(20, 200, 200, 50, 8, ILI9341_RED);
  tft.setCursor(80, 218); tft.setTextColor(ILI9341_WHITE); tft.print("Exit");
}

void drawVoltammetryOptionsScreen() {
  tft.fillScreen(ILI9341_WHITE);
  tft.setTextColor(ILI9341_BLACK);
  tft.setTextSize(2);
  tft.setCursor(10, 20); tft.print("Select Option:");

  tft.fillRoundRect(20, 60, 200, 60, 8, ILI9341_BLUE);
  tft.setTextColor(ILI9341_WHITE);
  tft.setCursor(25, 65);  tft.print("Cyclic");
  tft.setCursor(25, 85);  tft.print("Voltammetry");
  tft.setCursor(25, 100); tft.print("(CV)");

  tft.fillRoundRect(20, 130, 200, 80, 8, ILI9341_CYAN);
  tft.setTextColor(ILI9341_BLACK);
  tft.setCursor(25, 135); tft.print("Differential ");
  tft.setCursor(25, 155); tft.print("Pulse");
  tft.setCursor(25, 170); tft.print("Voltammetry");
  tft.setCursor(25, 190); tft.print("(DPV)");

  tft.fillRoundRect(20, 220, 200, 40, 8, ILI9341_ORANGE);
  tft.setCursor(45, 230); tft.setTextColor(ILI9341_WHITE); tft.print("Amperometry");

  tft.fillRoundRect(20, 265, 200, 35, 8, ILI9341_RED);
  tft.setCursor(85, 275); tft.setTextColor(ILI9341_WHITE); tft.print("Exit");
}

void waitForParametersScreen(String type) {
  tft.fillScreen(ILI9341_WHITE);
  tft.setTextColor(ILI9341_BLACK);
  tft.setTextSize(2);
  tft.setCursor(10, 120); tft.print("Waiting for ");
  tft.setCursor(10, 150); tft.print(type + " params...");

  tft.fillRoundRect(60, 200, 120, 40, 10, ILI9341_RED);
  tft.setCursor(80, 215); tft.setTextColor(ILI9341_WHITE); tft.print("Back");
}

void drawAnalyteDemoMenu(int page) {
  tft.fillScreen(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.setTextColor(ILI9341_DARKCYAN);
  tft.setCursor(10, 10); tft.print("Select Tests");

  int startIdx = page * 4;
  int endIdx = min(startIdx + 4, NUM_ANALYTES);

  for (int i = startIdx; i < endIdx; i++) {
    int y = 40 + (i - startIdx) * 60;
    tft.setCursor(10, y); tft.setTextColor(ILI9341_BLACK); tft.print(ANALYTE_TABLE[i].name);
    tft.fillRoundRect(150, y, 80, 35, 6, ILI9341_NAVY);
    tft.drawRoundRect(150, y, 80, 35, 6, ILI9341_CYAN);
    tft.setCursor(170, y + 12); tft.setTextColor(ILI9341_WHITE); tft.print("Test");
  }

  if (page > 0) {
    tft.fillRoundRect(0, 280, 80, 40, 5, ILI9341_ORANGE);
    tft.setCursor(25, 295); tft.setTextColor(ILI9341_WHITE); tft.print("<");
  }
  tft.fillRoundRect(80, 280, 80, 40, 5, ILI9341_DARKGREEN);
  tft.setCursor(95, 295); tft.setTextColor(ILI9341_WHITE); tft.print("Home");
  if ((page + 1) * 4 < NUM_ANALYTES) {
    tft.fillRoundRect(160, 280, 80, 40, 5, ILI9341_ORANGE);
    tft.setCursor(210, 295); tft.setTextColor(ILI9341_WHITE); tft.print(">");
  }
}

void drawDemoInputScreen() {
  tft.fillScreen(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.setTextColor(ILI9341_BLACK);

  if (currentMode == CV) {
    tft.setCursor(10, 20);  tft.print("CV Potentiostat");
    tft.setCursor(10, 60);  tft.print("Start V: "); tft.print(START_VOLTAGE - V_SHIFT, 2);
    tft.setCursor(10, 90);  tft.print("Peak V:  "); tft.print(END_VOLTAGE - V_SHIFT, 2);
    tft.setCursor(10, 120); tft.print("Scan Rate: "); tft.print(SCAN_RATE, 2);
    tft.setCursor(10, 150); tft.print("Cycles: "); tft.print(NUM_CYCLES);
  } else if (currentMode == DPV) {
    tft.setCursor(10, 20);  tft.print("DPV Potentiostat");
    tft.setCursor(10, 60);  tft.print("Start V: "); tft.print(START_VOLTAGE - V_SHIFT, 2);
    tft.setCursor(10, 90);  tft.print("End V:   "); tft.print(END_VOLTAGE - V_SHIFT, 2);
    tft.setCursor(10, 120); tft.print("Step H: "); tft.print(STEP_HEIGHT, 2);
    tft.setCursor(10, 150); tft.print("Pulse H: "); tft.print(PULSE_HEIGHT, 2);
    tft.setCursor(10, 180); tft.print("Step T: "); tft.print(STEP_TIME);
    tft.setCursor(10, 210); tft.print("Pulse W: "); tft.print(PULSE_WIDTH);
  } else if (currentMode == AMPEROMETRY) {
    tft.setCursor(10, 20); tft.print("Amperometry");
    tft.setCursor(10, 60); tft.print("Ox. Pot: "); tft.print(OX_POTENTIAL, 2);
    tft.setCursor(10, 90); tft.print("Run Time: "); tft.print(AMP_RUN_TIME); tft.print("s");
  }

  tft.fillRoundRect(60, 260, 120, 40, 10, ILI9341_GREEN);
  tft.setTextColor(ILI9341_WHITE);
  tft.setCursor(90, 275); tft.print("START");
}

void plotPoint(float xVal, float current_uA) {
  float xNorm;
  if (currentMode == CV || currentMode == DPV) {
    xNorm = mapFloat(xVal, START_VOLTAGE, END_VOLTAGE, 0, graphWidth - 1);
  } else if (currentMode == AMPEROMETRY) {
    xNorm = mapFloat(xVal, 0, AMP_RUN_TIME, 0, graphWidth - 1);
  } else {
    return;
  }

  float yNorm = mapFloat(current_uA, -1000, 1000, graphHeight - 1, 0);
  int x = graphX + (int)xNorm;
  int y = graphY + (int)yNorm;

  if (x >= graphX && x < graphX + graphWidth && y >= graphY && y < graphY + graphHeight) {
    uint16_t color = (currentMode == AMPEROMETRY) ? ILI9341_BLUE : ILI9341_RED;
    tft.drawPixel(x, y, color);
  } else {
    Serial.print("Point OOB: "); Serial.print(x); Serial.print(","); Serial.println(y);
  }
}

void showDone() {
  tft.setTextSize(2);
  tft.setTextColor(ILI9341_GREEN);
  tft.setCursor(20, 255);
  tft.print("Measurement Done");
}
