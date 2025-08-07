import 'package:health_sense/analyte_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'analyte_constants.dart'; // includes Analyte and analytes list

class TaskPage extends StatelessWidget {
  final String deviceIp;

  const TaskPage({super.key, required this.deviceIp});

  void _showTestDialog(BuildContext context, Analyte analyte) {
    final oxidationCtrl = TextEditingController(text: analyte.oxidationPotential.toString());
    final normalMinCtrl = TextEditingController(text: analyte.normalMinMGDL.toString());
    final normalMaxCtrl = TextEditingController(text: analyte.normalMaxMGDL.toString());
    final convFactorCtrl = TextEditingController(text: analyte.conversionFactor.toString());
    final timeCtrl = TextEditingController(text: analyte.time.toString());
    final calibSlope = TextEditingController(text: analyte.calibSlope.toString());
    final calibConstant = TextEditingController(text: analyte.calibConstant.toString());

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
                                  'calibSlope': analyte.calibSlope,
                                  'calibConstant': analyte.calibConstant,
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
                      _buildField("Calibration Slope", calibSlope),
                      _buildField("Calibration Constant", calibConstant),
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
                      'calibSlope': double.tryParse(calibSlope.text) ?? analyte.calibSlope,
                      'calibConstant': double.tryParse(calibConstant.text) ?? analyte.calibConstant,
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

  // Add this method to TaskPage
  void _showAddAnalyteDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final oxidationCtrl = TextEditingController();
    final minCtrl = TextEditingController();
    final maxCtrl = TextEditingController();
    final normalMinCtrl = TextEditingController();
    final normalMaxCtrl = TextEditingController();
    final convFactorCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final calibSlope = TextEditingController();
    final calibConstant = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add New Analyte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField("Name", nameCtrl),
                _buildField("Code", codeCtrl),
                _buildField("Oxidation Potential", oxidationCtrl),
                _buildField("Normal Min (mg/dL)", normalMinCtrl),
                _buildField("Normal Max (mg/dL)", normalMaxCtrl),
                _buildField("Conversion Factor", convFactorCtrl),
                _buildField("Test Time (ms)", timeCtrl),
                _buildField("Calibration Slope", calibSlope),
                _buildField("Calibration Constant", calibConstant),
                _buildField("Min Sensor Range", minCtrl),
                _buildField("Max Sensor Range", maxCtrl),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                final config = {
                  'task': codeCtrl.text,
                  'oxidationPotential': double.tryParse(oxidationCtrl.text) ?? 0.0,
                  'normalMinMGDL': double.tryParse(normalMinCtrl.text) ?? 0.0,
                  'normalMaxMGDL': double.tryParse(normalMaxCtrl.text) ?? 0.0,
                  'conversionFactor': double.tryParse(convFactorCtrl.text) ?? 1.0,
                  'time': int.tryParse(timeCtrl.text) ?? 1000,
                  'calibSlope': double.tryParse(calibSlope.text) ?? 9.2609e-9,
                  'calibConstant': double.tryParse(calibConstant.text) ?? 7.276e-7,
                  'min': double.tryParse(minCtrl.text) ?? 0.0,
                  'max': double.tryParse(maxCtrl.text) ?? 100.0,
                };
                final analyte = Analyte(
                  nameCtrl.text,
                  codeCtrl.text,
                  double.tryParse(oxidationCtrl.text) ?? 0.0,
                  double.tryParse(normalMinCtrl.text) ?? 0.0,
                  double.tryParse(normalMaxCtrl.text) ?? 0.0,
                  double.tryParse(convFactorCtrl.text) ?? 1.0,
                  int.tryParse(timeCtrl.text) ?? 1000,
                  double.tryParse(calibSlope.text) ?? 1.0,
                  double.tryParse(calibConstant.text) ?? 0.0,
                );
                _startTest(context, analyte, config);
                Navigator.pop(ctx);
              },
              child: const Text("Start Test"),
            ),
          ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAnalyteDialog(context),
        tooltip: 'Add Analyte',
        child: const Icon(Icons.add),
      ),
    );
  }
}
