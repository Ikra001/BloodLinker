import 'dart:math';
import 'package:blood_linker/services/health_tips_service.dart';
import 'package:blood_linker/models/health_data.dart';
import 'package:blood_linker/models/appointment.dart';
import 'package:blood_linker/data/repositories/health_data_repository.dart';

class AdvancedAIHealthTipsService extends AIHealthTipsService {
  final HealthDataRepository _healthRepository;
  final Random _random = Random();

  AdvancedAIHealthTipsService(this._healthRepository);

  @override
  Future<List<HealthTip>> getHealthTips(
    String userId,
    String userRole,
    String? bloodType,
  ) async {
    final baseTips = await super.getHealthTips(userId, userRole, bloodType);

    try {
      // Get user's health data and profile
      final healthData = await _healthRepository.getUserHealthData(userId);
      final healthProfile = await _healthRepository.getUserHealthProfile(
        userId,
      );

      if (healthData.isNotEmpty && healthProfile != null) {
        final personalizedTips = await _generatePersonalizedTips(
          userId,
          userRole,
          healthData,
          healthProfile,
        );
        baseTips.addAll(personalizedTips);
      }

      // Get today's health data for daily tips
      final todayHealthData = await _healthRepository.getTodayHealthData(
        userId,
      );
      if (todayHealthData != null) {
        final dailyTips = _generateDailyTips(todayHealthData, healthProfile);
        baseTips.addAll(dailyTips);
      }
    } catch (e) {
      // If personalized tips fail, return base tips
      print('Failed to generate personalized tips: $e');
    }

    return baseTips;
  }

  @override
  Future<HealthTip?> getDailyTip(
    String userId,
    String userRole,
    String? bloodType,
  ) async {
    try {
      final todayHealthData = await _healthRepository.getTodayHealthData(
        userId,
      );
      final healthProfile = await _healthRepository.getUserHealthProfile(
        userId,
      );

      if (todayHealthData != null && healthProfile != null) {
        final dailyTips = _generateDailyTips(todayHealthData, healthProfile);
        if (dailyTips.isNotEmpty) {
          return dailyTips[_random.nextInt(dailyTips.length)];
        }
      }
    } catch (e) {
      print('Failed to generate daily tip: $e');
    }

    // Fallback to base implementation
    return super.getDailyTip(userId, userRole, bloodType);
  }

  Future<List<HealthTip>> _generatePersonalizedTips(
    String userId,
    String userRole,
    List<HealthData> healthData,
    UserHealthProfile profile,
  ) async {
    final tips = <HealthTip>[];

    // Analyze donation patterns
    final donationTips = _analyzeDonationPatterns(profile);
    tips.addAll(donationTips);

    // Analyze health trends
    final healthTrendTips = _analyzeHealthTrends(healthData, profile);
    tips.addAll(healthTrendTips);

    // BMI-based tips
    final bmiTips = _generateBmiTips(profile);
    tips.addAll(bmiTips);

    // Age-specific tips
    final ageTips = _generateAgeSpecificTips(profile);
    tips.addAll(ageTips);

    // Blood type specific tips
    if (profile.bloodType.isNotEmpty) {
      final bloodTypeTips = _generateBloodTypeTips(profile.bloodType);
      tips.addAll(bloodTypeTips);
    }

    return tips;
  }

  List<HealthTip> _analyzeDonationPatterns(UserHealthProfile profile) {
    final tips = <HealthTip>[];

    // Streak-based tips
    if (profile.currentStreak >= 6) {
      tips.add(
        HealthTip(
          id: 'streak_excellent',
          title: 'Outstanding Donation Streak!',
          content:
              'You\'ve maintained a ${profile.currentStreak}-month donation streak! This saves ${profile.currentStreak * 3} lives. Keep up the incredible work!',
          category: 'donor',
          tags: ['streak', 'motivation', 'achievement'],
          createdAt: DateTime.now(),
          priority: 5,
        ),
      );
    } else if (profile.currentStreak >= 3) {
      tips.add(
        HealthTip(
          id: 'streak_good',
          title: 'Great Donation Consistency',
          content:
              'Your ${profile.currentStreak}-month donation streak is impressive! Regular donors like you ensure blood availability for emergencies.',
          category: 'donor',
          tags: ['streak', 'consistency', 'motivation'],
          createdAt: DateTime.now(),
          priority: 4,
        ),
      );
    }

    // Donation frequency tips
    if (profile.totalDonations >= 10) {
      tips.add(
        HealthTip(
          id: 'experienced_donor',
          title: 'Experienced Donor Benefits',
          content:
              'As someone who has donated ${profile.totalDonations} times, you know the process well. Consider mentoring new donors to help grow our donor community.',
          category: 'donor',
          tags: ['experience', 'mentoring', 'community'],
          createdAt: DateTime.now(),
          priority: 3,
        ),
      );
    }

    return tips;
  }

  List<HealthTip> _analyzeHealthTrends(
    List<HealthData> healthData,
    UserHealthProfile profile,
  ) {
    final tips = <HealthTip>[];
    final recentData = healthData.take(7); // Last 7 days

    if (recentData.length < 3) return tips;

    // Step count trends
    final avgSteps =
        recentData.map((d) => d.steps).reduce((a, b) => a + b) /
        recentData.length;
    if (avgSteps < 5000) {
      tips.add(
        HealthTip(
          id: 'increase_activity',
          title: 'Boost Your Daily Activity',
          content:
              'Your average daily steps (${avgSteps.round()}) could be higher. Aim for 7,000-10,000 steps daily to improve cardiovascular health and donation eligibility.',
          category: 'general',
          tags: ['activity', 'fitness', 'steps'],
          createdAt: DateTime.now(),
          priority: 4,
        ),
      );
    } else if (avgSteps >= 8000) {
      tips.add(
        HealthTip(
          id: 'excellent_activity',
          title: 'Outstanding Activity Level',
          content:
              'Your average ${avgSteps.round()} daily steps is excellent! This level of activity keeps you healthy and maintains optimal blood quality.',
          category: 'general',
          tags: ['activity', 'fitness', 'achievement'],
          createdAt: DateTime.now(),
          priority: 3,
        ),
      );
    }

    // Sleep pattern analysis
    final avgSleep =
        recentData.map((d) => d.sleepHours).reduce((a, b) => a + b) /
        recentData.length;
    if (avgSleep < 6) {
      tips.add(
        HealthTip(
          id: 'improve_sleep',
          title: 'Prioritize Quality Sleep',
          content:
              'You\'re averaging ${avgSleep.round()} hours of sleep. Aim for 7-9 hours nightly for better recovery and optimal donation readiness.',
          category: 'general',
          tags: ['sleep', 'recovery', 'health'],
          createdAt: DateTime.now(),
          priority: 4,
        ),
      );
    }

    return tips;
  }

  List<HealthTip> _generateBmiTips(UserHealthProfile profile) {
    final tips = <HealthTip>[];

    final bmi = profile.bmi;
    final category = profile.bmiCategory;

    switch (category) {
      case 'Underweight':
        tips.add(
          HealthTip(
            id: 'bmi_underweight',
            title: 'Healthy Weight Gain for Donors',
            content:
                'Your BMI suggests you\'re underweight. Focus on nutrient-dense foods and consult a doctor about safe weight gain strategies while maintaining donation eligibility.',
            category: 'general',
            tags: ['bmi', 'nutrition', 'weight'],
            createdAt: DateTime.now(),
            priority: 4,
          ),
        );
        break;

      case 'Normal':
        tips.add(
          HealthTip(
            id: 'bmi_normal',
            title: 'Excellent BMI for Donations',
            content:
                'Your BMI of ${bmi.toStringAsFixed(1)} is in the healthy range! This supports optimal blood donation and overall wellness.',
            category: 'general',
            tags: ['bmi', 'health', 'fitness'],
            createdAt: DateTime.now(),
            priority: 3,
          ),
        );
        break;

      case 'Overweight':
      case 'Obese':
        tips.add(
          HealthTip(
            id: 'bmi_overweight',
            title: 'Weight Management for Health',
            content:
                'Consider consulting a healthcare provider about gradual weight management. Maintaining a healthy weight improves donation eligibility and overall health.',
            category: 'general',
            tags: ['bmi', 'weight', 'health'],
            createdAt: DateTime.now(),
            priority: 3,
          ),
        );
        break;
    }

    return tips;
  }

  List<HealthTip> _generateAgeSpecificTips(UserHealthProfile profile) {
    final tips = <HealthTip>[];
    final age = profile.age;

    if (age < 25) {
      tips.add(
        HealthTip(
          id: 'young_donor',
          title: 'Young Donor Advantage',
          content:
              'As a young donor, you have the advantage of time. Regular donations now can establish lifelong healthy habits and help more people over your lifetime.',
          category: 'donor',
          tags: ['age', 'young', 'lifestyle'],
          createdAt: DateTime.now(),
          priority: 3,
        ),
      );
    } else if (age >= 50) {
      tips.add(
        HealthTip(
          id: 'experienced_health',
          title: 'Senior Donor Health Focus',
          content:
              'Regular health check-ups are especially important for donors over 50. Continue monitoring blood pressure and cholesterol for safe donations.',
          category: 'donor',
          tags: ['age', 'senior', 'health_checks'],
          createdAt: DateTime.now(),
          priority: 4,
        ),
      );
    }

    return tips;
  }

  List<HealthTip> _generateBloodTypeTips(String bloodType) {
    final tips = <HealthTip>[];
    final cleanBloodType = bloodType
        .toUpperCase()
        .replaceAll('+', 'POSITIVE')
        .replaceAll('-', 'NEGATIVE');

    final rareTypes = [
      'AB_NEGATIVE',
      'B_NEGATIVE',
      'AB_POSITIVE',
      'A_NEGATIVE',
    ];

    if (rareTypes.contains(cleanBloodType.replaceAll(' ', '_'))) {
      tips.add(
        HealthTip(
          id: 'rare_blood_type',
          title: 'Your Blood Type is Precious',
          content:
              '$bloodType is a rare and valuable blood type. Your donations are especially critical for patients who need this specific type.',
          category: 'donor',
          tags: ['blood_type', 'rare', 'importance'],
          createdAt: DateTime.now(),
          priority: 5,
        ),
      );
    } else {
      tips.add(
        HealthTip(
          id: 'common_blood_type',
          title: 'Common but Essential',
          content:
              '$bloodType is commonly needed. Your regular donations ensure hospitals have adequate supplies for emergency situations.',
          category: 'donor',
          tags: ['blood_type', 'common', 'supply'],
          createdAt: DateTime.now(),
          priority: 3,
        ),
      );
    }

    return tips;
  }

  List<HealthTip> _generateDailyTips(
    HealthData todayData,
    UserHealthProfile? profile,
  ) {
    final tips = <HealthTip>[];

    // Step goal achievement
    if (todayData.steps >= 10000) {
      tips.add(
        HealthTip(
          id: 'daily_steps_excellent',
          title: 'Step Goal Achieved! 🏆',
          content:
              'Congratulations! You\'ve reached ${todayData.steps} steps today. This excellent activity level supports cardiovascular health and donation readiness.',
          category: 'general',
          tags: ['steps', 'achievement', 'fitness'],
          createdAt: DateTime.now(),
          priority: 5,
        ),
      );
    } else if (todayData.steps >= 8000) {
      tips.add(
        HealthTip(
          id: 'daily_steps_good',
          title: 'Great Progress Today!',
          content:
              '${todayData.steps} steps is an excellent achievement! You\'re ${(todayData.steps / 10000 * 100).round()}% toward your daily goal.',
          category: 'general',
          tags: ['steps', 'progress', 'motivation'],
          createdAt: DateTime.now(),
          priority: 4,
        ),
      );
    } else if (todayData.steps < 3000) {
      tips.add(
        HealthTip(
          id: 'daily_steps_low',
          title: 'Let\'s Get Moving!',
          content:
              'You\'ve only taken ${todayData.steps} steps today. Try a short walk to boost your activity level and improve donation eligibility.',
          category: 'general',
          tags: ['steps', 'activity', 'motivation'],
          createdAt: DateTime.now(),
          priority: 4,
        ),
      );
    }

    // Calorie tracking
    if (todayData.caloriesBurned > 0) {
      tips.add(
        HealthTip(
          id: 'daily_calories',
          title: 'Today\'s Calorie Burn',
          content:
              'You\'ve burned approximately ${todayData.caloriesBurned.round()} calories through activity. Combined with a balanced diet, this supports healthy weight management.',
          category: 'general',
          tags: ['calories', 'activity', 'nutrition'],
          createdAt: DateTime.now(),
          priority: 3,
        ),
      );
    }

    // Water intake
    if (todayData.waterIntake < 1500) {
      tips.add(
        HealthTip(
          id: 'daily_water_low',
          title: 'Stay Hydrated Today',
          content:
              'You\'ve consumed ${todayData.waterIntake}ml of water. Aim for at least 2 liters daily to maintain optimal blood volume for donations.',
          category: 'general',
          tags: ['hydration', 'water', 'health'],
          createdAt: DateTime.now(),
          priority: 4,
        ),
      );
    }

    // Health score feedback
    final healthScore = todayData.getHealthScore();
    if (healthScore >= 80) {
      tips.add(
        HealthTip(
          id: 'daily_health_excellent',
          title: 'Excellent Health Day! 🌟',
          content:
              'Your health score today is ${healthScore.round()}%. Keep up these healthy habits for optimal donation readiness and overall wellness.',
          category: 'general',
          tags: ['health_score', 'achievement', 'wellness'],
          createdAt: DateTime.now(),
          priority: 4,
        ),
      );
    } else if (healthScore < 50) {
      tips.add(
        HealthTip(
          id: 'daily_health_improve',
          title: 'Room for Improvement',
          content:
              'Your health score is ${healthScore.round()}%. Focus on increasing activity, improving sleep, and staying hydrated for better health outcomes.',
          category: 'general',
          tags: ['health_score', 'improvement', 'goals'],
          createdAt: DateTime.now(),
          priority: 3,
        ),
      );
    }

    return tips;
  }
}
