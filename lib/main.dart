import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:rxdart/rxdart.dart';

import 'ble_model.dart';
import 'connection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  FlutterBlue flutterBlueInstance = FlutterBlue.instance;
  Map<String, BLEDevice> deviceMap = <String, BLEDevice>{};

  BehaviorSubject<List<BLEDevice>> scanDeviceListStream =
      BehaviorSubject<List<BLEDevice>>.seeded([]);

  dynamic scanDevices;

  @override
  void initState() {
    super.initState();
  }

  scanForDevices() {
    flutterBlueInstance.state.listen((state) {
      if (state == BluetoothState.off) {
        debugPrint("Bluetooth is OFF");
      } else if (state == BluetoothState.on) {
        debugPrint("Bluetooth is ON");
        deviceMap.clear();
        // scanDeviceList.clear();
        scanDeviceListStream.add([]);
        startScan();
      }
    });
  }

  void startScan() async {
    debugPrint("startScan");

    // flutterBlueInstance.startScan(allowDuplicates: true);

    List<BLEDevice> scanDeviceList = [];
    // this line will start scanning bluetooth devices
    scanDevices = flutterBlueInstance.scan(allowDuplicates: true).listen(
      (scanResult) async {
        if (scanResult.device.name.isNotEmpty) {
          debugPrint(
              "ScanResult: ${scanResult.device.name}, rssi: ${scanResult.rssi}, ID: ${scanResult.device.id.id}");

          if (!deviceMap.containsKey(scanResult.device.id.id)) {
            deviceMap[scanResult.device.id.id.toString()] = BLEDevice(
                bluetoothDevice: scanResult.device, rssi: scanResult.rssi);
            scanDeviceList = deviceMap.values.toList();
          } else {
            debugPrint("Already added");
            deviceMap.update(
                scanResult.device.id.id,
                (value) => BLEDevice(
                    bluetoothDevice: scanResult.device, rssi: scanResult.rssi));
            scanDeviceList[scanDeviceList.indexWhere((element) =>
                    element.bluetoothDevice.id.id == scanResult.device.id.id)] =
                BLEDevice(
                    bluetoothDevice: scanResult.device, rssi: scanResult.rssi);
          }
          scanDeviceListStream.add(scanDeviceList);
        }
      },
    );
  }

  stopScan() {
    flutterBlueInstance.stopScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          StreamBuilder<bool>(
              stream: flutterBlueInstance.isScanning,
              builder: (context, snapshot) {
                bool isScanning = snapshot.data ?? false;
                return isScanning
                    ? IconButton(
                        onPressed: () {
                          stopScan();
                        },
                        icon: const Icon(Icons.bluetooth_audio))
                    : IconButton(
                        onPressed: () {
                          scanForDevices();
                        },
                        icon: const Icon(Icons.bluetooth));
              })
        ],
      ),
      body: StreamBuilder<List<BLEDevice>>(
          stream: scanDeviceListStream,
          builder: (context, snapshot) {
            List<BLEDevice> deviceList = snapshot.data ?? [];
            return deviceList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: const [
                        Icon(
                          Icons.bluetooth_audio,
                          size: 100,
                        ),
                        Text(
                          "No device found",
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    itemBuilder: (BuildContext context, int index) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Card(
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.bluetooth),
                            ),
                            title: Text(deviceList
                                .elementAt(index)
                                .bluetoothDevice
                                .name),
                            subtitle: Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    deviceList
                                        .elementAt(index)
                                        .bluetoothDevice
                                        .id
                                        .id,
                                  ),
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.signal_cellular_4_bar,
                                        size: 16,
                                      ),
                                      const SizedBox(
                                        width: 4,
                                      ),
                                      Text(
                                          "${deviceList.elementAt(index).rssi.toString()} dBm"),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            trailing: ElevatedButton(
                              child: const Text("Connect"),
                              onPressed: () {
                                debugPrint("Start connection");

                                flutterBlueInstance.stopScan();
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => ConnectionPage(
                                              bleDevice:
                                                  deviceList.elementAt(index),
                                              flutterBlueInstance:
                                                  flutterBlueInstance,
                                            )));
                              },
                            ),
                          ),
                        ),
                      );
                    },
                    itemCount: deviceList.length,
                  );
          }),
    );
  }

  @override
  void dispose() {
    super.dispose();
    scanDevices.cancel();
  }
}
