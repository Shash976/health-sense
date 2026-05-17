// analyte_mode.ino — Analyte test execution and result display.

void performTest(Analyte a) {
  tft.fillRect(60, 140, 120, 40, ILI9341_YELLOW);
  tft.setCursor(75, 150);
  tft.setTextColor(ILI9341_BLACK);
  tft.setTextSize(2);
  tft.print("Testing...");
  delay(800);

  Serial.print("Test: "); Serial.println(a.name);
  Serial.print("  Ox. Potential: "); Serial.println(a.oxidationPotential);
  Serial.print("  Normal range: ");
  Serial.print(a.normalMin_mgdL); Serial.print(" – "); Serial.println(a.normalMax_mgdL);

  // Apply oxidation potential (shifted to 0–2 V range for DAC).
  int dacVal = (int)(((a.oxidationPotential + 1.0) / V_REF) * DAC_RESOLUTION);
  dac.setVoltage(dacVal, false);
  delay(a.voltageGenTime);

  int16_t adc = ads.readADC_SingleEnded(0);
  float mV = adc * ADS_GAIN * 0.2;
  float current_mA = mV / FEEDBACK_RESISTOR;
  float current_uA = current_mA * 1000.0;
  float concentration = (current_uA - a.calibConstant) / a.calibSlope;

  result = concentration;
  resultReady = true;

  Serial.println("Test complete");
  showResult(a, concentration, current_mA);
}

void showResult(Analyte a, float mgdL, float current_mA) {
  tft.fillScreen(ILI9341_WHITE);

  tft.setTextSize(2);
  tft.setTextColor(ILI9341_DARKCYAN);
  tft.setCursor(10, 10); tft.print("Result: "); tft.print(a.name);

  tft.setCursor(10, 40);
  tft.setTextSize(3);
  tft.setTextColor(ILI9341_BLACK);
  tft.print(mgdL, 2); tft.print(" mg/dL");

  tft.setTextSize(1);
  tft.setCursor(10, 80);
  if (a.conversionFactor > 0) {
    tft.setTextColor(ILI9341_DARKGREY);
    tft.print(mgdL * a.conversionFactor, 1); tft.print(" umol/L");
  }

  tft.setCursor(10, 110);
  tft.setTextColor(ILI9341_MAROON);
  tft.print("Current: "); tft.print(current_mA * 1000.0, 2); tft.print(" uA");

  tft.setCursor(10, 140);
  tft.setTextColor(ILI9341_BLUE);
  tft.print("Normal: ");
  tft.print(a.normalMin_mgdL); tft.print(" - "); tft.print(a.normalMax_mgdL); tft.print(" mg/dL");

  bool normal = mgdL >= a.normalMin_mgdL && mgdL <= a.normalMax_mgdL;
  tft.fillRoundRect(10, 180, 220, 30, 4, normal ? ILI9341_GREEN : ILI9341_RED);
  tft.setCursor(40, 188);
  tft.setTextColor(ILI9341_WHITE);
  tft.setTextSize(2);
  tft.print(normal ? "Level is Normal" : "Consult Doctor");

  tft.fillRoundRect(60, 285, 120, 40, 10, ILI9341_NAVY);
  tft.drawRoundRect(60, 285, 120, 40, 10, ILI9341_WHITE);
  tft.setCursor(100, 300); tft.setTextColor(ILI9341_WHITE); tft.print("Back");
}
