import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import '../models/device.dart';
import '../services/backend_service.dart';
import '../services/layout_service.dart';

// Device state
class DeviceState {
  final List<Device> devices;
  final Map<String, dynamic> deviceLayouts;
  final bool isLoading;
  final String? error;

  DeviceState({
    this.devices = const [],
    this.deviceLayouts = const {},
    this.isLoading = false,
    this.error,
  });

  DeviceState copyWith({
    List<Device>? devices,
    Map<String, dynamic>? deviceLayouts,
    bool? isLoading,
    String? error,
  }) {
    return DeviceState(
      devices: devices ?? this.devices,
      deviceLayouts: deviceLayouts ?? this.deviceLayouts,
      isLoading: isLoading ?? this.isLoading,
      error: error,  // Null if not provided
    );
  }
}

// Device notifier
class DeviceNotifier extends StateNotifier<DeviceState> {
  final BackendService _backendService = BackendService();
  final LayoutService _layoutService = LayoutService();

  DeviceNotifier() : super(DeviceState());

  Future<void> fetchDevices() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Fetch devices from backend
      final devices = await _backendService.fetchDevices();
      
      // Create a new map for layouts
      final Map<String, dynamic> layouts = {};
      
      // Fetch layouts for each device
      for (final device in devices) {
        try {
          final layout = await _layoutService.fetchDeviceLayout(
            device.id,
            device.type,
          );
          layouts[device.id] = layout;
        } catch (e) {
          safePrint('Error fetching layout for device ${device.id}: $e');
          // If layout fetch fails, we'll use default layout
        }
      }
      
      state = state.copyWith(
        devices: devices,
        deviceLayouts: layouts,
        isLoading: false,
      );
    } catch (e) {
      safePrint('Error fetching devices: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load devices. Please try again.',
      );
    }
  }

  Future<void> updateDeviceStatus(String deviceId, Map<String, dynamic> status) async {
    try {
      // Find the device
      final deviceIndex = state.devices.indexWhere((d) => d.id == deviceId);
      if (deviceIndex == -1) return;
      
      // Create a new list with the updated device
      final updatedDevices = List<Device>.from(state.devices);
      updatedDevices[deviceIndex] = updatedDevices[deviceIndex].copyWith(
        status: status,
        updatedAt: DateTime.now(),
      );
      
      // Update state immediately for responsive UI
      state = state.copyWith(devices: updatedDevices);
      
      // Send update to backend
      await _backendService.updateDeviceStatus(deviceId, status);
    } catch (e) {
      safePrint('Error updating device status: $e');
      // Revert to original state by fetching devices again
      await fetchDevices();
    }
  }

  Future<Device?> registerDevice(String name, String type) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Register device with backend
      final newDevice = await _backendService.registerDevice(name, type);
      
      // Add to local list
      final updatedDevices = [...state.devices, newDevice];
      
      // Fetch layout for the new device
      try {
        final layout = await _layoutService.fetchDeviceLayout(
          newDevice.id,
          newDevice.type,
        );
        
        final updatedLayouts = Map<String, dynamic>.from(state.deviceLayouts);
        updatedLayouts[newDevice.id] = layout;
        
        state = state.copyWith(
          devices: updatedDevices,
          deviceLayouts: updatedLayouts,
          isLoading: false,
        );
      } catch (e) {
        safePrint('Error fetching layout for new device: $e');
        state = state.copyWith(
          devices: updatedDevices,
          isLoading: false,
        );
      }
      
      return newDevice;
    } catch (e) {
      safePrint('Error registering device: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to register device. Please try again.',
      );
      return null;
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

// Provider
final deviceProvider = StateNotifierProvider<DeviceNotifier, DeviceState>((ref) {
  return DeviceNotifier();
});