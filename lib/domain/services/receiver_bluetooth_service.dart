import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xsaev/data/models/user.dart';

class ReceiverBluetoothService {
  final String serviceUuid = "12345678-1234-5678-1234-56789abcdef0";
  final String characteristicUuid = "abcdef01-1234-5678-1234-56789abcdef0";

  BluetoothCharacteristic? _rxChar;
  BluetoothDevice? _connectedDevice;

  Future<void> startScanning(Function(double) onAmountReceived) async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    FlutterBluePlus.scanResults.listen((results) async {
      for (ScanResult r in results) {
        if (r.advertisementData.serviceUuids.contains(serviceUuid)) {
          _connectedDevice = r.device;
          await _connectToDevice(onAmountReceived);
          break;
        }
      }
    });
  }

  Future<void> _connectToDevice(Function(double) onAmountReceived) async {
    if (_connectedDevice == null) return;

    await FlutterBluePlus.stopScan();
    await _connectedDevice!.connect(autoConnect: false).catchError((_) {});

    List<BluetoothService> services =
        await _connectedDevice!.discoverServices();
    for (BluetoothService service in services) {
      for (BluetoothCharacteristic c in service.characteristics) {
        if (c.uuid.toString() == characteristicUuid) {
          _rxChar = c;
          await c.setNotifyValue(true);
          c.value.listen((value) async {
            final String data = utf8.decode(value);
            final Map<String, dynamic> transfer = jsonDecode(data);
            final double amount = transfer['amount'];
            final String from = transfer['from'];

            print(
                "Received transfer of \$${amount.toStringAsFixed(2)} from $from");

            // ✅ Update local balance
            await _updateWalletBalance(amount);

            // 🔁 Callback to UI
            onAmountReceived(amount);
          });
        }
      }
    }
  }

  Future<void> _updateWalletBalance(double amount) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('userData');
    if (userJson == null) return;

    final user = AppUser.fromJson(jsonDecode(userJson));
    final updatedUser = user.copyWith(balance: user.balance + amount);
    await prefs.setString('userData', jsonEncode(updatedUser.toJson()));
  }

  Future<void> dispose() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
    }
  }
}
