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

  Future<void> _sendTaskCommand(String taskCode) async {
    try {
      final url = Uri.parse('http://$deviceIp/test?task=$taskCode');
      await http.get(url); // Arduino handles this request
    } catch (e) {
      debugPrint("Error sending task: $e");
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
              child: const Text('Test'),
              onPressed: () async {
                await _sendTaskCommand(task['code']);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DashboardPage(
                      deviceIp: deviceIp,
                      testName: task['name'],
                      min: task['min'],
                      max: task['max'],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
