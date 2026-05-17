// dpv_mode.ino — Differential Pulse Voltammetry step engine.

void startDPV() {
  dpvVoltage = START_VOLTAGE;
  dpvRunning = true;
  currentCurrent = 0;
  Serial.println("DPV started");
  Serial.print("  Start: "); Serial.println(START_VOLTAGE);
  Serial.print("  End:   "); Serial.println(END_VOLTAGE);
  Serial.print("  Step:  "); Serial.println(STEP_HEIGHT);
  Serial.print("  StepT: "); Serial.println(STEP_TIME);
  Serial.print("  Pulse: "); Serial.println(PULSE_HEIGHT);
  Serial.print("  PulseW:"); Serial.println(PULSE_WIDTH);
}

void performDPVStep() {
  dac.setVoltage(voltageToDAC(dpvVoltage), false);
  delay(STEP_TIME);

  float before_mV = averageADCReading();

  dac.setVoltage(voltageToDAC(dpvVoltage + PULSE_HEIGHT), false);
  delay(PULSE_WIDTH);

  float after_mV = averageADCReading();

  float diff_mA = (after_mV - before_mV) / 1000.0;

  currentCurrent = diff_mA * 1000.0; // convert to uA
  currentVoltage = dpvVoltage - V_SHIFT;
  newDPVPointAvailable = true;

  plotPoint(dpvVoltage, currentCurrent);

  Serial.print("DPV V="); Serial.print(dpvVoltage - V_SHIFT, 2);
  Serial.print(" I="); Serial.print(diff_mA, 6); Serial.println(" mA");

  dpvVoltage += (START_VOLTAGE < END_VOLTAGE) ? STEP_HEIGHT : -STEP_HEIGHT;
}

int voltageToDAC(float voltage) {
  return (int)((voltage / V_REF) * DAC_RESOLUTION);
}

float averageADCReading() {
  const int N = 10;
  long sum = 0;
  for (int i = 0; i < N; i++) {
    sum += ads.readADC_SingleEnded(0);
    delay(1);
  }
  return (sum / (float)N) * ADS_GAIN;
}
