import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DPVDashboard extends StatefulWidget {
  final String deviceIp;

  const DPVDashboard({super.key, required this.deviceIp});

  @override
  State<DPVDashboard> createState() => _DPVDashboardState();
}

class _DPVDashboardState extends State<DPVDashboard> {
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
      final url = Uri.parse("http://${widget.deviceIp}/dpvdata");
      final response = await http.get(url);
      debugPrint("DPV Response: ${response.body}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey("x") && data.containsKey("y")) {
          setState(() {
            xValues.add((data["x"] as num).toDouble());
            yValues.add((data["y"] as num).toDouble());
          });
        } else if (data["status"] == "dpv_done") {
          pollTimer?.cancel();
          // handle completion (snackbar, nav, plot, etc.)
        }
      }
    }  on SocketException {
      debugPrint("Network error while fetching DPV data.");
    } catch (e) {
      debugPrint("Error polling DPV: $e");
    }
  }

  void _downloadCSV() async {
    final csvLines = <String>["x,y"];
    for (int i = 0; i < xValues.length; i++) {
      csvLines.add("${xValues[i]},${yValues[i]}");
    }
    final csv = csvLines.join("\n");

    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/dpv_data.csv";
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
      appBar: AppBar(title: const Text("DPV Data Stream")),
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

