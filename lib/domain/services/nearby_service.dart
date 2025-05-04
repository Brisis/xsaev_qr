// nearby_connections_service.dart
import 'dart:math';
import 'dart:typed_data';
import 'dart:async';

import 'package:location/location.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

class NearbyConnectionsService {
  static final NearbyConnectionsService _instance =
      NearbyConnectionsService._internal();
  factory NearbyConnectionsService() => _instance;
  NearbyConnectionsService._internal();

  final Map<String, ConnectionInfo> _endpoints = {};
  String? _tempFileUri;
  final Map<int, String> _payloadMap = {};
  final Location _location = Location();

  final StreamController<ConnectionInitiationEvent>
      _connectionInitiatedController = StreamController.broadcast();
  final StreamController<ConnectionResultEvent> _connectionResultController =
      StreamController.broadcast();
  final StreamController<String> _disconnectedController =
      StreamController.broadcast();
  final StreamController<PayloadEvent> _payloadReceivedController =
      StreamController.broadcast();
  final StreamController<PayloadTransferUpdateEvent>
      _payloadTransferUpdateController = StreamController.broadcast();
  final StreamController<String> _endpointDiscoveredController =
      StreamController.broadcast();

  Stream<ConnectionInitiationEvent> get onConnectionInitiated =>
      _connectionInitiatedController.stream;
  Stream<ConnectionResultEvent> get onConnectionResult =>
      _connectionResultController.stream;
  Stream<String> get onDisconnected => _disconnectedController.stream;
  Stream<PayloadEvent> get onPayloadReceived =>
      _payloadReceivedController.stream;
  Stream<PayloadTransferUpdateEvent> get onPayloadTransferUpdate =>
      _payloadTransferUpdateController.stream;
  Stream<String> get onEndpointDiscovered =>
      _endpointDiscoveredController.stream;

  Map<String, ConnectionInfo> get endpoints => Map.from(_endpoints);

  Future<void> _checkPermissions() async {
    await [
      Permission.location,
      Permission.storage,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();
  }

  Future<bool> _checkLocationEnabled() async {
    if (!await _location.serviceEnabled()) {
      return await _location.requestService();
    }
    return true;
  }

  Future<void> startAdvertising(String userName, Strategy strategy) async {
    await _checkPermissions();
    if (!await _checkLocationEnabled())
      throw Exception('Location services required');

    await Nearby().startAdvertising(
      userName,
      strategy,
      onConnectionInitiated: (id, info) {
        _connectionInitiatedController.add(ConnectionInitiationEvent(id, info));
      },
      onConnectionResult: (id, status) {
        _connectionResultController.add(ConnectionResultEvent(id, status.name));
      },
      onDisconnected: (id) {
        _endpoints.remove(id);
        _disconnectedController.add(id);
      },
    );
  }

  Future<void> startDiscovery(String userName, Strategy strategy) async {
    await _checkPermissions();
    if (!await _checkLocationEnabled())
      throw Exception('Location services required');

    await Nearby().startDiscovery(
      userName,
      strategy,
      onEndpointFound: (id, name, serviceId) =>
          _endpointDiscoveredController.add(id),
      onEndpointLost: (id) => _endpointDiscoveredController.add('lost:$id'),
    );
  }

  Future<void> requestConnection(String userName, String endpointId) async {
    await Nearby().requestConnection(
      userName,
      endpointId,
      onConnectionInitiated: (id, info) {
        _connectionInitiatedController.add(ConnectionInitiationEvent(id, info));
      },
      onConnectionResult: (id, status) {
        _connectionResultController.add(ConnectionResultEvent(id, status.name));
      },
      onDisconnected: (id) {
        _endpoints.remove(id);
        _disconnectedController.add(id);
      },
    );
  }

  Future<void> acceptConnection(String endpointId, ConnectionInfo info) async {
    await Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (id, payload) => _handlePayload(id, payload),
      onPayloadTransferUpdate: (id, update) =>
          _handleTransferUpdate(id, update),
    );
    _endpoints[endpointId] = info;
  }

  void _handlePayload(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES) {
      final data = String.fromCharCodes(payload.bytes!);
      _payloadReceivedController.add(PayloadEvent(endpointId, data));

      if (data.contains(':')) {
        final parts = data.split(':');
        _payloadMap[int.parse(parts[0])] = parts[1];
      }
    } else if (payload.type == PayloadType.FILE) {
      _tempFileUri = payload.uri;
    }
  }

  void _handleTransferUpdate(String endpointId, PayloadTransferUpdate update) {
    _payloadTransferUpdateController
        .add(PayloadTransferUpdateEvent(endpointId, update));

    if (update.status == PayloadStatus.SUCCESS) {
      final fileName = _payloadMap[update.id];
      if (fileName != null && _tempFileUri != null) {
        _moveFile(_tempFileUri!, fileName);
        _payloadMap.remove(update.id);
      }
    }
  }

  Future<void> _moveFile(String uri, String fileName) async {
    final dir = await getExternalStorageDirectory();
    await Nearby().copyFileAndDeleteOriginal(uri, '${dir!.path}/$fileName');
  }

  Future<void> sendBytes(String endpointId, Uint8List bytes) async {
    await Nearby().sendBytesPayload(endpointId, bytes);
  }

  Future<void> sendFile(String endpointId, String filePath) async {
    final payloadId = await Nearby().sendFilePayload(endpointId, filePath);
    final fileName = filePath.split('/').last;
    _payloadMap[payloadId] = fileName;
    await sendBytes(
        endpointId, Uint8List.fromList('$payloadId:$fileName'.codeUnits));
  }

  Future<void> stopAll() async {
    await Nearby().stopAllEndpoints();
    _endpoints.clear();
  }

  void dispose() {
    _connectionInitiatedController.close();
    _connectionResultController.close();
    _disconnectedController.close();
    _payloadReceivedController.close();
    _payloadTransferUpdateController.close();
    _endpointDiscoveredController.close();
  }
}

class ConnectionInitiationEvent {
  final String endpointId;
  final ConnectionInfo info;

  ConnectionInitiationEvent(this.endpointId, this.info);
}

class ConnectionResultEvent {
  final String endpointId;
  final String status;

  ConnectionResultEvent(this.endpointId, this.status);
}

class PayloadEvent {
  final String endpointId;
  final dynamic data;

  PayloadEvent(this.endpointId, this.data);
}

class PayloadTransferUpdateEvent {
  final String endpointId;
  final PayloadTransferUpdate update;

  PayloadTransferUpdateEvent(this.endpointId, this.update);
}
