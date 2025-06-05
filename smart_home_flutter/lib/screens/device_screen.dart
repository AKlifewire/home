import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:convert';

class DeviceScreen extends StatefulWidget {
  final String deviceId;

  const DeviceScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  Map<String, dynamic>? _uiJson;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUiJson();
  }

  Future<void> _fetchUiJson() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = GraphQLRequest<String>(
        document: '''
          query GetUiJson(\$deviceId: String!) {
            getUiJson(deviceId: \$deviceId) {
              statusCode
              deviceId
              uiJson
            }
          }
        ''',
        variables: {
          'deviceId': widget.deviceId,
        },
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty) {
        setState(() {
          _error = response.errors.first.message;
          _isLoading = false;
        });
        return;
      }

      final data = response.data;
      if (data == null) {
        setState(() {
          _error = 'No data returned';
          _isLoading = false;
        });
        return;
      }

      final jsonData = jsonDecode(data);
      final uiJsonString = jsonData['getUiJson']['uiJson'];
      final uiJson = jsonDecode(uiJsonString);

      setState(() {
        _uiJson = uiJson;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_uiJson?['title'] ?? 'Device'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUiJson,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _uiJson == null
                  ? const Center(child: Text('No UI configuration found'))
                  : _buildDynamicUi(),
    );
  }

  Widget _buildDynamicUi() {
    final components = _uiJson!['components'] as List;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: components.length,
      itemBuilder: (context, index) {
        final component = components[index];
        return _buildComponent(component);
      },
    );
  }

  Widget _buildComponent(Map<String, dynamic> component) {
    final type = component['type'];
    
    switch (type) {
      case 'header':
        return _buildHeader(component);
      case 'status':
        return _buildStatus(component);
      case 'toggle':
        return _buildToggle(component);
      case 'gauge':
        return _buildGauge(component);
      case 'chart':
        return _buildChart(component);
      default:
        return ListTile(
          title: Text('Unknown component type: $type'),
        );
    }
  }

  Widget _buildHeader(Map<String, dynamic> component) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            component['title'] ?? '',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (component['subtitle'] != null)
            Text(
              component['subtitle'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
        ],
      ),
    );
  }

  Widget _buildStatus(Map<String, dynamic> component) {
    return Card(
      child: ListTile(
        title: Text(component['label'] ?? 'Status'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Connected',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildToggle(Map<String, dynamic> component) {
    return Card(
      child: SwitchListTile(
        title: Text(component['label'] ?? 'Toggle'),
        value: false,
        onChanged: (value) {
          _controlDevice(component['field'], value);
        },
      ),
    );
  }

  Widget _buildGauge(Map<String, dynamic> component) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              component['label'] ?? 'Gauge',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.thermostat, size: 32),
                const SizedBox(width: 8),
                Text(
                  '22.5 ${component['unit'] ?? ''}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Map<String, dynamic> component) {
    return Card(
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              component['label'] ?? 'Chart',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: Text('Chart data will appear here'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _controlDevice(String? field, dynamic value) async {
    if (field == null) return;

    try {
      final request = GraphQLRequest<String>(
        document: '''
          mutation ControlRelay(\$deviceId: String!, \$relay: String!, \$state: Boolean!) {
            controlRelay(deviceId: \$deviceId, relay: \$relay, state: \$state) {
              statusCode
              success
            }
          }
        ''',
        variables: {
          'deviceId': widget.deviceId,
          'relay': field,
          'state': value,
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.errors.first.message}')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Device control sent: $field = $value')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}