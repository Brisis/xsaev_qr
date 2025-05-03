import 'package:flutter/material.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';
import 'dart:async';

class WifiService extends ChangeNotifier {
  final FlutterP2pConnection _p2pPlugin = FlutterP2pConnection();
  final StreamController<String> _messageController =
      StreamController.broadcast();

  List<DiscoveredPeers> _peers = [];
  WifiP2PInfo? _wifiP2PInfo;
  StreamSubscription<WifiP2PInfo>? _wifiInfoSubscription;
  StreamSubscription<List<DiscoveredPeers>>? _peersSubscription;

  List<DiscoveredPeers> get peers => _peers;
  WifiP2PInfo? get wifiP2PInfo => _wifiP2PInfo;

  Stream<String> get messages => _messageController.stream;

  Future<void> initialize() async {
    await _p2pPlugin.initialize();
    await _p2pPlugin.register();
    _setupListeners();

    await askConnectionPermissions();
    await discover();

    // // await closeSocket();
    // await removeGroup();
    // await stopDiscovery();

    // await createGroup();

    // await startSocket();
  }

  void _setupListeners() {
    _wifiInfoSubscription = _p2pPlugin.streamWifiP2PInfo().listen((event) {
      _wifiP2PInfo = event;
      notifyListeners();
    });

    // _peersSubscription = _p2pPlugin.streamPeers().listen((event) {
    //   _peersSubscription?.cancel(); // Clear existing subscription
    //   _peers = event;
    //   notifyListeners();
    //   print("Updated peers list: ${_peers.length} items");
    // });

    _peersSubscription = _p2pPlugin.streamPeers().listen(
      (event) {
        _peers = event;
        notifyListeners();
        print("Updated peers list: ${_peers.length} items");
      },
      onError: (error) {
        print("Peer stream error: $error");
        _messageController.add("Error discovering peers: $error");
      },
      onDone: () {
        print("Peer stream closed");
      },
    );
  }

  Future<bool> askStoragePermission() async {
    return await _p2pPlugin.askStoragePermission();
  }

  Future<bool> askConnectionPermissions() async {
    final value = await _p2pPlugin.askConnectionPermissions();
    _messageController.add("Permisions Granted: $value");
    return value;
  }

  Future<bool> checkLocationEnabled() async {
    return await _p2pPlugin.checkLocationEnabled();
  }

  Future<bool> checkWifiEnabled() async {
    return await _p2pPlugin.checkWifiEnabled();
  }

  Future<bool> enableLocationServices() async {
    return await _p2pPlugin.enableLocationServices();
  }

  Future<bool> enableWifiServices() async {
    return await _p2pPlugin.enableWifiServices();
  }

  Future<bool?> createGroup() async {
    bool value = await _p2pPlugin.createGroup();

    if (value == false) {
      await _p2pPlugin.removeGroup();
      value = await _p2pPlugin.createGroup();
    }

    _messageController.add("Create Group: $value");
    return value;
  }

  // Future<bool?> createGroup() async {
  //   final value = await _p2pPlugin.createGroup();
  //   _messageController.add("Create Group: $value");
  //   return value;
  // }

  // Future<bool?> removeGroup() async {
  //   final value = await _p2pPlugin.removeGroup();
  //   _messageController.add("Remove Group: $value");
  //   return value;
  // }

  Future<WifiP2PGroupInfo?> groupInfo() async {
    return await _p2pPlugin.groupInfo();
  }

  Future<String?> getIPAddress() async {
    return await _p2pPlugin.getIPAddress();
  }

  Future<bool?> discover() async {
    bool value = await _p2pPlugin.discover();

    if (value == false) {
      await _p2pPlugin.stopDiscovery();
      value = await _p2pPlugin.discover();
    }

    _messageController.add("Discovery: $value");
    notifyListeners();
    return value;
  }

  // Future<bool?> discover() async {
  //   final value = await _p2pPlugin.discover();
  //   _messageController.add("Discovery: $value");
  //   notifyListeners();
  //   return value;
  // }

  // Future<bool?> stopDiscovery() async {
  //   final value = await _p2pPlugin.stopDiscovery();
  //   _messageController.add("Stop Discovery: $value");
  //   return value;
  // }

  Future<void> startSocket() async {
    if (_wifiP2PInfo == null) return;

    final started = await _p2pPlugin.startSocket(
      groupOwnerAddress: _wifiP2PInfo!.groupOwnerAddress,
      downloadPath: "/storage/emulated/0/Download/",
      maxConcurrentDownloads: 2,
      deleteOnError: true,
      onConnect: (name, address) {
        _messageController
            .add("$name connected to socket with address: $address");
      },
      transferUpdate: (transfer) {
        if (transfer.completed) {
          _messageController.add(
              "${transfer.failed ? "Failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "Received" : "Sent"}: ${transfer.filename}");
        }
      },
      onCloseSocket: () {
        _messageController.add("Socket connection closed");
      },
      receiveString: (req) {
        _messageController.add(req);
        notifyListeners();
      },
    );
    _messageController.add("Socket started: $started");
  }

  Future<void> connectToSocket() async {
    if (_wifiP2PInfo == null) return;

    await _p2pPlugin.connectToSocket(
      groupOwnerAddress: _wifiP2PInfo!.groupOwnerAddress,
      downloadPath: "/storage/emulated/0/Download/",
      maxConcurrentDownloads: 3,
      deleteOnError: true,
      onConnect: (address) {
        _messageController.add("Connected to socket: $address");
      },
      onCloseSocket: () {
        _messageController.add("Socket connection closed");
      },
      transferUpdate: (transfer) {
        if (transfer.completed) {
          _messageController.add(
              "${transfer.failed ? "Failed to ${transfer.receiving ? "receive" : "send"}" : transfer.receiving ? "Received" : "Sent"}: ${transfer.filename}");
        }
      },
      receiveString: (req) {
        _messageController.add(req);
        notifyListeners();
      },
    );
  }

  Future<void> closeSocket() async {
    final closed = await _p2pPlugin.closeSocket();
    _messageController.add("Socket closed: $closed");
  }

  Future<void> connect(String address) async {
    final success = await _p2pPlugin.connect(address);
    _messageController.add("Connection ${success ? "successful" : "failed"}");
  }

  void sendMessage(String message) {
    _p2pPlugin.sendStringToSocket(message);
  }

  void disposeService() {
    _wifiInfoSubscription?.cancel();
    _peersSubscription?.cancel();
    _messageController.close();
    _p2pPlugin.unregister();
  }

  @override
  void notifyListeners() {
    if (_messageController.isClosed) return;
    super.notifyListeners();
  }
}
