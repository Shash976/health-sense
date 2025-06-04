// import 'dart:async';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
//
// class BluetoothPage extends StatefulWidget {
//   const BluetoothPage({super.key});
//
//   @override
//   State<BluetoothPage> createState() => _BluetoothPageState();
// }
//
// class _BluetoothPageState extends State<BluetoothPage> {
//   final FlutterReactiveBle _ble = FlutterReactiveBle();
//   bool _isScanning = false;
//   late StreamSubscription<DiscoveredDevice> _scanSubscription;
//   final List<DiscoveredDevice> _devices = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _startScan();
//   }
//
//   void _startScan() {
//     _devices.clear();
//     _scanSubscription = _ble.scanForDevices(
//       withServices: [], // Specify your service UUIDs if needed
//       scanMode: ScanMode.lowLatency,
//     ).listen((device) {
//       setState(() {
//         _devices.add(device);
//       });
//     }, onError: (error) {
//       // Handle scan error
//     });
//
//     setState(() {
//       _isScanning = true;
//     });
//   }
//
//   void _stopScan() {
//     _scanSubscription.cancel();
//     setState(() {
//       _isScanning = false;
//     });
//   }
//
//   @override
//   void dispose() {
//     _scanSubscription.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Bluetooth')),
//       body: Column(
//         children: [
//           SwitchListTile(
//             title: const Text('Enable Bluetooth'),
//             value: _isScanning,
//             onChanged: (value) {
//               if (value) {
//                 _startScan();
//               } else {
//                 _stopScan();
//               }
//             },
//           ),
//           const Divider(),
//           const ListTile(
//             title: Text('Devices'),
//             trailing: Icon(Icons.sync),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: _devices.length,
//               itemBuilder: (context, index) {
//                 final device = _devices[index];
//                 return ListTile(
//                   title: Text(device.name.isNotEmpty ? device.name : 'Unknown'),
//                   subtitle: Text(device.id),
//                   onTap: () {
//                     // Handle device selection
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
