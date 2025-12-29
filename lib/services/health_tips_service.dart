import 'dart:math';

class HealthTip {
  final String id;
  final String title;
  final String content;
  final String category; // 'donor', 'receiver', 'general'
  final List<String> tags;
  final DateTime createdAt;
  final int priority; // 1-5, higher means more important

  const HealthTip({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.tags,
    required this.createdAt,
    this.priority = 3,
  });

  factory HealthTip.fromMap(Map<String, dynamic> map) {
    return HealthTip(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? 'general',
      tags: List<String>.from(map['tags'] ?? []),
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      priority: map['priority'] ?? 3,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'tags': tags,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'priority': priority,
    };
  }
}

abstract class HealthTipsService {
  Future<List<HealthTip>> getHealthTips(
    String userId,
    String userRole,
    String? bloodType,
  );
  Future<List<HealthTip>> getTipsByCategory(String category);
  Future<HealthTip?> getDailyTip(
    String userId,
    String userRole,
    String? bloodType,
  );
  Future<void> markTipAsRead(String userId, String tipId);
}

class AIHealthTipsService implements HealthTipsService {
  final Random _random = Random();
  final Map<String, List<String>> _readTips = {};

  @override
  Future<List<HealthTip>> getHealthTips(
    String userId,
    String userRole,
    String? bloodType,
  ) async {
    // Simulate AI-generated tips based on user data
    final tips = <HealthTip>[];

    if (userRole == 'donor') {
      tips.addAll(_generateDonorTips(bloodType));
    } else if (userRole == 'receiver') {
      tips.addAll(_generateReceiverTips(bloodType));
    }

    // Add general tips for everyone
    tips.addAll(_generateGeneralTips());

    // Filter out read tips
    final readTipIds = _readTips[userId] ?? [];
    tips.removeWhere((tip) => readTipIds.contains(tip.id));

    // Sort by priority (highest first)
    tips.sort((a, b) => b.priority.compareTo(a.priority));

    return tips;
  }

  @override
  Future<List<HealthTip>> getTipsByCategory(String category) async {
    return _generateGeneralTips()
        .where((tip) => tip.category == category)
        .toList();
  }

  @override
  Future<HealthTip?> getDailyTip(
    String userId,
    String userRole,
    String? bloodType,
  ) async {
    final allTips = await getHealthTips(userId, userRole, bloodType);
    if (allTips.isEmpty) return null;

    // Return a random tip for today
    return allTips[_random.nextInt(allTips.length)];
  }

  @override
  Future<void> markTipAsRead(String userId, String tipId) async {
    if (_readTips[userId] == null) {
      _readTips[userId] = [];
    }
    _readTips[userId]!.add(tipId);
  }

  List<HealthTip> _generateDonorTips(String? bloodType) {
    return [
      HealthTip(
        id: 'donor_1',
        title: 'Stay Hydrated Before Donating',
        content:
            'Drink plenty of water in the days leading up to your donation. Being well-hydrated makes the donation process easier and helps your body replenish blood volume faster.',
        category: 'donor',
        tags: ['hydration', 'preparation', 'recovery'],
        createdAt: DateTime.now(),
        priority: 5,
      ),
      HealthTip(
        id: 'donor_2',
        title: 'Eat Iron-Rich Foods',
        content:
            'Include iron-rich foods like spinach, lentils, red meat, and fortified cereals in your diet. This is especially important for maintaining healthy iron levels after donation.',
        category: 'donor',
        tags: ['nutrition', 'iron', 'recovery'],
        createdAt: DateTime.now(),
        priority: 4,
      ),
      HealthTip(
        id: 'donor_3',
        title: 'Rest After Donation',
        content:
            'Take it easy for the rest of the day after donating. Avoid strenuous activities and get plenty of rest to help your body recover.',
        category: 'donor',
        tags: ['recovery', 'rest', 'safety'],
        createdAt: DateTime.now(),
        priority: 4,
      ),
      HealthTip(
        id: 'donor_blood_type',
        title: 'Your Blood Type is Special',
        content:
            'Blood type ${bloodType ?? 'O+'} is in high demand. Your donations are particularly valuable for patients who need this specific type.',
        category: 'donor',
        tags: ['blood_type', 'importance', 'motivation'],
        createdAt: DateTime.now(),
        priority: 3,
      ),
    ];
  }

  List<HealthTip> _generateReceiverTips(String? bloodType) {
    return [
      HealthTip(
        id: 'receiver_1',
        title: 'Understand Your Blood Type Needs',
        content:
            'Your blood type ${bloodType ?? 'O+'} determines which donors can help you. Knowing this helps you understand compatibility and urgency.',
        category: 'receiver',
        tags: ['blood_type', 'compatibility', 'education'],
        createdAt: DateTime.now(),
        priority: 5,
      ),
      HealthTip(
        id: 'receiver_2',
        title: 'Prepare for Transfusion',
        content:
            'Follow your doctor\'s instructions carefully before and after receiving blood. This ensures the best possible outcome from your transfusion.',
        category: 'receiver',
        tags: ['transfusion', 'preparation', 'safety'],
        createdAt: DateTime.now(),
        priority: 4,
      ),
      HealthTip(
        id: 'receiver_3',
        title: 'Monitor Your Health',
        content:
            'Keep track of how you feel after receiving blood. Report any unusual symptoms to your healthcare provider immediately.',
        category: 'receiver',
        tags: ['monitoring', 'safety', 'recovery'],
        createdAt: DateTime.now(),
        priority: 4,
      ),
      HealthTip(
        id: 'receiver_4',
        title: 'Stay Informed About Your Condition',
        content:
            'Educate yourself about your medical condition and treatment plan. Understanding your needs helps you make informed decisions.',
        category: 'receiver',
        tags: ['education', 'empowerment', 'health'],
        createdAt: DateTime.now(),
        priority: 3,
      ),
    ];
  }

  List<HealthTip> _generateGeneralTips() {
    return [
      HealthTip(
        id: 'general_1',
        title: 'Regular Health Check-ups',
        content:
            'Schedule regular health check-ups and blood tests. This helps maintain good health and ensures you\'re eligible to donate or receive blood when needed.',
        category: 'general',
        tags: ['health', 'prevention', 'check-ups'],
        createdAt: DateTime.now(),
        priority: 3,
      ),
      HealthTip(
        id: 'general_2',
        title: 'Maintain a Healthy Lifestyle',
        content:
            'Eat a balanced diet, exercise regularly, and avoid smoking. A healthy lifestyle keeps your blood in optimal condition.',
        category: 'general',
        tags: ['lifestyle', 'nutrition', 'exercise'],
        createdAt: DateTime.now(),
        priority: 3,
      ),
      HealthTip(
        id: 'general_3',
        title: 'Know Your Blood Type',
        content:
            'Knowing your blood type is important for emergency situations and medical treatments. Get tested if you don\'t know yours.',
        category: 'general',
        tags: ['blood_type', 'emergency', 'preparedness'],
        createdAt: DateTime.now(),
        priority: 4,
      ),
    ];
  }
}
