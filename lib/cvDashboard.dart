import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class CVDashboard extends StatefulWidget {
  final String deviceIp;

  const CVDashboard({super.key, required this.deviceIp});

  @override
  State<CVDashboard> createState() => _CVDashboardState();
}

class _CVDashboardState extends State<CVDashboard> {
  List<double> xValues = [];
  List<double> yValues = [];
  Timer? pollTimer;

  @override
  void initState() {
    super.initState();
    pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => fetchPoint());
  }

  Future<void> fetchPoint() async {
    try {
      final url = Uri.parse("http://${widget.deviceIp}/cvdata");
      final response = await http.get(url);
      debugPrint("CV Response: ${response.body}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey("x") && data.containsKey("y")) {
          setState(() {
            xValues.add((data["x"] as num).toDouble());
            yValues.add((data["y"] as num).toDouble());
          });
        } else if (data["status"] == "cv_done") {
          debugPrint("CV data collection complete.");
          pollTimer?.cancel();
          // handle completion (snackbar, nav, plot, etc.)
        }
      }
    }  on SocketException {
      debugPrint("Network error while fetching CV data.");
    } catch (e) {
      debugPrint("Error polling CV: $e");
    }
  }

  void _downloadCSV() async {
    final csvLines = <String>["x,y"];
    for (int i = 0; i < xValues.length; i++) {
      csvLines.add("${xValues[i]},${yValues[i]}");
    }
    final csv = csvLines.join("\n");

    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/cv_data.csv";
    final file = File(filePath);
    await file.writeAsString(csv);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("CSV saved to: $filePath")),
    );
  }


  @override
  void dispose() {
    pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("CV Data Stream")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Received ${xValues.length} points"),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: xValues.length,
                itemBuilder: (context, index) {
                  return Text("(${xValues[index].toStringAsFixed(2)}, ${yValues[index].toStringAsFixed(2)})");
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: xValues.isEmpty ? null : _downloadCSV,
              icon: Icon(Icons.download),
              label: Text("Download CSV"),
            ),
          ],
        ),
      ),
    );
  }
}

