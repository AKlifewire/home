import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/models/ui_component.dart';
import '../core/services/device_control_service.dart';
import 'builders/smart_device_widget_factory.dart';

/// A widget that dynamically renders a UI component based on its type
class DynamicComponent extends ConsumerWidget {
  final UiComponent component;

  const DynamicComponent({
    Key? key,
    required this.component,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controlService = ref.watch(deviceControlServiceProvider);
    final widgetFactory = SmartDeviceWidgetFactory(controlService);
    
    return widgetFactory.createWidget(component);
  }
}

/// A widget that renders a complete device UI with multiple screens
class DeviceUI extends ConsumerStatefulWidget {
  final String deviceId;
  final List<UiScreen> screens;

  const DeviceUI({
    Key? key,
    required this.deviceId,
    required this.screens,
  }) : super(key: key);

  @override
  ConsumerState<DeviceUI> createState() => _DeviceUIState();
}

class _DeviceUIState extends ConsumerState<DeviceUI> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.screens.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If there's only one screen, don't show tabs
    if (widget.screens.length == 1) {
      return _buildScreenContent(widget.screens.first);
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: widget.screens.map((screen) => Tab(text: screen.title)).toList(),
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.screens.map(_buildScreenContent).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildScreenContent(UiScreen screen) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: screen.widgets.map((widget) {
            final component = UiComponent.fromWidget(widget.toJson());
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: DynamicComponent(component: component),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Data model for a UI screen
class UiScreen {
  final String id;
  final String title;
  final List<UiWidget> widgets;

  UiScreen({
    required this.id,
    required this.title,
    required this.widgets,
  });

  factory UiScreen.fromJson(Map<String, dynamic> json) {
    return UiScreen(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      widgets: (json['widgets'] as List<dynamic>?)
              ?.map((widget) => UiWidget.fromJson(widget as Map<String, dynamic>))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'widgets': widgets.map((widget) => widget.toJson()).toList(),
  };
}

/// Data model for a UI widget
class UiWidget {
  final String type;
  final String id;
  final String title;
  final Map<String, dynamic> properties;

  UiWidget({
    required this.type,
    required this.id,
    required this.title,
    required this.properties,
  });

  factory UiWidget.fromJson(Map<String, dynamic> json) {
    return UiWidget(
      type: json['type'] as String? ?? 'text',
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      properties: json['properties'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'title': title,
    'properties': properties,
  };
}