import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: WifiSetter(),
    );
  }
}

class WifiSetter extends StatefulWidget {
  @override
  _WifiSetterState createState() => _WifiSetterState();
}

class _WifiSetterState extends State<WifiSetter> {
  //final String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String SERVICE_UUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
//  final String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  final String CHARACTERISTIC_UUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  final String TARGET_DEVICE_NAME = "Nordic_UART";

  FlutterBlue flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult> scanSubscription;

  BluetoothDevice targetDevice;
  BluetoothCharacteristic targetCharacteristic;

  String connectionText = "";

  @override
  void initState() {
    startScan();
  }

  void startScan() {
    setState(() {
      connectionText = "Start scanning";
    });

    scanSubscription = flutterBlue.scan().listen((scanResult) {
      print(scanResult.device.name);
      if (scanResult.device.name.contains(TARGET_DEVICE_NAME)) {
        stopScan();
        setState(() {
          connectionText = "Found Target Device";
        });
        print(connectionText);
        targetDevice = scanResult.device;
        connectToDevice();
      }
    }, onDone: ()=> stopScan());
  }

  void stopScan() {
    scanSubscription?.cancel();
    scanSubscription = null;
  }

  void connectToDevice() async {
    if(targetDevice == null) return;

    connectionText = 'Device connecting';
    await targetDevice.connect();

    setState(() {
      connectionText = "Device Connected";
    });
    discoverServices();
  }

  void disconnectFromDevice(){
    if(targetDevice == null) return;
    targetDevice.disconnect();
    setState(() {
      connectionText = "Device Disconnected";
    });
  }

  void discoverServices() async {
    if(targetDevice == null) return;

    List<BluetoothService> services = await targetDevice.discoverServices();
    services.forEach((service){
      if(service.uuid.toString() == SERVICE_UUID){
        service.characteristics.forEach((characteristic){
          if(characteristic.uuid.toString() == CHARACTERISTIC_UUID){
            targetCharacteristic = characteristic;
            setState(() {
              connectionText = "All ready with ${targetDevice.name}";
            });
          }
        });
      }
    });
  }

  void writeData(String data) async {
    if(targetCharacteristic == null) return;
    List<int> bytes = utf8.encode(data);
    await targetCharacteristic.write(bytes);
  }

  TextEditingController wifiNameController = TextEditingController();
  TextEditingController wifiPasswordController = TextEditingController();

  void submitActions(){
    var wifiData = '${wifiNameController.text},${wifiPasswordController.text}';
    writeData(wifiData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bluetooth test'),
      ),
      body: Container(
        child: targetCharacteristic == null ? Center(
          child: Text(
            "Waiting...",
            style: TextStyle(fontSize: 34, color: Colors.green),
          ),
        )
            : Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: wifiNameController,
                decoration: InputDecoration(labelText: 'Wifi Name'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: wifiPasswordController,
                decoration: InputDecoration(labelText: 'Wifi Password'),
              ),
            ),
            RaisedButton(
              child: Text('Send'),
              color: Colors.indigoAccent,
              onPressed: submitActions,
            )
          ],
        )
      ),
    );
  }
}
