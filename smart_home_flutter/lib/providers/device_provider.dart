import 'package:flutter/foundation.dart';
import '../models/device.dart';
import '../services/backend_service.dart';
import '../services/layout_service.dart';

class DeviceProvider with ChangeNotifier {
  final BackendService _backendService = BackendService();
  final LayoutService _layoutService = LayoutService();
  
  List<Device> _devices = [];
  Map<String, dynamic> _deviceLayouts = {};
  bool _isLoading = false;
  String? _error;

  List<Device> get devices => [..._devices];
  Map<String, dynamic> get deviceLayouts => _deviceLayouts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchDevices() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Fetch devices from backend
      _devices = await _backendService.fetchDevices();
      
      // Fetch layouts for each device
      await _fetchDeviceLayouts();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load devices. Please try again.';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchDeviceLayouts() async {
    for (final device in _devices) {
      try {
        final layout = await _layoutService.fetchDeviceLayout(
          device.id,
          device.type,
        );
        _deviceLayouts[device.id] = layout;
      } catch (e) {
        // If layout fetch fails, we'll use default layout
        // which will be handled by the UI renderer
      }
    }
    notifyListeners();
  }

  Future<void> updateDeviceStatus(String deviceId, Map<String, dynamic> status) async {
    try {
      // Update local state immediately for responsive UI
      final deviceIndex = _devices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex != -1) {
        _devices[deviceIndex] = _devices[deviceIndex].copyWith(status: status);
        notifyListeners();
      }

      // Send update to backend
      await _backendService.updateDeviceStatus(deviceId, status);
    } catch (e) {
      // Revert local state if update fails
      await fetchDevices();
    }
  }

  Future<Device> registerDevice(String name, String type) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      // Register device with backend
      final newDevice = await _backendService.registerDevice(name, type);
      
      // Add to local list
      _devices.add(newDevice);
      
      _isLoading = false;
      notifyListeners();
      
      return newDevice;
    } catch (e) {
      _error = 'Failed to register device. Please try again.';
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> testBackendConnection() async {
    try {
      return await _backendService.testConnection();
    } catch (e) {
      return false;
    }
  }
}