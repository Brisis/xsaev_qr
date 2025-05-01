import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

class WiFiDirectService {
  final FlutterP2pConnection _plugin = FlutterP2pConnection();
  WifiP2PInfo? wifiInfo;

  Future<void> init() async {
    await _plugin.initialize();
    await _plugin.register();
    _plugin.streamWifiP2PInfo().listen((info) => wifiInfo = info);
  }

  Future<bool> askPermissions() async {
    // final granted1 = await _plugin.askConnectionPermissions();
    final granted1 = await _plugin.checkWifiEnabled();

    final granted2 = await _plugin.askStoragePermission();
    return granted1 && granted2;
  }

  Future<bool> discover() => _plugin.discover();
  Future<bool?> connect(String deviceAddress) => _plugin.connect(deviceAddress);

  Future<void> startSocket({
    required Function(String msg) onMessage,
    required Function(String name, String address) onConnect,
  }) async {
    if (wifiInfo == null) return;

    await _plugin.startSocket(
      groupOwnerAddress: wifiInfo!.groupOwnerAddress,
      downloadPath: "/storage/emulated/0/Download/",
      onConnect: onConnect,
      // onCloseSocket: () => print("Socket closed."),
      transferUpdate: (_) {},
      receiveString: (msg) async => onMessage(msg),
      maxConcurrentDownloads: 2,
      deleteOnError: true,
    );
  }

  Future<void> connectToSocket({
    required Function(String msg) onMessage,
    required Function(String address) onConnect,
  }) async {
    if (wifiInfo == null) return;

    await _plugin.connectToSocket(
      groupOwnerAddress: wifiInfo!.groupOwnerAddress,
      downloadPath: "/storage/emulated/0/Download/",
      onConnect: onConnect,
      // onCloseSocket: () => print("Closed socket."),
      transferUpdate: (_) {},
      receiveString: (msg) async => onMessage(msg),
      maxConcurrentDownloads: 2,
      deleteOnError: true,
    );
  }

  Future<void> sendMessage(String msg) async {
    await _plugin.sendStringToSocket(msg);
  }

  Future<void> closeSocket() async {
    await _plugin.closeSocket();
  }

  Future<List<DiscoveredPeers>> getPeers() async {
    return _plugin.discover().then((_) => []);
  }
}
