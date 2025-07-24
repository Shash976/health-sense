import 'package:bio_amp/volt_config_page.dart';
import 'package:flutter/material.dart';

class AMPConfigPage extends StatelessWidget {
  final String deviceIp;

  const AMPConfigPage({super.key, required this.deviceIp});

  @override
  Widget build(BuildContext context) {
    final fields = [
      VoltConfigField(label: "Oxidation Potential (V)", controller: TextEditingController(text: "0.0")),
      VoltConfigField(label: "Run Time (ms)", controller: TextEditingController(text: "100")),
      VoltConfigField(label: "Measure Interval (ms)", controller: TextEditingController(text: "100")),
    ];
    return VoltConfigPage(
      deviceIp: deviceIp,
      title: "Amperometric Titration",
      endpoint: "amp",
      mode: "AMP",
      fields: fields,
      buildConfig: (fields) => {
        "mode": "AMP",
        "oxidationPotential": double.tryParse(fields[0].controller.text) ?? 0.0,
        "runTime": int.tryParse(fields[1].controller.text) ?? 12,
        "measureInterval": int.tryParse(fields[2].controller.text) ?? 120,
      },
    );
  }
}
