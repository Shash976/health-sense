// amp_mode.ino — Amperometric titration step engine.

void startAmp() {
  ampIndex = 0;
  ampCurrent = 0.0;
  ampTime = 0;
  ampSteps = AMP_RUN_TIME * 1000 / MEASURE_INTERVAL;
  int dacVal = (int)(((OX_POTENTIAL + 1.0) / V_REF) * DAC_RESOLUTION);
  dac.setVoltage(dacVal, false);
  ampRunning = true;
  Serial.println("AMP started");
}

void ampStep() {
  int16_t adc = ads.readADC_SingleEnded(0);
  float mV = adc * ADS_GAIN;
  float current_uA = (mV / FEEDBACK_RESISTOR) / 1000.0;
  float time_s = ampIndex * MEASURE_INTERVAL / 1000.0;

  ampCurrent = current_uA;
  ampTime = (int)time_s;
  plotPoint(time_s, current_uA);
  newAmpPointAvailable = true;

  delay(MEASURE_INTERVAL);
}
