// touch_handler.ino — Touch event dispatch for each Mode.
// Called once per loop() iteration.

void handleTouch() {
  if (!ts.touched()) return;

  TS_Point p = ts.getPoint();
  pinMode(TOUCH_CS, OUTPUT);
  digitalWrite(TOUCH_CS, HIGH);

  int x, y;
  Serial.println(currentMode);

  if (currentMode == WELCOME) {
    TS_MINX = 732; TS_MAXX = 3379; TS_MINY = 624; TS_MAXY = 3135;
    x = map(p.x, TS_MAXX, TS_MINX, 0, SCREEN_WIDTH);
    y = map(p.y, TS_MAXY, TS_MINY, 0, SCREEN_HEIGHT);

    if (x >= 125 && x <= 225 && y >= 258 && y <= 303) {
      demoMode = false;
      drawGeneralOptionsScreen();
      currentMode = OPTIONS;
    } else if (x >= 15 && x <= 115 && y >= 258 && y <= 303) {
      demoMode = true;
      drawGeneralOptionsScreen();
      currentMode = OPTIONS;
    }

  } else if (currentMode == OPTIONS) {
    TS_MINX = 329; TS_MAXX = 3835; TS_MINY = 530; TS_MAXY = 3800;
    x = map(p.x, TS_MAXX, TS_MINX, 0, SCREEN_WIDTH);
    y = map(p.y, TS_MAXY, TS_MINY, 0, SCREEN_HEIGHT);
    Serial.print("OPTIONS x="); Serial.print(x); Serial.print(" y="); Serial.println(y);

    if (x > 20 && x < 220) {
      if (y > 70 && y < 120) {
        drawVoltammetryOptionsScreen();
        currentMode = V_OPTIONS;
      } else if (y > 135 && y < 185) {
        if (demoMode) drawAnalyteDemoMenu(analyteCurrentPage);
        currentMode = ANALYTE;
      } else if (y > 200 && y < 250) {
        drawWelcomeScreen();
        currentMode = WELCOME;
      }
    }

  } else if (currentMode == V_OPTIONS) {
    TS_MINX = 329; TS_MAXX = 3835; TS_MINY = 530; TS_MAXY = 3800;
    x = map(p.x, TS_MAXX, TS_MINX, 0, SCREEN_WIDTH);
    y = map(p.y, TS_MAXY, TS_MINY, 0, SCREEN_HEIGHT);
    Serial.print("V_OPTIONS x="); Serial.print(x); Serial.print(" y="); Serial.println(y);

    if (x > 20 && x < 220) {
      if (y > 60 && y < 120) {
        currentMode = CV;
        if (demoMode) {
          START_VOLTAGE = 0.0 + V_SHIFT;
          END_VOLTAGE   = 2.0;
          SCAN_RATE = 0.1;
          NUM_CYCLES = 2;
          drawDemoInputScreen();
        }
      } else if (y > 130 && y < 190) {
        currentMode = DPV;
        if (demoMode) {
          STEP_HEIGHT  = 0.01; PULSE_HEIGHT = 0.05; PULSE_WIDTH = 500; STEP_TIME = 100;
          START_VOLTAGE = 0.0; END_VOLTAGE = 2.0;
          drawDemoInputScreen();
        }
      } else if (y > 210 && y < 250) {
        currentMode = AMPEROMETRY;
        if (demoMode) {
          OX_POTENTIAL = 0.5; AMP_RUN_TIME = 10;
          drawDemoInputScreen();
        }
      } else if (y > 255 && y < 290) {
        drawGeneralOptionsScreen();
        currentMode = OPTIONS;
      }
    }

  } else if (currentMode == CV) {
    TS_MINX = 732; TS_MAXX = 3379; TS_MINY = 624; TS_MAXY = 3135;
    x = map(p.x, TS_MINX, TS_MAXX, 0, tft.width());
    y = map(p.y, TS_MAXY, TS_MINY, 0, tft.height());

    if (!cvRunning && !cvRequested && !axesDrawn) {
      if (demoMode) {
        if (x > 60 && x < 180 && y > 260 && y < 300) {
          cvRequested = true;
          drawGraphAxes();
        }
      } else {
        waitForParametersScreen("CV");
        currentMode = PARAM;
      }
    } else if (!axesDrawn && x > 0 && x < 80 && y > 280 && y < 320) {
      rerunRequested = true;
      cvRunning = false;
    }
    if (axesDrawn && x > 160 && x < 240 && y > 280 && y < 320) {
      rerunRequested = false;
      cvRunning = false; cvRequested = false;
      axesDrawn = false;
      drawGeneralOptionsScreen();
      currentMode = OPTIONS;
    }

  } else if (currentMode == DPV) {
    TS_MINX = 732; TS_MAXX = 3379; TS_MINY = 624; TS_MAXY = 3135;
    x = map(p.x, TS_MINX, TS_MAXX, 0, tft.width());
    y = map(p.y, TS_MAXY, TS_MINY, 0, tft.height());

    if (!dpvRunning && !dpvRequested && !axesDrawn) {
      if (demoMode) {
        if (x > 60 && x < 180 && y > 260 && y < 300) {
          dpvRequested = true;
          drawGraphAxes();
        }
      } else {
        waitForParametersScreen("DPV");
        currentMode = PARAM;
      }
    }
    if (axesDrawn && !dpvRunning && !dpvRequested && x > 160 && x < 240 && y > 280 && y < 320) {
      dpvRunning = false;
      axesDrawn = false;
      drawGeneralOptionsScreen();
      currentMode = OPTIONS;
    }

  } else if (currentMode == AMPEROMETRY) {
    TS_MINX = 732; TS_MAXX = 3379; TS_MINY = 624; TS_MAXY = 3135;
    x = map(p.x, TS_MINX, TS_MAXX, 0, tft.width());
    y = map(p.y, TS_MAXY, TS_MINY, 0, tft.height());

    if (axesDrawn && !ampRunning && !ampRequested && x > 160 && x < 240 && y > 280 && y < 320) {
      ampRunning = false;
      axesDrawn = false;
      drawGeneralOptionsScreen();
      currentMode = OPTIONS;
    } else if (!ampRunning && !ampRequested && !axesDrawn) {
      if (demoMode) {
        if (x > 60 && x < 180 && y > 260 && y < 300) {
          ampRequested = true;
          drawGraphAxes();
        }
      } else {
        waitForParametersScreen("Amperometry");
        currentMode = PARAM;
      }
    }

  } else if (currentMode == ANALYTE || currentMode == ANALYTE_PAGE) {
    TS_MINX = 732; TS_MAXX = 3379; TS_MINY = 624; TS_MAXY = 3135;
    x = map(p.x, TS_MINX, TS_MAXX, 0, tft.width());
    y = map(p.y, TS_MAXY, TS_MINY, 0, tft.height());

    if (demoMode) {
      if (y > 280 && y < 320) {
        if (x >= 0 && x < 80 && analyteCurrentPage == 0) {
          analyteCurrentPage++;
          drawAnalyteDemoMenu(analyteCurrentPage);
          waitForTouchRelease();
          return;
        } else if (x >= 160 && x < 240 && analyteCurrentPage > 0) {
          analyteCurrentPage--;
          drawAnalyteDemoMenu(analyteCurrentPage);
          waitForTouchRelease();
          return;
        } else if (x >= 80 && x < 160) {
          if (currentMode == ANALYTE) {
            drawGeneralOptionsScreen();
            currentMode = OPTIONS;
          } else {
            drawAnalyteDemoMenu(analyteCurrentPage);
            currentMode = ANALYTE;
          }
          return;
        }
      }
      // Test buttons
      int startIdx = analyteCurrentPage * 4;
      int endIdx = min(startIdx + 4, NUM_ANALYTES);
      for (int i = startIdx; i < endIdx; i++) {
        int yBtn = -35 + (i - startIdx) * 70;
        if (x >= -5 && x <= 100 && y >= yBtn && y <= yBtn + 40) {
          waitForTouchRelease();
          performTest(ANALYTE_TABLE[i]);
          currentMode = ANALYTE_PAGE;
          break;
        }
      }
      delay(300);
    } else {
      if (!processing && !processingStarted) {
        waitForParametersScreen("Analyte");
        currentMode = PARAM;
      }
    }

  } else if (currentMode == PARAM) {
    TS_MINX = 329; TS_MAXX = 3835; TS_MINY = 530; TS_MAXY = 3800;
    x = map(p.x, TS_MINX, TS_MAXX, 0, tft.width());
    y = map(p.y, TS_MINY, TS_MAXY, 0, tft.height());
    if (x >= 60 && x <= 180 && y >= 80 && y <= 90) {
      drawGeneralOptionsScreen();
      currentMode = OPTIONS;
    }

  } else {
    currentMode = OPTIONS;
  }
}
