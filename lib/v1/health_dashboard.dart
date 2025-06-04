// import 'package:flutter/material.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
//
// class HealthDashboardPage extends StatefulWidget {
//   final DiscoveredDevice device;
//   const HealthDashboardPage({super.key, required this.device});
//
//   @override
//   State<HealthDashboardPage> createState() => _HealthDashboardPageState();
// }
//
// class _HealthDashboardPageState extends State<HealthDashboardPage> {
//   final FlutterReactiveBle _ble = FlutterReactiveBle();
//   late QualifiedCharacteristic _char;
//   late Stream<List<int>> _charStream;
//   double? bilirubinLevel;
//
//   final serviceUuid = Uuid.parse("0000180D-0000-1000-8000-00805f9b34fb"); // replace with your own
//   final characteristicUuid = Uuid.parse("00002A37-0000-1000-8000-00805f9b34fb"); // replace with your own
//
//   @override
//   void initState() {
//     super.initState();
//     _char = QualifiedCharacteristic(
//       deviceId: widget.device.id,
//       serviceId: serviceUuid,
//       characteristicId: characteristicUuid,
//     );
//
//     _charStream = _ble.subscribeToCharacteristic(_char);
//     _charStream.listen((value) {
//       final double parsed = _parseBilirubinValue(value);
//       setState(() {
//         bilirubinLevel = parsed;
//       });
//     });
//   }
//
//   double _parseBilirubinValue(List<int> value) {
//     // Example: interpret the first byte as a float in mg/dL
//     return value.isNotEmpty ? value[0] / 10.0 : 0.0;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isNormal = bilirubinLevel != null && bilirubinLevel! >= 0.2 && bilirubinLevel! <= 1.3;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Health Dashboard"),
//         backgroundColor: Colors.green[400],
//         automaticallyImplyLeading: false,
//       ),
//       body: bilirubinLevel == null
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//         padding: const EdgeInsets.all(20),
//         child: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 "Good Morning",
//                 style: TextStyle(fontSize: 20),
//               ),
//               const SizedBox(height: 8),
//               const Text("User", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 16),
//
//               // User Info
//               Row(
//                 children: const [
//                   Expanded(child: Text("Age", style: TextStyle(fontWeight: FontWeight.bold))),
//                   Expanded(child: Text("29")),
//                 ],
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 children: [
//                   const Expanded(child: Text("Date", style: TextStyle(fontWeight: FontWeight.bold))),
//                   Expanded(child: Text(DateTime.now().toString().split(" ").first)),
//                 ],
//               ),
//               const SizedBox(height: 20),
//
//               // Bilirubin Card
//               Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(12),
//                   color: Colors.white,
//                   boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6)],
//                 ),
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     const Text(
//                       "Total Bilirubin",
//                       style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       "${bilirubinLevel!.toStringAsFixed(1)} mg/dL",
//                       style: const TextStyle(fontSize: 44),
//                     ),
//                     const SizedBox(height: 12),
//                     LinearProgressIndicator(
//                       value: ((bilirubinLevel! - 0.2) / (1.3 - 0.2)).clamp(0.0, 1.0),
//                       backgroundColor: Colors.grey[200],
//                       color: isNormal ? Colors.green : Colors.red,
//                       minHeight: 10,
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       isNormal
//                           ? "Your Bilirubin level is normal"
//                           : "Your Bilirubin level is abnormal",
//                       style: TextStyle(
//                         color: isNormal ? Colors.green : Colors.red,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     const Text("Normal Range: 0.2 - 1.3 mg/dL"),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//
//               // Details Card
//               Container(
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(12),
//                   color: Colors.white,
//                   boxShadow: [BoxShadow(color: Colors.grey.shade300, blurRadius: 6)],
//                 ),
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: const [
//                     Text("Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                     SizedBox(height: 8),
//                     Text(
//                       "Bilirubin is a yellow compound that occurs in the normal catabolic pathway that breaks down heme in red blood cells.",
//                     ),
//                     SizedBox(height: 12),
//                     Text("Book a Telehealth Visit"),
//                     Text("Share results with a doctor"),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 30),
//
//               // Navigation Button
//               Center(
//                 child: ElevatedButton.icon(
//                   icon: const Icon(Icons.chevron_left),
//                   label: const Text("Back to Tasks"),
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.green[400],
//                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
