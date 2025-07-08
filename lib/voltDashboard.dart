import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class VoltDashboard extends StatefulWidget {
  final String deviceIp;
  final String mode;

  const VoltDashboard({super.key, required this.deviceIp, required this.mode});


  @override
  State<VoltDashboard> createState() => _VoltDashboardState();
}

class _VoltDashboardState extends State<VoltDashboard> {
  List<double> xValues = [];
  List<double> yValues = [];
  Timer? pollTimer;
  late ScrollController _scrollController;


  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    pollTimer = Timer.periodic(const Duration(milliseconds: 100), (_) => fetchPoint());
  }

  Future<void> fetchPoint() async {
    try {

      final url = Uri.parse("http://${widget.deviceIp}/${widget.mode.toLowerCase()}data");
      final response = await http.get(url);
      debugPrint("${widget.mode.toUpperCase()} Response: ${response.body}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey("x") && data.containsKey("y")) {
          setState(() {
            xValues.add((data["x"] as num).toDouble());
            yValues.add((data["y"] as num).toDouble());
          });
          // Auto-scroll to the bottom
          Future.delayed(Duration(milliseconds: 50), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        } else if (data["status"] == "${widget.mode.toLowerCase()}_done") {
          pollTimer?.cancel();
          // handle completion (snackbar, nav, plot, etc.)
        }
      }
    }  on SocketException {
      debugPrint("Network error while fetching ${widget.mode.toUpperCase()} data.");
    } catch (e) {
      debugPrint("Error polling ${widget.mode.toUpperCase()}: $e");
    }
  }

  void _downloadCSV() async {
    final csvLines = <String>["x,y"];
    for (int i = 0; i < xValues.length; i++) {
      csvLines.add("${xValues[i]},${yValues[i]}");
    }
    final csv = csvLines.join("\n");

    final directory = await getApplicationDocumentsDirectory();
    final filePath = "${directory.path}/${widget.mode.toLowerCase()}_data.csv";
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
    final appBarTitle = "${widget.mode.toUpperCase()} Data Stream";
    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Received ${xValues.length} points"),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
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