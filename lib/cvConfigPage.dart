import 'package:bio_amp/voltConfigPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CVConfigPage extends StatelessWidget {
  final String deviceIp;

  const CVConfigPage({super.key, required this.deviceIp});

  @override
  Widget build(BuildContext context) {
    final fields = [
      VoltConfigField(
        label: "Start Voltage (V) (Enter between -1.0 to 1.0)",
        controller: TextEditingController(text: "0.0"),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
          RangeInputFormatter(),
        ],
      ),
      VoltConfigField(
        label: "End Voltage (V) (Enter between -1.0 to 1.0)",
        controller: TextEditingController(text: "1.0"),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d{0,2}')),
          RangeInputFormatter(),
        ],
      ),
      VoltConfigField(
        label: "Scan Rate (V/s)",
        controller: TextEditingController(text: "100"),
      ),
      VoltConfigField(
        label: "Cycle Count",
        controller: TextEditingController(text: "3"),
      ),
    ];
    return VoltConfigPage(
      deviceIp: deviceIp,
      title: "Cyclic Voltammetry",
      endpoint: "cv",
      mode: "CV",
      fields: fields,
      buildConfig:
          (fields) => {
            "mode": "cv",
            "startVoltage": double.tryParse(fields[0].controller.text) ?? 0.0,
            "endVoltage": double.tryParse(fields[1].controller.text) ?? 1.0,
            "scanRate": double.tryParse(fields[2].controller.text) ?? 1.0,
            "cycles": int.tryParse(fields[3].controller.text) ?? 3,
          },
    );
  }
}

class RangeInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text == '-' || text == '' || text == '.' || text == '-.')
      return newValue;
    final value = double.tryParse(text);
    if (value == null) return oldValue;
    if (value < -1.0 || value > 1.0) return oldValue;
    return newValue;
  }
}
