import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ui_layout.dart';
import '../models/ui_component.dart';
import '../../widgets/builders/toggle_builder.dart';
import '../../widgets/builders/gauge_builder.dart';
import '../../widgets/builders/chart_builder.dart';
import '../../widgets/builders/text_builder.dart';
import 'storage_service.dart';
import 'auth_service_new.dart';
import 'device_control_service.dart';
import 'package:logging/logging.dart';

/// Service responsible for building dynamic UI widgets from JSON layouts
class WidgetBuilderService {
  final Logger _logger = Logger('WidgetBuilderService');
  final StorageService _storageService;
  final AuthService _authService;
  final DeviceControlService _deviceControlService;
  
  // Cache for UI layouts to avoid repeated S3 downloads
  final Map<String, UiLayout> _layoutCache = {};

  WidgetBuilderService({
    required StorageService storageService,
    required AuthService authService,
    required DeviceControlService deviceControlService,
  }) : 
    _storageService = storageService,
    _authService = authService,
    _deviceControlService = deviceControlService;

  /// Fetch UI layout for a specific device
  Future<UiLayout> getDeviceLayout(String deviceId) async {
    try {
      // Check cache first
      if (_layoutCache.containsKey(deviceId)) {
        _logger.info('Using cached layout for device: $deviceId');
        return _layoutCache[deviceId]!;
      }
      
      // Get current user ID
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      
      // Fetch layout from S3
      final s3Key = 'users/$userId/devices/$deviceId.json';
      final layoutJson = await _storageService.getFile(s3Key);
      
      // Parse layout
      final layout = UiLayout.fromJson(json.decode(layoutJson));
      
      // Cache the layout
      _layoutCache[deviceId] = layout;
      
      return layout;
    } catch (e) {
      _logger.severe('Error fetching device layout: $e');
      
      // Return a fallback layout for error cases
      return UiLayout(
        title: 'Device Error',
        deviceId: deviceId,
        deviceType: 'unknown',
        components: [
          UiComponent(
            type: 'text',
            field: 'error',
            label: 'Error loading device UI',
            value: e.toString(),
          ),
        ],
      );
    }
  }

  /// Build a widget from a UI layout
  Widget buildFromLayout(UiLayout layout) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            layout.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: layout.components.map((component) => 
              _buildComponent(component, layout.deviceId)
            ).toList(),
          ),
        ),
      ],
    );
  }

  /// Build a widget for a specific device by ID
  Future<Widget> buildDeviceWidget(String deviceId) async {
    final layout = await getDeviceLayout(deviceId);
    return buildFromLayout(layout);
  }

  /// Build a component based on its type
  Widget _buildComponent(UiComponent component, String deviceId) {
    try {
      switch (component.type) {
        case 'header':
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              component.text ?? component.label ?? '',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
          );
          
        case 'text':
          return TextBuilder(component: component);
          
        case 'value':
          return TextBuilder(
            component: component,
            deviceId: deviceId,
            deviceControlService: _deviceControlService,
          );
          
        case 'switch':
          return ToggleBuilder(
            component: component,
            deviceId: deviceId,
            deviceControlService: _deviceControlService,
          );
          
        case 'gauge':
          return GaugeBuilder(
            component: component,
            deviceId: deviceId,
            deviceControlService: _deviceControlService,
          );
          
        case 'chart':
          return ChartBuilder(
            component: component,
            deviceId: deviceId,
            deviceControlService: _deviceControlService,
          );
          
        case 'status':
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  const Icon(Icons.circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(component.label ?? 'Status'),
                  const Spacer(),
                  Text('Online', style: TextStyle(color: Colors.green[700])),
                ],
              ),
            ),
          );
          
        default:
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text('Unknown component type: ${component.type}'),
          );
      }
    } catch (e) {
      _logger.warning('Error building component ${component.type}: $e');
      return Card(
        color: Colors.red[100],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text('Error: $e'),
        ),
      );
    }
  }

  /// Clear the layout cache
  void clearCache() {
    _layoutCache.clear();
  }
  
  /// Clear a specific device from the cache
  void clearDeviceCache(String deviceId) {
    _layoutCache.remove(deviceId);
  }
}