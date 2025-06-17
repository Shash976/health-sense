import 'package:bio_amp/analyteDashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'constants.dart'; // includes Analyte and analytes list

class TaskPage extends StatelessWidget {
  final String deviceIp;

  const TaskPage({super.key, required this.deviceIp});

  void _showTestDialog(BuildContext context, Analyte analyte) {
    final oxidationCtrl = TextEditingController(text: analyte.oxidationPotential.toString());
    final minCtrl = TextEditingController(text: analyte.min.toString());
    final maxCtrl = TextEditingController(text: analyte.max.toString());
    final normalMinCtrl = TextEditingController(text: analyte.normalMinMGDL.toString());
    final normalMaxCtrl = TextEditingController(text: analyte.normalMaxMGDL.toString());
    final convFactorCtrl = TextEditingController(text: analyte.conversionFactor.toString());
    final timeCtrl = TextEditingController(text: analyte.time.toString());

    bool showFields = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text('Start ${analyte.name} Test'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!showFields) ...[
                      const Text('Customize parameters before starting?'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final config = {
                                  'task': analyte.code,
                                  'oxidationPotential': analyte.oxidationPotential,
                                  'normalMinMGDL': analyte.normalMinMGDL,
                                  'normalMaxMGDL': analyte.normalMaxMGDL,
                                  'conversionFactor': analyte.conversionFactor,
                                  'time': analyte.time,
                                  'min': analyte.min,
                                  'max': analyte.max,
                                };
                                _startTest(context, analyte, config);
                                Navigator.pop(ctx);
                              },
                              child: const Text("Use Defaults"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setState(() => showFields = true),
                              child: const Text("Customize"),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      _buildField("Oxidation Potential", oxidationCtrl),
                      _buildField("Normal Min (mg/dL)", normalMinCtrl),
                      _buildField("Normal Max (mg/dL)", normalMaxCtrl),
                      _buildField("Conversion Factor", convFactorCtrl),
                      _buildField("Test Time (ms)", timeCtrl),
                      _buildField("Min Sensor Range", minCtrl),
                      _buildField("Max Sensor Range", maxCtrl),
                    ],
                  ],
                ),
              ),
              actions: showFields
                  ? [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    final config = {
                      'task': analyte.code,
                      'oxidationPotential': double.tryParse(oxidationCtrl.text) ?? analyte.oxidationPotential,
                      'normalMinMGDL': double.tryParse(normalMinCtrl.text) ?? analyte.normalMinMGDL,
                      'normalMaxMGDL': double.tryParse(normalMaxCtrl.text) ?? analyte.normalMaxMGDL,
                      'conversionFactor': double.tryParse(convFactorCtrl.text) ?? analyte.conversionFactor,
                      'time': int.tryParse(timeCtrl.text) ?? analyte.time,
                      'min': double.tryParse(minCtrl.text) ?? analyte.min,
                      'max': double.tryParse(maxCtrl.text) ?? analyte.max,
                    };
                    _startTest(context, analyte, config);
                    Navigator.pop(ctx);
                  },
                  child: const Text("Start Test"),
                ),
              ]
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _startTest(BuildContext context, Analyte analyte, Map<String, dynamic> config) async {
    try {
      final response = await http.post(
        Uri.parse('http://$deviceIp/test'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(config),
      );

      if (response.statusCode == 200) {
        debugPrint("Sent parameters: $config");
        debugPrint("Test started successfully: ${response.body}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalyteDashboard(
              deviceIp: deviceIp,
              testName: analyte.name,
              min: config['normalMinMGDL'] ?? analyte.normalMinMGDL,
              max: config['normalMaxMGDL'] ?? analyte.normalMaxMGDL,
            ),
          ),
        );
      } else {
        throw Exception("Status: ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to start test: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Test')),
      body: ListView.builder(
        itemCount: analytes.length,
        itemBuilder: (context, index) {
          final analyte = analytes[index];
          return ListTile(
            title: Text(analyte.name),
            subtitle: Text("Normal: ${analyte.normalRange}"),
            trailing: ElevatedButton(
              child: const Text("Test"),
              onPressed: () => _showTestDialog(context, analyte),
            ),
          );
        },
      ),
    );
  }
}
