// cv_mode.ino — Cyclic Voltammetry step engine.

void startCV() {
  STEP_TIME = 10; // fixed 10 ms per step
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
  if (millis() - lastStepTime < (unsigned long)STEP_TIME) return;
  lastStepTime = millis();

  float v = sweepingForward
    ? START_VOLTAGE + stepIndex * stepSize
    : END_VOLTAGE   - stepIndex * stepSize;

  int dacVal = (int)((v / V_REF) * DAC_RESOLUTION);
  dac.setVoltage(dacVal, false);

  int16_t adc = ads.readADC_SingleEnded(0) * -1;
  float mV = adc * ADS_GAIN;
  float current_uA = (mV / FEEDBACK_RESISTOR) / 1000.0;

  currentVoltage = v - V_SHIFT;
  currentCurrent = current_uA;
  newCVPointAvailable = true;

  plotPoint(v, current_uA);

  stepIndex++;
  if (stepIndex >= totalSteps) {
    stepIndex = 0;
    if (sweepingForward) {
      sweepingForward = false;
    } else {
      sweepingForward = true;
      currentCycle++;
      if (currentCycle >= NUM_CYCLES) cvRunning = false;
    }
  }
}

// Returns the voltage increment per step (helper, currently unused in loop but
// kept for diagnostics / future use).
float scanStepSize() {
  float totalTime = abs(END_VOLTAGE - START_VOLTAGE) / SCAN_RATE;
  int steps = totalTime * 1000.0 / STEP_TIME;
  return (END_VOLTAGE - START_VOLTAGE) / steps;
}
