import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothTransferService {
  final String serviceUUID = "12345678-1234-1234-1234-1234567890ab";
  final String characteristicUUID = "abcd1234-5678-90ab-cdef-1234567890ab";

  Future<void> sendPaymentOverBluetooth(
      String recipientAccount, double amount) async {
    try {
      // Scan for device
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
      BluetoothDevice? targetDevice;

      // await for (ScanResult result in FlutterBluePlus.scanResults) {
      //   if (result.advertisementData.serviceUuids.contains(serviceUUID)) {
      //     targetDevice = result.device;
      //     break;
      //   }
      // }

      FlutterBluePlus.scanResults.listen((List<ScanResult> results) async {
        for (ScanResult result in results) {
          if (result.advertisementData.serviceUuids.contains(serviceUUID)) {
            targetDevice = result.device;
            FlutterBluePlus.stopScan();
            // await connectToDevice(); // Your connection logic here
            break;
          }
        }
      });

      // await FlutterBluePlus.stopScan();

      if (targetDevice == null) {
        throw Exception("Target device not found.");
      }

      await targetDevice!.connect();
      List<BluetoothService> services = await targetDevice!.discoverServices();

      for (BluetoothService service in services) {
        if (service.uuid.toString() == serviceUUID) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString() == characteristicUUID) {
              String payload = jsonEncode({
                "account": recipientAccount,
                "amount": amount,
              });
              await c.write(utf8.encode(payload));
              await targetDevice!.disconnect();
              return;
            }
          }
        }
      }

      throw Exception("Service or characteristic not found.");
    } catch (e) {
      print("Bluetooth error: $e");
    }
  }
}
