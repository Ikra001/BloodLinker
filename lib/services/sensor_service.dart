import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:blood_linker/models/health_data.dart';

abstract class SensorService {
  Future<bool> initialize();
  Stream<int> get stepCountStream;
  Stream<HealthData> get healthDataStream;
  Future<HealthData> getTodayHealthData();
  Future<void> updateHealthData(HealthData data);
  void dispose();
}

class MobileSensorService implements SensorService {
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamController<int>? _stepController;
  StreamController<HealthData>? _healthController;

  int _currentSteps = 0;
  DateTime _lastResetDate = DateTime.now();
  HealthData? _todayHealthData;

  @override
  Future<bool> initialize() async {
    try {
      _stepController = StreamController<int>.broadcast();
      _healthController = StreamController<HealthData>.broadcast();

      // Initialize pedometer
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepError,
        cancelOnError: true,
      );

      // Start periodic health data updates
      Timer.periodic(const Duration(minutes: 5), (_) => _updateHealthData());

      return true;
    } catch (e) {
      print('Failed to initialize sensors: $e');
      return false;
    }
  }

  void _onStepCount(StepCount event) {
    _currentSteps = event.steps;

    // Reset steps at midnight
    final now = DateTime.now();
    if (now.day != _lastResetDate.day) {
      _currentSteps = 0;
      _lastResetDate = now;
    }

    _stepController?.add(_currentSteps);
    _updateHealthData();
  }

  void _onStepError(error) {
    print('Step count error: $error');
    // Could implement fallback step counting here
  }

  void _updateHealthData() {
    final now = DateTime.now();

    // Calculate calories burned (rough estimate: 0.04 calories per step)
    final caloriesBurned = _currentSteps * 0.04;

    // Estimate distance (average step length ~0.76m)
    final distanceWalked = _currentSteps * 0.00076; // in kilometers

    // Estimate active minutes (rough calculation)
    final activeMinutes = (_currentSteps / 100)
        .round(); // ~100 steps per minute of activity

    final healthData = HealthData(
      id: 'today_${now.year}${now.month}${now.day}',
      userId: 'current_user', // This should be injected
      date: now,
      steps: _currentSteps,
      caloriesBurned: caloriesBurned,
      distanceWalked: distanceWalked,
      activeMinutes: activeMinutes,
      sleepHours: 0, // Would need sleep tracking sensor
      waterIntake: 0, // Would need manual input or smart bottle integration
      activities: ['walking'],
    );

    _todayHealthData = healthData;
    _healthController?.add(healthData);
  }

  @override
  Stream<int> get stepCountStream =>
      _stepController?.stream ?? const Stream.empty();

  @override
  Stream<HealthData> get healthDataStream =>
      _healthController?.stream ?? const Stream.empty();

  @override
  Future<HealthData> getTodayHealthData() async {
    if (_todayHealthData != null) {
      return _todayHealthData!;
    }

    // Return default health data if sensors not available
    final now = DateTime.now();
    return HealthData(
      id: 'today_${now.year}${now.month}${now.day}',
      userId: 'current_user',
      date: now,
      steps: _currentSteps,
    );
  }

  @override
  Future<void> updateHealthData(HealthData data) async {
    // This would typically save to repository
    _todayHealthData = data;
    _healthController?.add(data);
  }

  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _stepController?.close();
    _healthController?.close();
  }
}

class MockSensorService implements SensorService {
  StreamController<int>? _stepController;
  StreamController<HealthData>? _healthController;
  Timer? _mockTimer;

  @override
  Future<bool> initialize() async {
    _stepController = StreamController<int>.broadcast();
    _healthController = StreamController<HealthData>.broadcast();

    // Simulate step counting
    int mockSteps = 0;
    _mockTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      mockSteps += (5 + (10 * (DateTime.now().second % 3))); // Random steps
      _stepController?.add(mockSteps);

      // Generate mock health data
      final healthData = HealthData(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'mock_user',
        date: DateTime.now(),
        steps: mockSteps,
        caloriesBurned: mockSteps * 0.04,
        distanceWalked: mockSteps * 0.00076,
        activeMinutes: (mockSteps / 80).round(),
        sleepHours: 7,
        waterIntake: 1800,
        activities: ['walking', 'light_activity'],
      );

      _healthController?.add(healthData);
    });

    return true;
  }

  @override
  Stream<int> get stepCountStream =>
      _stepController?.stream ?? const Stream.empty();

  @override
  Stream<HealthData> get healthDataStream =>
      _healthController?.stream ?? const Stream.empty();

  @override
  Future<HealthData> getTodayHealthData() async {
    final now = DateTime.now();
    return HealthData(
      id: 'mock_today',
      userId: 'mock_user',
      date: now,
      steps: 6500,
      caloriesBurned: 260,
      distanceWalked: 4.9,
      activeMinutes: 45,
      sleepHours: 7,
      waterIntake: 1800,
      activities: ['walking', 'exercise'],
    );
  }

  @override
  Future<void> updateHealthData(HealthData data) async {
    _healthController?.add(data);
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _stepController?.close();
    _healthController?.close();
  }
}
