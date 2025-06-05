import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_config.dart';
import '../models/ui_component.dart';
import '../services/auth_service.dart';
import '../services/graphql_service.dart';
import '../services/storage_service.dart';

class AppState extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final GraphQLService _graphQLService;
  final StorageService _storageService;

  AppState({
    required AuthService authService,
    required GraphQLService graphQLService,
    required StorageService storageService,
  }) : _authService = authService,
       _graphQLService = graphQLService,
       _storageService = storageService,
       super(const AsyncValue.loading());

  // User state
  AuthUser? _currentUser;
  List<DeviceConfig> _devices = [];
  Map<String, UiLayout> _deviceLayouts = {};

  // Getters
  AuthUser? get currentUser => _currentUser;
  List<DeviceConfig> get devices => _devices;
  Map<String, UiLayout> get deviceLayouts => _deviceLayouts;

  // Initialize app state
  Future<void> initialize() async {
    try {
      state = const AsyncValue.loading();

      // Get current user
      _currentUser = await _authService.getCurrentUser();

      if (_currentUser != null) {
        // Load user's devices
        await _loadUserDevices();
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Load user's devices
  Future<void> _loadUserDevices() async {
    if (_currentUser == null) return;

    _devices = await _graphQLService.getMyDevices(userId: _currentUser!.userId);

    // Pre-fetch UI layouts for all devices
    for (final device in _devices) {
      try {
        final layout = await _storageService.getUiJson(
          userId: _currentUser!.userId,
          deviceId: device.deviceId,
        );
        _deviceLayouts[device.deviceId] = layout;
      } catch (e) {
        print('Failed to load UI layout for device ${device.deviceId}: $e');
      }
    }
  }

  // Handle device control
  Future<void> controlDevice({
    required String deviceId,
    required String componentId,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      await _graphQLService.controlDevice(
        deviceId: deviceId,
        componentId: componentId,
        parameters: parameters,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Clear state on logout
  void clearState() {
    _currentUser = null;
    _devices = [];
    _deviceLayouts = {};
    state = const AsyncValue.data(null);
  }
}

// Providers
final appStateProvider = StateNotifierProvider<AppState, AsyncValue<void>>((
  ref,
) {
  return AppState(
    authService: ref.watch(authServiceProvider),
    graphQLService: ref.watch(graphQLServiceProvider),
    storageService: ref.watch(storageServiceProvider),
  );
});
