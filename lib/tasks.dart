import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard.dart';

class TaskPage extends StatelessWidget {
  final String deviceIp;

  TaskPage({super.key, required this.deviceIp});

  final List<Map<String, dynamic>> tasks = [
    {'name': 'Bilirubin', 'code': 'BIL', 'min': 0.2, 'max': 1.3},
    {'name': 'ALT', 'code': 'ALT', 'min': 10.0, 'max': 40.0},
    {'name': 'AST', 'code': 'AST', 'min': 10.0, 'max': 35.0},
  ];

  // Default parameters for each task
  final Map<String, Map<String, dynamic>> defaultParams = {
    'BIL': {'voltage': 3.3, 'time': 3000, 'gain': 4},
    'ALT': {'voltage': 5.0, 'time': 4000, 'gain': 6},
  };

  // Shows a dialog to start a test, with option to customize parameters
  void _showTestDialog(BuildContext context, String code, String name, double min, double max) {
    final defaultConfig = defaultParams[code]!;
    final TextEditingController voltageCtrl = TextEditingController(text: defaultConfig['voltage'].toString());
    final TextEditingController timeCtrl = TextEditingController(text: defaultConfig['time'].toString());
    final TextEditingController gainCtrl = TextEditingController(text: defaultConfig['gain'].toString());
    bool showFields = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text('Start ${name} Test'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // If not customizing, show options to use defaults or customize
                  if (!showFields) ...[
                    const Text('Do you want to customize parameters?'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _startTest(
                                context,
                                code,
                                name,
                                deviceIp,
                                defaultConfig,
                                min,
                                max,
                              );
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
                    )
                  ] else ...[
                    // If customizing, show input fields for parameters
                    _buildField("Voltage (V)", voltageCtrl),
                    _buildField("Time (ms)", timeCtrl),
                    _buildField("Gain", gainCtrl),
                  ],
                ],
              ),
              actions: showFields
                  ? [
                // Actions for customized parameters: Cancel or Start
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    final config = {
                      'task': code,
                      'voltage': double.tryParse(voltageCtrl.text) ?? defaultConfig['voltage'],
                      'time': int.tryParse(timeCtrl.text) ?? defaultConfig['time'],
                      'gain': int.tryParse(gainCtrl.text) ?? defaultConfig['gain'],
                    };
                    _startTest(context, code, name, deviceIp, config, min, max);
                    Navigator.pop(ctx);
                  },
                  child: const Text("Start"),
                ),
              ]
                  : null,
            );
          },
        );
      },
    );
  }

  // Builds a labeled input field for parameter customization
  Widget _buildField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  // Sends the test configuration to the device and navigates to the dashboard
  void _startTest(BuildContext context, String code, String name, String ip, Map<String, dynamic> config, double min, double max) async {
    try {
      await http.post(
        Uri.parse('http://$ip/test'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(config),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DashboardPage(
            deviceIp: ip,
            testName: name,
            min: min,
            max: max,
          ),
        ),
      );
    } catch (e) {
      // Show error if POST fails
      debugPrint("POST failed: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to send test to device")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Tasks')),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text(task['name']),
            trailing: ElevatedButton(
              child: const Text("Test"),
              onPressed: () {
                _showTestDialog(
                  context,
                  task['code'],
                  task['name'],
                  task['min'],
                  task['max'],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
