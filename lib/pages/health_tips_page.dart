import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_linker/services/health_tips_service.dart';
import 'package:blood_linker/auth/auth_manager.dart';
import 'package:blood_linker/widgets/common_widgets.dart';
import 'package:blood_linker/widgets/app_theme.dart';

class HealthTipsPage extends StatefulWidget {
  static const route = '/health_tips';

  const HealthTipsPage({super.key});

  @override
  State<HealthTipsPage> createState() => _HealthTipsPageState();
}

class _HealthTipsPageState extends State<HealthTipsPage> {
  late HealthTipsService _tipsService;
  List<HealthTip> _tips = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tipsService = AIHealthTipsService();
    _loadTips();
  }

  Future<void> _loadTips() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get user role and blood type from auth manager
      final authManager = Provider.of<AuthManager>(context, listen: false);
      final user = authManager.customUser;

      String userRole = 'donor'; // Default
      String? bloodType = user?.bloodType;

      _tips = await _tipsService.getHealthTips(
        authManager.user?.uid ?? 'anonymous',
        userRole,
        bloodType,
      );
    } catch (e) {
      _error = 'Failed to load health tips: $e';
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
        title: const Text('Health Tips'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
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
                    onPressed: _loadTips,
                    width: 120,
                  ),
                ],
              ),
            )
          : _tips.isEmpty
          ? EmptyState(
              icon: Icons.lightbulb_outline,
              title: 'No Health Tips Available',
              subtitle: 'Check back later for personalized health tips.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _tips.length,
              itemBuilder: (context, index) {
                final tip = _tips[index];
                return _buildTipCard(tip);
              },
            ),
    );
  }

  Widget _buildTipCard(HealthTip tip) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: AppBorderRadius.sm,
                ),
                child: Icon(
                  _getTipIcon(tip.category),
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  tip.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getPriorityColor(tip.priority),
                  borderRadius: AppBorderRadius.sm,
                ),
                child: Text(
                  _getPriorityText(tip.priority),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            tip.content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(Icons.category, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                tip.category.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
}
