import 'package:health_sense/analyte_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'analyte_constants.dart';

class TaskPage extends StatefulWidget {
  final String deviceIp;

  const TaskPage({super.key, required this.deviceIp});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  bool _startingTest = false;

  void _showTestDialog(BuildContext context, Analyte analyte) {
    final oxidationCtrl = TextEditingController(text: analyte.oxidationPotential.toString());
    final normalMinCtrl = TextEditingController(text: analyte.normalMinMGDL.toString());
    final normalMaxCtrl = TextEditingController(text: analyte.normalMaxMGDL.toString());
    final convFactorCtrl = TextEditingController(text: analyte.conversionFactor.toString());
    final timeCtrl = TextEditingController(text: analyte.time.toString());
    final calibSlopeCtrl = TextEditingController(text: analyte.calibSlope.toString());
    final calibConstantCtrl = TextEditingController(text: analyte.calibConstant.toString());

    void disposeControllers() {
      oxidationCtrl.dispose();
      normalMinCtrl.dispose();
      normalMaxCtrl.dispose();
      convFactorCtrl.dispose();
      timeCtrl.dispose();
      calibSlopeCtrl.dispose();
      calibConstantCtrl.dispose();
    }

    bool showFields = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
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
                              onPressed: _startingTest
                                  ? null
                                  : () {
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
                                      Navigator.pop(ctx);
                                      _startTest(context, analyte, config);
                                    },
                              child: const Text("Use Defaults"),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => setDialogState(() => showFields = true),
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
                      _buildField("Calibration Slope", calibSlopeCtrl),
                      _buildField("Calibration Constant", calibConstantCtrl),
                    ],
                  ],
                ),
              ),
              actions: showFields
                  ? [
                      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                      ElevatedButton(
                        onPressed: _startingTest
                            ? null
                            : () {
                                final config = {
                                  'task': analyte.code,
                                  'oxidationPotential': double.tryParse(oxidationCtrl.text) ?? analyte.oxidationPotential,
                                  'normalMinMGDL': double.tryParse(normalMinCtrl.text) ?? analyte.normalMinMGDL,
                                  'normalMaxMGDL': double.tryParse(normalMaxCtrl.text) ?? analyte.normalMaxMGDL,
                                  'conversionFactor': double.tryParse(convFactorCtrl.text) ?? analyte.conversionFactor,
                                  'time': int.tryParse(timeCtrl.text) ?? analyte.time,
                                  'calibSlope': double.tryParse(calibSlopeCtrl.text) ?? analyte.calibSlope,
                                  'calibConstant': double.tryParse(calibConstantCtrl.text) ?? analyte.calibConstant,
                                };
                                Navigator.pop(ctx);
                                _startTest(context, analyte, config);
                              },
                        child: const Text("Start Test"),
                      ),
                    ]
                  : null,
            );
          },
        );
      },
    ).then((_) => disposeControllers());
  }

  void _showAddAnalyteDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final oxidationCtrl = TextEditingController();
    final normalMinCtrl = TextEditingController();
    final normalMaxCtrl = TextEditingController();
    final convFactorCtrl = TextEditingController();
    final timeCtrl = TextEditingController();
    final calibSlopeCtrl = TextEditingController();
    final calibConstantCtrl = TextEditingController();

    void disposeAll() {
      nameCtrl.dispose();
      codeCtrl.dispose();
      oxidationCtrl.dispose();
      normalMinCtrl.dispose();
      normalMaxCtrl.dispose();
      convFactorCtrl.dispose();
      timeCtrl.dispose();
      calibSlopeCtrl.dispose();
      calibConstantCtrl.dispose();
    }

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
                _buildField("Calibration Slope", calibSlopeCtrl),
                _buildField("Calibration Constant", calibConstantCtrl),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: _startingTest
                  ? null
                  : () {
                      final name = nameCtrl.text.trim();
                      final code = codeCtrl.text.trim();
                      if (name.isEmpty || code.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name and Code are required.')),
                        );
                        return;
                      }
                      final minVal = double.tryParse(normalMinCtrl.text) ?? 0.0;
                      final maxVal = double.tryParse(normalMaxCtrl.text) ?? 100.0;
                      if (minVal >= maxVal) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Normal Min must be less than Normal Max.')),
                        );
                        return;
                      }
                      final analyte = Analyte(
                        name,
                        code,
                        double.tryParse(oxidationCtrl.text) ?? 0.0,
                        minVal,
                        maxVal,
                        double.tryParse(convFactorCtrl.text) ?? 1.0,
                        int.tryParse(timeCtrl.text) ?? 1000,
                        double.tryParse(calibSlopeCtrl.text) ?? 1.0,
                        double.tryParse(calibConstantCtrl.text) ?? 0.0,
                      );
                      // Add to list and rebuild the page, then start the test.
                      setState(() => addAnalyte(analyte));
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
                      Navigator.pop(ctx);
                      _startTest(context, analyte, config);
                    },
              child: const Text("Add & Start Test"),
            ),
          ],
        );
      },
    ).then((_) => disposeAll());
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

  Future<void> _startTest(BuildContext context, Analyte analyte, Map<String, dynamic> config) async {
    if (_startingTest) return;
    setState(() => _startingTest = true);
    try {
      final response = await http
          .post(
            Uri.parse('http://${widget.deviceIp}/test'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(config),
          )
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        debugPrint("Sent parameters: $config");
        debugPrint("Test started successfully: ${response.body}");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AnalyteDashboard(
              deviceIp: widget.deviceIp,
              testName: analyte.name,
              min: (config['normalMinMGDL'] as num).toDouble(),
              max: (config['normalMaxMGDL'] as num).toDouble(),
            ),
          ),
        );
      } else {
        throw Exception("Status: ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to start test: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _startingTest = false);
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
              onPressed: _startingTest ? null : () => _showTestDialog(context, analyte),
              child: const Text("Test"),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _startingTest ? null : () => _showAddAnalyteDialog(context),
        tooltip: 'Add Analyte',
        child: const Icon(Icons.add),
      ),
    );
  }
}
