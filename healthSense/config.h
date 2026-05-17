#pragma once

// --- Access Point credentials ---
#define AP_SSID     "BioAMP"
#define AP_PASSWORD "bioamp123"

// --- Pin Configuration ---
#define TFT_CS   10
#define TFT_DC    8
#define TFT_RST   9
#define TOUCH_CS  7
#define TOUCH_IRQ 255

// --- Screen ---
#define SCREEN_WIDTH  240
#define SCREEN_HEIGHT 320

// --- Hardware constants ---
#define V_REF             4.8
#define DAC_RESOLUTION    4095
#define ADS_GAIN          0.1875
#define FEEDBACK_RESISTOR 1000.0
