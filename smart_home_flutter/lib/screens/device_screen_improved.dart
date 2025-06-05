import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:convert';
import '../widgets/dynamic_component.dart';

class DeviceScreen extends StatefulWidget {
  final String deviceId;

  const DeviceScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  Map<String, dynamic>? _uiJson;
  Map<String, dynamic> _deviceState = {};
  bool _isLoading = true;
  String? _error;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _fetchUiJson();
    _setupSubscription();
  }

  @override
  void dispose() {
    // Cancel subscription if needed
    super.dispose();
  }

  Future<void> _setupSubscription() async {
    try {
      final subscription = Amplify.API.subscribe(
        GraphQLRequest<String>(
          document: '''
            subscription OnDeviceUpdate(\$deviceId: String!) {
              onDeviceUpdate(deviceId: \$deviceId) {
                deviceId
                state
                timestamp
              }
            }
          ''',
          variables: {
            'deviceId': widget.deviceId,
          },
        ),
      );

      subscription.listen(
        (event) {
          if (event.data != null) {
            final data = jsonDecode(event.data!);
            final state = jsonDecode(data['onDeviceUpdate']['state']);
            setState(() {
              _deviceState = {..._deviceState, ...state};
            });
          }
        },
        onError: (error) {
          print('Subscription error: $error');
        },
      );
    } catch (e) {
      print('Error setting up subscription: $e');
    }
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

      // Fetch initial device state
      _fetchDeviceState();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchDeviceState() async {
    try {
      final request = GraphQLRequest<String>(
        document: '''
          query GetDeviceState(\$deviceId: String!) {
            getDeviceState(deviceId: \$deviceId) {
              deviceId
              state
              timestamp
            }
          }
        ''',
        variables: {
          'deviceId': widget.deviceId,
        },
      );

      final response = await Amplify.API.query(request: request).response;

      if (response.errors.isNotEmpty || response.data == null) {
        return;
      }

      final data = jsonDecode(response.data!);
      if (data['getDeviceState'] != null && data['getDeviceState']['state'] != null) {
        final state = jsonDecode(data['getDeviceState']['state']);
        setState(() {
          _deviceState = state;
        });
      }
    } catch (e) {
      print('Error fetching device state: $e');
    }
  }

  Future<void> _controlDevice(String field, dynamic value) async {
    try {
      // Show optimistic update
      setState(() {
        _deviceState = {..._deviceState, field: value};
      });

      final request = GraphQLRequest<String>(
        document: '''
          mutation ControlDevice(\$deviceId: String!, \$field: String!, \$value: AWSJSON!) {
            controlDevice(deviceId: \$deviceId, field: \$field, value: \$value) {
              statusCode
              success
            }
          }
        ''',
        variables: {
          'deviceId': widget.deviceId,
          'field': field,
          'value': jsonEncode(value),
        },
      );

      final response = await Amplify.API.mutate(request: request).response;

      if (response.errors.isNotEmpty) {
        // Revert optimistic update on error
        setState(() {
          _deviceState.remove(field);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.errors.first.message}')),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device control sent: $field = $value'),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _deviceState.remove(field);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    await _fetchDeviceState();
    
    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_uiJson?['title'] ?? 'Device'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _uiJson == null
                  ? const Center(child: Text('No UI configuration found'))
                  : RefreshIndicator(
                      onRefresh: _refreshData,
                      child: _buildDynamicUi(),
                    ),
    );
  }

  Widget _buildDynamicUi() {
    final components = _uiJson!['components'] as List;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: components.length,
      itemBuilder: (context, index) {
        final component = components[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: DynamicComponent(
            component: component,
            deviceState: _deviceState,
            onControlAction: _controlDevice,
          ),
        );
      },
    );
  }
}