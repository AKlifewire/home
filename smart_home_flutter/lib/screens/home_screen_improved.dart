import 'package:flutter/material.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'dart:convert';
import '../widgets/device_card.dart';
import 'device_screen.dart';
import 'device_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _devices = [];
  List<Map<String, dynamic>> _filteredDevices = [];
  Set<String> _favoriteDevices = {};
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _fetchDevices();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    // In a real app, this would load from SharedPreferences or similar
    _favoriteDevices = {'test-relay-f181fa48', 'test-sensor-a9e50c3e'};
  }

  Future<void> _fetchDevices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final request = GraphQLRequest<String>(
        document: '''
          query GetMyDevices {
            getMyDevices {
              id
              name
              type
              location
              status
            }
          }
        ''',
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
      final devices = List<Map<String, dynamic>>.from(
        jsonData['getMyDevices'].map((device) => Map<String, dynamic>.from(device)),
      );

      setState(() {
        _devices = devices;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_devices);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((device) {
        final name = device['name']?.toString().toLowerCase() ?? '';
        final location = device['location']?.toString().toLowerCase() ?? '';
        final type = device['type']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || location.contains(query) || type.contains(query);
      }).toList();
    }
    
    // Apply type filter
    if (_filterType != 'all') {
      filtered = filtered.where((device) => 
        device['type']?.toString().toLowerCase() == _filterType.toLowerCase()
      ).toList();
    }
    
    setState(() {
      _filteredDevices = filtered;
    });
  }

  void _toggleFavorite(String deviceId) {
    setState(() {
      if (_favoriteDevices.contains(deviceId)) {
        _favoriteDevices.remove(deviceId);
      } else {
        _favoriteDevices.add(deviceId);
      }
    });
    // In a real app, save to SharedPreferences or similar
  }

  Future<void> _signOut() async {
    try {
      await Amplify.Auth.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Devices'),
        actions: [
          IconButton(
            icon: const Icon(Icons.science),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DeviceTestScreen()),
              );
            },
            tooltip: 'Test Tools',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDevices,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search devices...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _applyFilters();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Relay', 'relay'),
                      _buildFilterChip('Sensor', 'sensor'),
                      _buildFilterChip('Camera', 'camera'),
                      _buildFilterChip('Light', 'light'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _filteredDevices.isEmpty
                        ? const Center(child: Text('No devices found'))
                        : RefreshIndicator(
                            onRefresh: _fetchDevices,
                            child: ListView.builder(
                              itemCount: _filteredDevices.length,
                              itemBuilder: (context, index) {
                                final device = _filteredDevices[index];
                                final deviceId = device['id'];
                                return DeviceCard(
                                  name: device['name'] ?? 'Unnamed Device',
                                  type: device['type'] ?? 'unknown',
                                  location: device['location'],
                                  status: device['status'],
                                  isFavorite: _favoriteDevices.contains(deviceId),
                                  onFavorite: () => _toggleFavorite(deviceId),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DeviceScreen(deviceId: deviceId),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to add device screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add device functionality coming soon')),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Add Device',
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterType = selected ? value : 'all';
            _applyFilters();
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        checkmarkColor: Theme.of(context).primaryColor,
      ),
    );
  }
}