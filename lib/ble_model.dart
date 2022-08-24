import 'package:flutter_blue/flutter_blue.dart';

class BLEDevice {
  BluetoothDevice bluetoothDevice;
  int rssi;

  BLEDevice({required this.bluetoothDevice, required this.rssi});
}