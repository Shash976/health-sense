#pragma once
#include <Arduino.h>

struct Analyte {
  String name;
  float oxidationPotential;
  float normalMin_mgdL;
  float normalMax_mgdL;
  float conversionFactor;
  unsigned long voltageGenTime;
  float calibSlope;
  float calibConstant;
};

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
