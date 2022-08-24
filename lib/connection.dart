import 'package:demo_bluetooth/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

import 'ble_model.dart';

class ConnectionPage extends StatefulWidget {
  const ConnectionPage(
      {Key? key, required this.bleDevice, required this.flutterBlueInstance})
      : super(key: key);
  final BLEDevice bleDevice;
  final FlutterBlue flutterBlueInstance;

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  List<BluetoothService> services = [];

  @override
  void initState() {
    super.initState();
    try {
      connectDevice();
    } catch (e) {
      debugPrint("Error: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Connection Page"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<BluetoothDeviceState>(
            stream: widget.bleDevice.bluetoothDevice.state,
            builder: (context, snapshot) {
              debugPrint("ConnectionPage State: ${snapshot.data}");
              if (snapshot.data == BluetoothDeviceState.connected) {
                getServices();
              }
              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.bleDevice.bluetoothDevice.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            height: 2,
                          ),
                          Text(widget.bleDevice.bluetoothDevice.id.id,
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      snapshot.data == BluetoothDeviceState.connected
                          ? ElevatedButton(
                        child: const Text(
                          "Disconnect",
                          style: TextStyle(fontSize: 16),
                        ),
                        onPressed: () {
                          try {
                            disconnectDevice();
                          } catch (e) {
                            debugPrint("Error: ${e.toString()}");
                          }
                        },
                      )
                          : ElevatedButton(
                        child: const Text(
                          "Connect",
                          style: TextStyle(fontSize: 16),
                        ),
                        onPressed: () {
                          try {
                            connectDevice();
                          } catch (e) {
                            debugPrint("Error: ${e.toString()}");
                          }
                        },
                      )
                    ],
                  ),
                  Expanded(
                    child: StreamBuilder<bool>(
                        stream: widget
                            .bleDevice.bluetoothDevice.isDiscoveringServices,
                        builder: (context, snapshot) {
                          debugPrint(
                              "ConnectionPage isDiscoveringServices: ${snapshot
                                  .data}");

                          return Padding(
                            padding: const EdgeInsets.only(top: 20.0),
                            child: Center(
                              child: services.isEmpty
                                  ? const CircularProgressIndicator()
                              /*ElevatedButton(
                                      child: const Text(
                                        "Get Services",
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      onPressed: () {
                                        getServices();
                                      },
                                    )*/
                                  : StreamBuilder<List<BluetoothService>>(
                                  stream: widget
                                      .bleDevice.bluetoothDevice.services,
                                  builder: (context, snapshot) {
                                    return _buildExpandableList(services);
                                  }),
                            ),
                          );
                        }),
                  )
                ],
              );
            }),
      ),
    );
  }

  Future<void> connectDevice() async {
    await widget.bleDevice.bluetoothDevice.connect();
  }

  Future<void> disconnectDevice() async {
    await widget.bleDevice.bluetoothDevice.disconnect();
  }

  Future<void> getServices() async {
    services = await widget.bleDevice.bluetoothDevice.discoverServices();
    debugPrint("Services: $services");
  }

  Widget _buildExpandableList(List<BluetoothService> services) {
    return ListView.builder(
      itemCount: services.length,
      itemBuilder: (context, index) {
        return ServiceTile(
            service: services.elementAt(index),
            characteristicTiles: services
                .elementAt(index)
                .characteristics
                .map((c) =>
                CharacteristicTile(
                  characteristic: c,
                  descriptorTiles: c.descriptors
                      .map((d) => DescriptorTile(descriptor: d))
                      .toList(),
                ))
                .toList());
      },
    );
  }
}

class ServiceTile extends StatelessWidget {
  const ServiceTile(
      {Key? key, required this.service, required this.characteristicTiles})
      : super(key: key);

  final BluetoothService service;
  final List<CharacteristicTile> characteristicTiles;

  @override
  Widget build(BuildContext context) {
    String uuid = service.uuid.toString().toUpperCase().substring(4, 8);
    String serviceName = "Unknown Service";
    switch (uuid) {
      case "1800":
        serviceName = "Generic Access";
        break;
      case "1801":
        serviceName = "Generic Attribute";
        break;
    }
    if (characteristicTiles.isNotEmpty) {
      return ExpansionTile(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(serviceName),
            Text(
              'UUID: 0x$uuid',
            )
          ],
        ),
        children: characteristicTiles,
      );
    } else {
      return ListTile(
        title: const Text('Service'),
        subtitle: Text('UUID: 0x$uuid'),
      );
    }
  }
}

class CharacteristicTile extends StatelessWidget {
  const CharacteristicTile(
      {Key? key, required this.characteristic, required this.descriptorTiles})
      : super(key: key);

  final BluetoothCharacteristic characteristic;
  final List<DescriptorTile> descriptorTiles;

  @override
  Widget build(BuildContext context) {
    String uuid = characteristic.uuid.toString().toUpperCase().substring(4, 8);
    String characteristicName = "Unknown Characteristic";
    switch (uuid) {
      case "2A00":
        characteristicName = "Device Name";
        break;
      case "2A01":
        characteristicName = "Appearance";
        break;
      case "2A04":
        characteristicName = "Peripheral Preferred Connection Parameter";
        break;
      case "2A05":
        characteristicName = "Service Changed";
        break;
      case "2AA6":
        characteristicName = "Central Address Resolution";
        break;
    }
    List<String> propertiesList = [];
    if (characteristic.properties.read) {
      propertiesList.add("READ");
    }
    if (characteristic.properties.write) {
      propertiesList.add("WRITE");
    }
    if (characteristic.properties.writeWithoutResponse) {
      propertiesList.add("WRITE NO RESPONSE");
    }
    if (characteristic.properties.notify) {
      propertiesList.add("NOTIFY");
    }
    if (characteristic.properties.indicate) {
      propertiesList.add("INDICATE");
    }
    debugPrint(
        "Characteristic name: $characteristicName, Properties: $propertiesList, Main: ${characteristic
            .properties}");
    return StreamBuilder<List<int>>(
      stream: characteristic.value,
      initialData: characteristic.lastValue,
      builder: (context, snapshot) {
        debugPrint(
            "Characteristic value: ${snapshot.data}, Text: ${String
                .fromCharCodes(snapshot.data ?? [])}");
        return ExpansionTile(
          title: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(characteristicName),
              Text(
                'UUID: 0x$uuid',
              ),
              Text(
                  "Properties: ${propertiesList.join(", ")}",
              )
            ],
          ),
          subtitle: Text(String.fromCharCodes(snapshot.data ?? []), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),),
          trailing: characteristic.properties.read
              ? IconButton(
            icon: Icon(
              Icons.file_download,
              color: Theme
                  .of(context)
                  .iconTheme
                  .color
                  ?.withOpacity(0.5),
            ),
            onPressed: () {
              characteristic.read();
            },
          )
              : const SizedBox.shrink(),
          children: descriptorTiles,
        );
      },
    );
  }
}

class DescriptorTile extends StatelessWidget {
  const DescriptorTile({Key? key, required this.descriptor}) : super(key: key);
  final BluetoothDescriptor descriptor;

  @override
  Widget build(BuildContext context) {
    String uuid = descriptor.uuid.toString().toUpperCase().substring(4, 8);

    return ListTile(
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Descriptor'),
          Text(
            'UUID: 0x$uuid',
          )
        ],
      ),
      subtitle: StreamBuilder<List<int>>(
          stream: descriptor.value,
          builder: (context, snapshot) {
            return Text(snapshot.data.toString());
          }),
    );
  }
}
