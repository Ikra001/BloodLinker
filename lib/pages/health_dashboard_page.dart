import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/services/advanced_health_tips_service.dart';
import 'package:blood_linker/services/sensor_service.dart';
import 'package:blood_linker/services/health_tips_service.dart';
import 'package:blood_linker/models/health_data.dart';
import 'package:blood_linker/data/repositories/health_data_repository.dart';
import 'package:blood_linker/widgets/common_widgets.dart';
import 'package:blood_linker/widgets/app_theme.dart';

class HealthDashboardPage extends StatefulWidget {
  static const route = '/health_dashboard';

  const HealthDashboardPage({super.key});

  @override
  State<HealthDashboardPage> createState() => _HealthDashboardPageState();
}

class _HealthDashboardPageState extends State<HealthDashboardPage> {
  late AdvancedAIHealthTipsService _tipsService;
  late SensorService _sensorService;
  late HealthDataRepository _healthRepository;

  List<HealthTip> _todayTips = [];
  HealthData? _todayHealthData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadTodayData();
  }

  void _initializeServices() {
    _healthRepository = FirestoreHealthDataRepository(
      Provider.of(context, listen: false), // This needs proper DI
    );
    _tipsService = AdvancedAIHealthTipsService(_healthRepository);
    _sensorService =
        MockSensorService(); // Use MobileSensorService() for real sensors
  }

  Future<void> _loadTodayData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authManager = Provider.of<AuthManager>(context, listen: false);
      final user = authManager.customUser;

      if (user != null) {
        // Load today's health data
        _todayHealthData = await _sensorService.getTodayHealthData();

        // Generate personalized tips
        _todayTips = await _tipsService.getHealthTips(
          user.userId,
          'donor', // This should be dynamic
          user.bloodType,
        );
      }
    } catch (e) {
      _error = 'Failed to load health data: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadTodayData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.errorColor,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    text: 'Retry',
                    onPressed: _loadTodayData,
                    width: 120,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Daily Health Metrics
                  _buildDailyMetrics(),

                  const SizedBox(height: AppSpacing.xl),

                  // Health Score
                  if (_todayHealthData != null) _buildHealthScore(),

                  const SizedBox(height: AppSpacing.xl),

                  // Today's Tips
                  _buildTodayTips(),

                  const SizedBox(height: AppSpacing.xl),

                  // Quick Actions
                  _buildQuickActions(),
                ],
              ),
            ),
    );
  }

  Widget _buildDailyMetrics() {
    if (_todayHealthData == null) {
      return const EmptyState(
        icon: Icons.fitness_center,
        title: 'No Health Data',
        subtitle:
            'Start tracking your daily activity to see personalized insights.',
      );
    }

    final data = _todayHealthData!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.today, color: AppTheme.primaryColor, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Today\'s Health Metrics',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Metrics Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            children: [
              _buildMetricCard(
                'Steps',
                '${data.steps}',
                Icons.directions_walk,
                _getStepColor(data.steps),
                '${(data.steps / 10000 * 100).round()}% of goal',
              ),
              _buildMetricCard(
                'Calories',
                '${data.caloriesBurned.round()}',
                Icons.local_fire_department,
                Colors.orange,
                'kcal burned',
              ),
              _buildMetricCard(
                'Distance',
                '${data.distanceWalked.toStringAsFixed(1)}',
                Icons.straighten,
                Colors.blue,
                'km walked',
              ),
              _buildMetricCard(
                'Active Time',
                '${data.activeMinutes}',
                Icons.timer,
                Colors.green,
                'minutes',
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Additional metrics in a row
          Row(
            children: [
              Expanded(
                child: _buildSmallMetric(
                  'Sleep',
                  '${data.sleepHours}h',
                  Icons.bedtime,
                ),
              ),
              Expanded(
                child: _buildSmallMetric(
                  'Water',
                  '${data.waterIntake}ml',
                  Icons.water_drop,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppBorderRadius.md,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSmallMetric(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: AppBorderRadius.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScore() {
    final score = _todayHealthData!.getHealthScore();
    final scoreColor = _getScoreColor(score);

    return AppCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Health Score',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: AppBorderRadius.lg,
                  border: Border.all(color: scoreColor.withOpacity(0.3)),
                ),
                child: Text(
                  '${score.round()}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: score / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
            borderRadius: AppBorderRadius.sm,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _getScoreMessage(score),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTips() {
    if (_todayTips.isEmpty) {
      return const EmptyState(
        icon: Icons.lightbulb,
        title: 'No Tips Today',
        subtitle: 'Check back later for personalized health tips.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s Health Tips',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._todayTips.take(3).map((tip) => _buildTipCard(tip)),
        if (_todayTips.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: PrimaryButton(
              text: 'View All Tips',
              onPressed: () => Navigator.pushNamed(context, '/health_tips'),
              width: double.infinity,
            ),
          ),
      ],
    );
  }

  Widget _buildTipCard(HealthTip tip) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTipIcon(tip.category),
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  tip.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(tip.priority).withOpacity(0.1),
                  borderRadius: AppBorderRadius.sm,
                ),
                child: Text(
                  _getPriorityText(tip.priority),
                  style: TextStyle(
                    color: _getPriorityColor(tip.priority),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            tip.content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Log Water',
                  Icons.water_drop,
                  Colors.blue,
                  () {
                    // Navigate to water logging
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Water logging coming soon!'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildActionButton(
                  'Track Sleep',
                  Icons.bedtime,
                  Colors.purple,
                  () {
                    // Navigate to sleep tracking
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Sleep tracking coming soon!'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'View History',
                  Icons.history,
                  Colors.green,
                  () {
                    // Navigate to health history
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Health history coming soon!'),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildActionButton(
                  'Set Goals',
                  Icons.flag,
                  Colors.orange,
                  () {
                    // Navigate to goal setting
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Goal setting coming soon!'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppBorderRadius.md,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: AppBorderRadius.md,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: AppSpacing.sm),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStepColor(int steps) {
    if (steps >= 10000) return Colors.green;
    if (steps >= 8000) return Colors.lightGreen;
    if (steps >= 6000) return Colors.yellow;
    if (steps >= 3000) return Colors.orange;
    return Colors.red;
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.yellow;
    if (score >= 20) return Colors.orange;
    return Colors.red;
  }

  String _getScoreMessage(double score) {
    if (score >= 80)
      return 'Excellent! You\'re crushing your health goals today!';
    if (score >= 60) return 'Good job! Keep up the healthy habits.';
    if (score >= 40) return 'Not bad, but there\'s room for improvement.';
    if (score >= 20) return 'Let\'s focus on building healthier routines.';
    return 'Time to prioritize your health and wellness.';
  }

  IconData _getTipIcon(String category) {
    switch (category) {
      case 'donor':
        return Icons.volunteer_activism;
      case 'receiver':
        return Icons.local_hospital;
      case 'general':
      default:
        return Icons.health_and_safety;
    }
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 5:
        return Colors.red;
      case 4:
        return Colors.orange;
      case 3:
        return Colors.blue;
      case 2:
        return Colors.green;
      case 1:
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 5:
        return 'Critical';
      case 4:
        return 'High';
      case 3:
        return 'Medium';
      case 2:
        return 'Low';
      case 1:
      default:
        return 'Info';
    }
  }

  @override
  void dispose() {
    _sensorService.dispose();
    super.dispose();
  }
}
