import 'package:flutter/foundation.dart';
import 'package:skillswap/models/skill_card_data.dart';
import '../config/app_config.dart';

class SkillService {
  static const String _endpoint = '${AppConfig.baseUrl}/api/skills';

  /// Asynchronously fetch the active skills listings.
  /// Standard simulated latency gives a polished mockup performance in dev.
  Future<List<SkillCardData>> fetchSkills() async {
    debugPrint('SkillService: Fetching skills from $_endpoint...');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    // Returning standard mocks (can easily connect to backend endpoint via http.get later)
    return const [
      SkillCardData(
        image: 'assets/images/guitar.jpg',
        category: 'Creative',
        title: 'Guitar Lessons',
        exchange: 'in exchange for Spanish Tutoring',
        user: 'Anna, 5 miles away',
      ),
      SkillCardData(
        image: 'assets/images/camera.jpg',
        category: 'Creative',
        title: 'Photography Basics',
        exchange: 'in exchange for Baking Lessons',
        user: 'Mark, 2 miles away',
      ),
    ];
  }
}
