import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/health_data.dart';

class BluetoothConnectionPage extends StatefulWidget {
  const BluetoothConnectionPage({Key? key}) : super(key: key);

  @override
  State<BluetoothConnectionPage> createState() =>
      _BluetoothConnectionPageState();
}

class _BluetoothConnectionPageState extends State<BluetoothConnectionPage> {
  final List<BluetoothDevice> _devices = [];
  bool _isScanning = false;
  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _checkBluetoothState();
    
    // Test toast on page load
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _showToast('Serial Bluetooth page loaded successfully!', isError: false);
      }
    });
  }

  @override
  void dispose() {
    _connection?.dispose();
    super.dispose();
  }

  // Return connection status when navigating back
  void _returnConnectionStatus() {
    if (_connectedDevice != null && _connection?.isConnected == true) {
      Navigator.pop(context, {
        'device': _connectedDevice,
        'connected': true,
      });
    } else {
      Navigator.pop(context, null);
    }
  }

  /* ──────────── Bluetooth State Check ──────────── */
  Future<void> _checkBluetoothState() async {
    try {
      FlutterBluetoothSerial.instance.state.then((state) {
        setState(() {
          _bluetoothState = state;
        });
        
        if (state == BluetoothState.STATE_OFF) {
          _showToast('Bluetooth must be turned on to scan for devices', isError: true);
        }
      });
    } catch (e) {
      _showToast('Failed to check Bluetooth state: $e', isError: true);
    }
  }

  /* ──────────── Toast Notifications ──────────── */
  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return;
    
    debugPrint('Showing toast: $message (isError: $isError)');
    
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isError ? Icons.error : Icons.info,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: isError ? Colors.red : Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      debugPrint('Failed to show toast with ScaffoldMessenger: $e');
      debugPrint('TOAST: $message');
    }
  }

  /* ──────────── Permissions ──────────── */
  Future<void> _requestPermissions() async {
    try {
      final results = await [
        Permission.bluetooth,
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,      // required by Android for Bluetooth scan
      ].request();
      
      // Check if any permission was denied
      for (final result in results.entries) {
        if (result.value.isDenied) {
          _showToast('${result.key.toString().split('.').last} permission is required', isError: true);
        }
      }
    } catch (e) {
      _showToast('Failed to request permissions: $e', isError: true);
    }
  }

  /* ──────────── Scanning ──────────── */
  Future<void> _startScan() async {
    try {
      // Check Bluetooth state before scanning
      if (_bluetoothState != BluetoothState.STATE_ON) {
        _showToast('Bluetooth must be turned on to scan for devices', isError: true);
        return;
      }

      setState(() {
        _devices.clear();
        _isScanning = true;
      });

      _showToast('Starting scan for Bluetooth devices...');

      // Get bonded devices (already paired)
      List<BluetoothDevice> bondedDevices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        _devices.addAll(bondedDevices);
      });

      // Start discovery for new devices
      FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
        setState(() {
          // Add device if not already in list
          if (!_devices.any((device) => device.address == result.device.address)) {
            _devices.add(result.device);
          }
        });
      });

      // Stop discovery after 10 seconds
      await Future.delayed(const Duration(seconds: 10));
      await FlutterBluetoothSerial.instance.cancelDiscovery();
      
      if (mounted) {
        setState(() => _isScanning = false);
        if (_devices.isEmpty) {
          _showToast('No Bluetooth devices found nearby', isError: true);
        } else {
          _showToast('Found ${_devices.length} device(s)');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        _showToast('Scan failed: $e', isError: true);
      }
    }
  }

  /* ──────────── Connect ──────────── */
  Future<void> _connectTo(BluetoothDevice device) async {
    try {
      _showToast('Connecting to ${device.name ?? 'device'}...');
      
      _connection = await BluetoothConnection.toAddress(device.address);
      
      if (_connection!.isConnected) {
        _connectedDevice = device;
        _showToast('Successfully connected to ${device.name ?? 'device'}');
        
        // Listen for incoming data
        _connection!.input!.listen((Uint8List data) {
          final incoming = String.fromCharCodes(data);
          _showToast('📥 Received: $incoming');
          debugPrint('📥 Received data: $incoming');
          
          // Process the data and update health data
          _processReceivedData(incoming);
        }).onDone(() {
          _showToast('Connection closed', isError: true);
          setState(() {
            _connection = null;
            _connectedDevice = null;
          });
        });
        
        setState(() {});
      } else {
        _showToast('Failed to establish connection', isError: true);
      }
      
    } catch (e) {
      String errorMessage = 'Connection failed';
      
      if (e.toString().contains('timeout')) {
        errorMessage = 'Connection timeout - device may be out of range';
      } else if (e.toString().contains('bluetooth')) {
        errorMessage = 'Bluetooth error - please check if Bluetooth is enabled';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission denied - please grant Bluetooth permissions';
      } else if (e.toString().contains('device')) {
        errorMessage = 'Device not found or not responding';
      } else {
        errorMessage = 'Connection failed: $e';
      }
      
      if (mounted) {
        _showToast(errorMessage, isError: true);
      }
    }
  }

  /* ──────────── Process Received Data ──────────── */
  void _processReceivedData(String data) {
    try {
      // Get the HealthData provider and update it
      final healthData = Provider.of<HealthData>(context, listen: false);
      healthData.parseBluetoothData(data);
      
      debugPrint('📥 Health data updated from Bluetooth');
    } catch (e) {
      debugPrint('📥 Error processing received data: $e');
    }
  }

  /* ──────────── Send Data ──────────── */
  Future<void> _sendData(String data) async {
    if (_connection?.isConnected == true) {
      try {
        _connection!.output.add(Uint8List.fromList(data.codeUnits));
        await _connection!.output.allSent;
        _showToast('📤 Sent: $data');
      } catch (e) {
        _showToast('Failed to send data: $e', isError: true);
      }
    } else {
      _showToast('Not connected to any device', isError: true);
    }
  }

  /* ──────────── Disconnect ──────────── */
  Future<void> _disconnect() async {
    if (_connection?.isConnected == true) {
      await _connection!.close();
      setState(() {
        _connection = null;
        _connectedDevice = null;
      });
      _showToast('Disconnected');
    }
  }

  /* ──────────── UI ──────────── */
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('Serial Bluetooth'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _returnConnectionStatus,
        ),
        actions: [
          if (_connection?.isConnected == true)
            IconButton(
              icon: const Icon(Icons.bluetooth_disabled),
              onPressed: _disconnect,
              tooltip: 'Disconnect',
            ),
        ],
      ),
      body: Column(
        children: [
          // Connection status
          if (_connection?.isConnected == true)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade100,
              child: Row(
                children: [
                  Icon(Icons.bluetooth_connected, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Connected to: ${_connectedDevice?.name ?? 'Unknown'}',
                    style: TextStyle(color: Colors.green.shade800),
                  ),
                ],
              ),
            ),
          
          // Control buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isScanning ? null : _startScan,
                    child: Text(_isScanning ? 'Scanning…' : 'Scan for Devices'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _showToast('Test toast message!', isError: false);
                    _showToast('Test error message!', isError: true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Test Toast'),
                ),
              ],
            ),
          ),
          
          // Send data section (when connected)
          if (_connection?.isConnected == true)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Enter message to send',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: _sendData,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _sendData('Hello from Flutter!'),
                    child: const Text('Send'),
                  ),
                ],
              ),
            ),
          
          // Device list
          Expanded(
            child: ListView.builder(
              itemCount: _devices.length,
              itemBuilder: (_, i) {
                final device = _devices[i];
                final isConnected = _connectedDevice?.address == device.address;
                
                return Card(
                  child: ListTile(
                    leading: Icon(
                      isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                      color: isConnected ? Colors.green : Colors.grey,
                    ),
                    title: Text(device.name ?? 'Unknown Device'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(device.address),
                        Text('Bonded: ${device.isBonded ? 'Yes' : 'No'}'),
                      ],
                    ),
                    trailing: ElevatedButton(
                      onPressed: isConnected ? null : () => _connectTo(device),
                      child: Text(isConnected ? 'Connected' : 'Connect'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
