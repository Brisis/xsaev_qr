// ignore_for_file: avoid_print

// import 'dart:convert';
// import 'dart:math';
// import 'dart:typed_data';

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:nearby_connections/nearby_connections.dart';
// import 'package:xsaev/domain/services/nearby_service.dart';

// void main() => runApp(const MyApp());

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: const Text('Nearby Connections Example'),
//         ),
//         body: const Body(),
//       ),
//     );
//   }
// }

// class Body extends StatefulWidget {
//   const Body({super.key});

//   @override
//   State<Body> createState() => _BodyState();
// }

// class _BodyState extends State<Body> {
//   final NearbyConnectionsService nearby = NearbyConnectionsService();
//   final String userName = Random().nextInt(10000).toString();
//   final Strategy strategy = Strategy.P2P_STAR;
//   final ImagePicker _imagePicker = ImagePicker();

//   @override
//   void initState() {
//     super.initState();
//     _setupListeners();
//   }

//   void _setupListeners() {
//     nearby.onConnectionInitiated.listen((event) {
//       _showConnectionDialog(event.endpointId, event.info);
//     });

//     nearby.onConnectionResult.listen((event) {
//       _showSnackbar('Connection ${event.status} with ${event.endpointId}');
//     });

//     nearby.onDisconnected.listen((endpointId) {
//       _showSnackbar('Disconnected: $endpointId');
//       setState(() {});
//     });

//     nearby.onPayloadReceived.listen((event) {
//       _showSnackbar('Received from ${event.endpointId}: ${event.data}');
//     });

//     nearby.onPayloadTransferUpdate.listen((event) {
//       if (event.update.status == PayloadStatus.SUCCESS) {
//         _showSnackbar('Transfer success with ${event.endpointId}');
//       }
//     });
//   }

//   void _showConnectionDialog(String endpointId, ConnectionInfo info) {
//     showModalBottomSheet(
//       context: context,
//       builder: (context) => ConnectionDialog(
//         endpointId: endpointId,
//         info: info,
//         onAccept: () => nearby.acceptConnection(endpointId, info),
//         onReject: () => Nearby().rejectConnection(endpointId),
//       ),
//     );
//   }

//   void _showSnackbar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   @override
//   void dispose() {
//     nearby.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: ListView(
//         children: [
//           _buildAdvertisingSection(),
//           _buildDiscoverySection(),
//           _buildConnectionStatus(),
//           _buildDataTransferSection(),
//         ],
//       ),
//     );
//   }

//   Widget _buildAdvertisingSection() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             const Text('Advertising', style: TextStyle(fontSize: 18)),
//             Wrap(
//               spacing: 8.0,
//               children: [
//                 ElevatedButton(
//                   onPressed: () async {
//                     try {
//                       await nearby.startAdvertising(userName, strategy);
//                       _showSnackbar('Advertising started');
//                     } catch (e) {
//                       _showSnackbar('Error: $e');
//                     }
//                   },
//                   child: const Text('Start Advertising'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => Nearby().stopAdvertising(),
//                   child: const Text('Stop Advertising'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDiscoverySection() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             const Text('Discovery', style: TextStyle(fontSize: 18)),
//             Wrap(
//               spacing: 8.0,
//               children: [
//                 ElevatedButton(
//                   onPressed: () async {
//                     try {
//                       await nearby.startDiscovery(userName, strategy);
//                       _showSnackbar('Discovery started');
//                     } catch (e) {
//                       _showSnackbar('Error: $e');
//                     }
//                   },
//                   child: const Text('Start Discovery'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () => Nearby().stopDiscovery(),
//                   child: const Text('Stop Discovery'),
//                 ),
//               ],
//             ),
//             StreamBuilder<String>(
//               stream: nearby.onEndpointDiscovered,
//               builder: (context, snapshot) {
//                 if (snapshot.hasData) {
//                   final data = snapshot.data!;
//                   if (data.startsWith('lost:')) {
//                     return Text('Lost endpoint: ${data.substring(5)}');
//                   }
//                   return ListTile(
//                     title: Text('Discovered endpoint: $data'),
//                     trailing: ElevatedButton(
//                       child: const Text('Connect'),
//                       onPressed: () => nearby.requestConnection(userName, data),
//                     ),
//                   );
//                 }
//                 return const SizedBox.shrink();
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildConnectionStatus() {
//     return Card(
//       child: StreamBuilder<Object>(
//           stream: nearby.onConnectionResult,
//           builder: (context, snapshot) {
//             return Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: Column(
//                 children: [
//                   const Text('Connected Devices',
//                       style: TextStyle(fontSize: 18)),
//                   Text('${nearby.endpoints.length} devices connected',
//                       style: const TextStyle(fontSize: 16)),
//                   ElevatedButton(
//                     onPressed: () async {
//                       await nearby.stopAll();
//                       setState(() {});
//                       _showSnackbar('All connections stopped');
//                     },
//                     child: const Text('Stop All Connections'),
//                   ),
//                 ],
//               ),
//             );
//           }),
//     );
//   }

//   Widget _buildDataTransferSection() {
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             const Text('Data Transfer', style: TextStyle(fontSize: 18)),
//             Wrap(
//               spacing: 8.0,
//               children: [
//                 ElevatedButton(
//                   onPressed: () {
//                     // Create the JSON data structure
//                     final data = {
//                       'account': "298302",
//                       'amount': 2.55,
//                       'timestamp': DateTime.now().toIso8601String(),
//                     };

//                     // Convert to JSON string and then to bytes
//                     final jsonString = jsonEncode(data);
//                     final jsonBytes =
//                         Uint8List.fromList(utf8.encode(jsonString));

//                     // Send to all connected endpoints
//                     for (final endpoint in nearby.endpoints.keys) {
//                       nearby.sendBytes(endpoint, jsonBytes);
//                     }
//                     _showSnackbar('JSON data sent');
//                   },
//                   child: const Text('Send Transaction Data'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () async {
//                     final file = await _imagePicker.pickImage(
//                       source: ImageSource.gallery,
//                     );
//                     if (file != null) {
//                       for (final endpoint in nearby.endpoints.keys) {
//                         await nearby.sendFile(endpoint, file.path);
//                       }
//                       _showSnackbar('File sent');
//                     }
//                   },
//                   child: const Text('Send File'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class ConnectionDialog extends StatelessWidget {
//   final String endpointId;
//   final ConnectionInfo info;
//   final VoidCallback onAccept;
//   final VoidCallback onReject;

//   const ConnectionDialog({
//     super.key,
//     required this.endpointId,
//     required this.info,
//     required this.onAccept,
//     required this.onReject,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text('Connection Request from ${info.endpointName}',
//               style: const TextStyle(fontSize: 18)),
//           const SizedBox(height: 16),
//           Text('ID: $endpointId'),
//           Text('Authentication Token: ${info.authenticationToken}'),
//           const SizedBox(height: 24),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: [
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   onAccept();
//                 },
//                 child: const Text('Accept'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   onReject();
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                 ),
//                 child: const Text('Reject'),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:xsaev/core/constants.dart';
import 'package:xsaev/ui/screens/forgot_password_screen.dart';
import 'package:xsaev/ui/screens/generate_qr_screen.dart';
import 'package:xsaev/ui/screens/home_screen.dart';
import 'package:xsaev/ui/screens/login_screen.dart';
import 'package:xsaev/ui/screens/profile_screen.dart';
import 'package:xsaev/ui/screens/register_screen.dart';
import 'package:xsaev/ui/screens/scan_qr_screen.dart';
import 'package:xsaev/ui/screens/splash_screen.dart';
import 'package:xsaev/ui/screens/welcome_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Xsaev',
      theme: ThemeData(
        primarySwatch: customGreen,
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryColor, // Main customGreen color
          iconTheme: IconThemeData(color: Colors.white), // Icon color
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        cardTheme: const CardTheme(
          color: Color(0xFFE7E7E7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          elevation: 2,
          // margin: EdgeInsets.symmetric(vertical: 8),
        ),
        // listTileTheme: const ListTileThemeData(
        //   contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        //   iconColor: Colors.black87,
        //   textColor: Colors.black87,
        //   shape: RoundedRectangleBorder(
        //     borderRadius: BorderRadius.all(Radius.circular(12)),
        //   ),
        // ),
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/': (context) => const WelcomeScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/geneate-qr': (context) => const GenerateQrScreen(), // QR generation
        '/scan': (context) => const ScanQrScreen(), // QR scanner
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
}

// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'dart:async';

// import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: MyHomePage(),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key});

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
//   final TextEditingController msgText = TextEditingController();
//   final _flutterP2pConnectionPlugin = FlutterP2pConnection();

//   List<DiscoveredPeers> peers = [];
//   WifiP2PInfo? wifiP2PInfo;

//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addObserver(this);
//     _init();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     _flutterP2pConnectionPlugin.unregister();
//     super.dispose();
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.paused) {
//       _flutterP2pConnectionPlugin.unregister();
//     } else if (state == AppLifecycleState.resumed) {
//       _flutterP2pConnectionPlugin.register();
//     }
//   }

//   void _init() async {
//     await _flutterP2pConnectionPlugin.initialize();
//     await _flutterP2pConnectionPlugin.register();
//     _flutterP2pConnectionPlugin.streamWifiP2PInfo().listen((event) {
//       setState(() {
//         wifiP2PInfo = event;
//       });
//     });
//     _flutterP2pConnectionPlugin.streamPeers().listen((event) async {
//       setState(() {
//         peers = event;
//       });
//     });
//   }

//   Future startSocket() async {
//     if (wifiP2PInfo != null) {
//       bool started = await _flutterP2pConnectionPlugin.startSocket(
//         groupOwnerAddress: wifiP2PInfo!.groupOwnerAddress,
//         downloadPath: "/storage/emulated/0/Download/",
//         maxConcurrentDownloads: 2,
//         deleteOnError: true,
//         onConnect: (name, address) {
//           snack("$name connected to socket with address: $address");
//         },
//         transferUpdate: (transfer) {
//           if (transfer.completed) {
//             snack(
//                 "${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
//           }
//           print(
//               "ID: ${transfer.id}, FILENAME: ${transfer.filename}, PATH: ${transfer.path}, COUNT: ${transfer.count}, TOTAL: ${transfer.total}, COMPLETED: ${transfer.completed}, FAILED: ${transfer.failed}, RECEIVING: ${transfer.receiving}");
//         },
//         onCloseSocket: () {
//           print("close connection");
//         },
//         receiveString: (req) async {
//           snack(req);
//         },
//       );
//       snack("open socket: $started");
//     }
//   }

//   Future connectToSocket() async {
//     if (wifiP2PInfo != null) {
//       await _flutterP2pConnectionPlugin.connectToSocket(
//         groupOwnerAddress: wifiP2PInfo!.groupOwnerAddress,
//         downloadPath: "/storage/emulated/0/Download/",
//         maxConcurrentDownloads: 3,
//         deleteOnError: true,
//         onConnect: (address) {
//           snack("connected to socket: $address");
//         },
//         onCloseSocket: () {
//           snack("closed to socket");
//         },
//         transferUpdate: (transfer) {
//           // if (transfer.count == 0) transfer.cancelToken?.cancel();
//           if (transfer.completed) {
//             snack(
//                 "${transfer.failed ? "failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "received" : "sent"}: ${transfer.filename}");
//           }
//           print(
//               "ID: ${transfer.id}, FILENAME: ${transfer.filename}, PATH: ${transfer.path}, COUNT: ${transfer.count}, TOTAL: ${transfer.total}, COMPLETED: ${transfer.completed}, FAILED: ${transfer.failed}, RECEIVING: ${transfer.receiving}");
//         },
//         receiveString: (req) async {
//           snack(req);
//         },
//       );
//     }
//   }

//   Future closeSocketConnection() async {
//     bool closed = _flutterP2pConnectionPlugin.closeSocket();
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           "closed: $closed",
//         ),
//       ),
//     );
//   }

//   Future sendMessage() async {
//     _flutterP2pConnectionPlugin.sendStringToSocket(msgText.text);
//   }

//   void snack(String msg) async {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         duration: const Duration(seconds: 2),
//         content: Text(
//           msg,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Flutter p2p connection plugin'),
//       ),
//       body: SingleChildScrollView(
//         physics: const BouncingScrollPhysics(),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Text(
//                 "IP: ${wifiP2PInfo == null ? "null" : wifiP2PInfo?.groupOwnerAddress}"),
//             wifiP2PInfo != null
//                 ? Text(
//                     "connected: ${wifiP2PInfo?.isConnected}, isGroupOwner: ${wifiP2PInfo?.isGroupOwner}, groupFormed: ${wifiP2PInfo?.groupFormed}, groupOwnerAddress: ${wifiP2PInfo?.groupOwnerAddress}, clients: ${wifiP2PInfo?.clients}")
//                 : const SizedBox.shrink(),
//             const SizedBox(height: 10),
//             const Text("PEERS:"),
//             SizedBox(
//               height: 100,
//               width: MediaQuery.of(context).size.width,
//               child: ListView.builder(
//                 scrollDirection: Axis.horizontal,
//                 itemCount: peers.length,
//                 itemBuilder: (context, index) => Center(
//                   child: GestureDetector(
//                     onTap: () {
//                       showDialog(
//                         context: context,
//                         builder: (context) => Center(
//                           child: AlertDialog(
//                             content: SizedBox(
//                               height: 200,
//                               child: Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text("name: ${peers[index].deviceName}"),
//                                   Text(
//                                       "address: ${peers[index].deviceAddress}"),
//                                   Text(
//                                       "isGroupOwner: ${peers[index].isGroupOwner}"),
//                                   Text(
//                                       "isServiceDiscoveryCapable: ${peers[index].isServiceDiscoveryCapable}"),
//                                   Text(
//                                       "primaryDeviceType: ${peers[index].primaryDeviceType}"),
//                                   Text(
//                                       "secondaryDeviceType: ${peers[index].secondaryDeviceType}"),
//                                   Text("status: ${peers[index].status}"),
//                                 ],
//                               ),
//                             ),
//                             actions: [
//                               TextButton(
//                                 onPressed: () async {
//                                   Navigator.of(context).pop();
//                                   bool? bo = await _flutterP2pConnectionPlugin
//                                       .connect(peers[index].deviceAddress);
//                                   snack("connected: $bo");
//                                 },
//                                 child: const Text("connect"),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                     child: Container(
//                       height: 80,
//                       width: 80,
//                       decoration: BoxDecoration(
//                         color: Colors.grey,
//                         borderRadius: BorderRadius.circular(50),
//                       ),
//                       child: Center(
//                         child: Text(
//                           peers[index]
//                               .deviceName
//                               .toString()
//                               .characters
//                               .first
//                               .toUpperCase(),
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 30,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 _init();
//               },
//               child: const Text("initialize"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 snack(await _flutterP2pConnectionPlugin.askStoragePermission()
//                     ? "granted"
//                     : "denied");
//               },
//               child: const Text("ask storage permission"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 snack(
//                     await _flutterP2pConnectionPlugin.askConnectionPermissions()
//                         ? "granted"
//                         : "denied");
//               },
//               child: const Text(
//                 "ask required permissions for connection (nearbyWifiDevices & location)",
//                 textAlign: TextAlign.center,
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 snack(await _flutterP2pConnectionPlugin.checkLocationEnabled()
//                     ? "enabled"
//                     : "disabled");
//               },
//               child: const Text(
//                 "check location enabled",
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 snack(await _flutterP2pConnectionPlugin.checkWifiEnabled()
//                     ? "enabled"
//                     : "disabled");
//               },
//               child: const Text("check wifi enabled"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 print(
//                     await _flutterP2pConnectionPlugin.enableLocationServices());
//               },
//               child: const Text("enable location"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 print(await _flutterP2pConnectionPlugin.enableWifiServices());
//               },
//               child: const Text("enable wifi"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 bool? created = await _flutterP2pConnectionPlugin.createGroup();
//                 snack("created group: $created");
//               },
//               child: const Text("create group"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 bool? removed = await _flutterP2pConnectionPlugin.removeGroup();
//                 snack("removed group: $removed");
//               },
//               child: const Text("remove group/disconnect"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 var info = await _flutterP2pConnectionPlugin.groupInfo();
//                 showDialog(
//                   context: context,
//                   builder: (context) => Center(
//                     child: Dialog(
//                       child: SizedBox(
//                         height: 200,
//                         child: Padding(
//                           padding: const EdgeInsets.symmetric(horizontal: 10),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                   "groupNetworkName: ${info?.groupNetworkName}"),
//                               Text("passPhrase: ${info?.passPhrase}"),
//                               Text("isGroupOwner: ${info?.isGroupOwner}"),
//                               Text("clients: ${info?.clients}"),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//               child: const Text("get group info"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 String? ip = await _flutterP2pConnectionPlugin.getIPAddress();
//                 snack("ip: $ip");
//               },
//               child: const Text("get ip"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 bool? discovering =
//                     await _flutterP2pConnectionPlugin.discover();
//                 snack("discovering $discovering");
//               },
//               child: const Text("discover"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 bool? stopped =
//                     await _flutterP2pConnectionPlugin.stopDiscovery();
//                 snack("stopped discovering $stopped");
//               },
//               child: const Text("stop discovery"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 startSocket();
//               },
//               child: const Text("open a socket"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 connectToSocket();
//               },
//               child: const Text("connect to socket"),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 closeSocketConnection();
//               },
//               child: const Text("close socket"),
//             ),
//             TextField(
//               controller: msgText,
//               decoration: const InputDecoration(
//                 hintText: "message",
//               ),
//             ),
//             ElevatedButton(
//               onPressed: () async {
//                 sendMessage();
//               },
//               child: const Text("send msg"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
