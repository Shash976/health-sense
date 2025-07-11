import 'package:bio_amp/volt_config_page.dart';
import 'package:flutter/material.dart';

class DPVConfigPage extends StatelessWidget {
  final String deviceIp;

  const DPVConfigPage({super.key, required this.deviceIp});

  @override
  Widget build(BuildContext context) {
    final fields = [
      VoltConfigField(label: "Start Voltage (V) [-1.0 to 1.0]", controller: TextEditingController(text: "-1.0")),
      VoltConfigField(label: "End Voltage (V) [-1.0 to 1.0]", controller: TextEditingController(text: "1.0")),
      VoltConfigField(label: "Step Height (V)", controller: TextEditingController(text: "0.01")),
      VoltConfigField(label: "Step Time (ms)", controller: TextEditingController(text: "100")),
      VoltConfigField(label: "Pulse Height (V)", controller: TextEditingController(text: "0.05")),
      VoltConfigField(label: "Pulse Width (ms)", controller: TextEditingController(text: "500")),
    ];
    return VoltConfigPage(
      deviceIp: deviceIp,
      title: "Differential Pulse Voltammetry",
      endpoint: "dpv",
      mode: "DPV",
      fields: fields,
      buildConfig: (fields) => {
        "mode": "DPV",
        "startVoltage": double.tryParse(fields[0].controller.text) ?? -0.5,
        "endVoltage": double.tryParse(fields[1].controller.text) ?? 1.0,
        "stepHeight": double.tryParse(fields[2].controller.text) ?? 0.1,
        "stepTime": int.tryParse(fields[3].controller.text) ?? 100,
        "pulseHeight": double.tryParse(fields[4].controller.text) ?? 0.05,
        "pulseWidth": int.tryParse(fields[5].controller.text) ?? 500,
      },
    );
  }
}
