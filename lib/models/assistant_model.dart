import 'dart:convert';

class AiConversation {
  final int id;
  final int userId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int messagesCount;

  const AiConversation({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.messagesCount = 0,
  });

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: json['id'] is int ? json['id'] as int : int.parse(json['id'].toString()),
      userId: json['user_id'] is int ? json['user_id'] as int : int.parse(json['user_id'].toString()),
      title: json['title']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : DateTime.now(),
      messagesCount: json['messages_count'] is int ? json['messages_count'] as int : (json['messages'] is List ? (json['messages'] as List).length : 0),
    );
  }
}

class AiMessage {
  final int? id;
  final int? aiConversationId;
  final String role; // 'user' or 'assistant'
  final String content;
  final String? intent;
  final Map<String, dynamic>? data;
  final List<String> followUps;
  final DateTime createdAt;

  const AiMessage({
    this.id,
    this.aiConversationId,
    required this.role,
    required this.content,
    this.intent,
    this.data,
    this.followUps = const [],
    required this.createdAt,
  });

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    // Determine follow ups safely
    List<String> parsedFollowUps = [];
    if (json['follow_ups'] is List) {
      parsedFollowUps = (json['follow_ups'] as List).map((e) => e.toString()).toList();
    } else if (json['followUps'] is List) {
      parsedFollowUps = (json['followUps'] as List).map((e) => e.toString()).toList();
    }

    // Try parsing intent and data
    final intentVal = json['intent']?.toString();
    
    // Parse data safely
    Map<String, dynamic>? parsedData;
    if (json['data'] != null) {
      if (json['data'] is Map) {
        parsedData = Map<String, dynamic>.from(json['data'] as Map);
      } else if (json['data'] is String) {
        try {
          parsedData = Map<String, dynamic>.from(jsonDecode(json['data'] as String) as Map);
        } catch (_) {}
      }
    }

    return AiMessage(
      id: json['id'] is int ? json['id'] as int : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      aiConversationId: json['ai_conversation_id'] is int 
          ? json['ai_conversation_id'] as int 
          : (json['conversation_id'] is int
              ? json['conversation_id'] as int
              : (json['ai_conversation_id'] != null 
                  ? int.tryParse(json['ai_conversation_id'].toString()) 
                  : (json['conversation_id'] != null 
                      ? int.tryParse(json['conversation_id'].toString()) 
                      : null))),
      role: json['role']?.toString() ?? (json.containsKey('reply') ? 'assistant' : 'user'),
      content: json['content']?.toString() ?? json['reply']?.toString() ?? '',
      intent: intentVal,
      data: parsedData,
      followUps: parsedFollowUps,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
    );
  }
}

class CareerRecommendation {
  final String career;
  final double confidence;

  const CareerRecommendation({
    required this.career,
    required this.confidence,
  });

  factory CareerRecommendation.fromJson(Map<String, dynamic> json) {
    final confVal = json['confidence'] ?? json['confidence_score'] ?? 0.0;
    double parsedConf = 0.0;
    if (confVal is num) {
      parsedConf = confVal.toDouble();
    } else {
      parsedConf = double.tryParse(confVal.toString()) ?? 0.0;
    }
    // If it's represented as a fraction (e.g. 0.85), convert to percentage
    if (parsedConf > 0 && parsedConf <= 1.0) {
      parsedConf = parsedConf * 100;
    }

    return CareerRecommendation(
      career: json['career']?.toString() ?? '',
      confidence: parsedConf,
    );
  }
}

class SkillGap {
  final double matchPercentage;
  final List<String> requiredSkills;
  final List<String> missingSkills;
  final List<RoadmapStep> roadmap;
  final List<MentorRecommendation> mentors;

  const SkillGap({
    required this.matchPercentage,
    required this.requiredSkills,
    required this.missingSkills,
    this.roadmap = const [],
    this.mentors = const [],
  });

  factory SkillGap.fromJson(Map<String, dynamic> json) {
    final matchVal = json['match_percentage'] ?? json['matchPercentage'] ?? json['match_score'] ?? 0.0;
    double parsedMatch = 0.0;
    if (matchVal is num) {
      parsedMatch = matchVal.toDouble();
    } else {
      parsedMatch = double.tryParse(matchVal.toString()) ?? 0.0;
    }
    if (parsedMatch > 0 && parsedMatch <= 1.0) {
      parsedMatch = parsedMatch * 100;
    }

    final reqRaw = json['required_skills'] ?? json['requiredSkills'] ?? [];
    final List<String> reqSkills = reqRaw is List ? reqRaw.map((e) => e.toString()).toList() : [];

    final missRaw = json['missing_skills'] ?? json['missingSkills'] ?? [];
    final List<String> missSkills = missRaw is List ? missRaw.map((e) => e.toString()).toList() : [];

    final roadRaw = json['roadmap'] ?? [];
    final List<RoadmapStep> parsedRoadmap = roadRaw is List
        ? roadRaw.map((e) => RoadmapStep.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    final mentorRaw = json['mentors'] ?? [];
    final List<MentorRecommendation> parsedMentors = mentorRaw is List
        ? mentorRaw.map((e) => MentorRecommendation.fromJson(e as Map<String, dynamic>)).toList()
        : [];

    return SkillGap(
      matchPercentage: parsedMatch,
      requiredSkills: reqSkills,
      missingSkills: missSkills,
      roadmap: parsedRoadmap,
      mentors: parsedMentors,
    );
  }
}

class RoadmapStep {
  final String title;
  final String description;
  final List<String> skills;

  const RoadmapStep({
    required this.title,
    required this.description,
    required this.skills,
  });

  factory RoadmapStep.fromJson(Map<String, dynamic> json) {
    final skillsRaw = json['skills'] ?? [];
    final List<String> parsedSkills = skillsRaw is List ? skillsRaw.map((e) => e.toString()).toList() : [];
    return RoadmapStep(
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      skills: parsedSkills,
    );
  }
}

class MentorRecommendation {
  final String name;
  final List<String> matchingSkills;
  final double matchScore;

  const MentorRecommendation({
    required this.name,
    required this.matchingSkills,
    required this.matchScore,
  });

  factory MentorRecommendation.fromJson(Map<String, dynamic> json) {
    final scoreVal = json['match_score'] ?? json['matchScore'] ?? 0.0;
    double parsedScore = 0.0;
    if (scoreVal is num) {
      parsedScore = scoreVal.toDouble();
    } else {
      parsedScore = double.tryParse(scoreVal.toString()) ?? 0.0;
    }
    if (parsedScore > 0 && parsedScore <= 1.0) {
      parsedScore = parsedScore * 100;
    }

    final skillsRaw = json['matching_skills'] ?? json['matchingSkills'] ?? [];
    final List<String> parsedSkills = skillsRaw is List ? skillsRaw.map((e) => e.toString()).toList() : [];

    return MentorRecommendation(
      name: json['name']?.toString() ?? '',
      matchingSkills: parsedSkills,
      matchScore: parsedScore,
    );
  }
}
