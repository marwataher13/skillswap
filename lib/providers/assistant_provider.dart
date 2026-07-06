import 'package:flutter/foundation.dart';
import 'package:skillswap/models/assistant_model.dart';
import 'package:skillswap/services/assistant_service.dart';

class AssistantProvider extends ChangeNotifier {
  final AssistantService _service = AssistantService();

  List<AiMessage> _messages = [];
  List<AiConversation> _conversations = [];
  bool _isLoading = false;
  int? _conversationId;
  String? _currentIntent;
  String? _error;
  List<CareerRecommendation> _careerRecommendations = [];
  SkillGap? _skillGap;
  List<RoadmapStep> _roadmap = [];
  List<MentorRecommendation> _mentors = [];
  List<String> _followUps = [];

  // Getters
  List<AiMessage> get messages => _messages;
  List<AiConversation> get conversations => _conversations;
  bool get isLoading => _isLoading;
  int? get conversationId => _conversationId;
  String? get currentIntent => _currentIntent;
  String? get error => _error;
  List<CareerRecommendation> get careerRecommendations => _careerRecommendations;
  SkillGap? get skillGap => _skillGap;
  List<RoadmapStep> get roadmap => _roadmap;
  List<MentorRecommendation> get mentors => _mentors;
  List<String> get followUps => _followUps;

  // Actions
  Future<void> loadConversations() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _conversations = await _service.fetchConversations();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('AssistantProvider.loadConversations error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectConversation(int id) async {
    _isLoading = true;
    _error = null;
    _conversationId = id;
    _messages = [];
    _currentIntent = null;
    _careerRecommendations = [];
    _skillGap = null;
    _roadmap = [];
    _mentors = [];
    _followUps = [];
    notifyListeners();

    try {
      _messages = await _service.fetchMessages(id);
      
      // If there are messages, infer state from last message
      if (_messages.isNotEmpty) {
        final last = _messages.last;
        _currentIntent = last.intent;
        _followUps = last.followUps;
        
        // Parse metadata if present
        if (last.intent == 'skill_gap' && last.data != null) {
          _skillGap = SkillGap.fromJson(last.data!);
          _roadmap = _skillGap?.roadmap ?? [];
          _mentors = _skillGap?.mentors ?? [];
        } else if (last.intent == 'mentor_recommendation' && last.data != null) {
          final parsed = SkillGap.fromJson(last.data!);
          _mentors = parsed.mentors;
        }
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('AssistantProvider.selectConversation error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void startNewConversation() {
    _conversationId = null;
    _messages = [];
    _currentIntent = null;
    _careerRecommendations = [];
    _skillGap = null;
    _roadmap = [];
    _mentors = [];
    _followUps = [];
    _error = null;
    notifyListeners();
  }

  Future<void> deleteConversation(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteConversation(id);
      _conversations.removeWhere((c) => c.id == id);
      if (_conversationId == id) {
        startNewConversation();
      }
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('AssistantProvider.deleteConversation error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add local user message instantly
    final userMsg = AiMessage(
      role: 'user',
      content: text,
      createdAt: DateTime.now(),
    );
    _messages.add(userMsg);
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final replyMsg = await _service.chat(
        message: text,
        conversationId: _conversationId,
      );

      // Save conversation_id returned by the server
      if (replyMsg.aiConversationId != null) {
        _conversationId = replyMsg.aiConversationId;
      }

      // Add reply to list
      _messages.add(replyMsg);
      _currentIntent = replyMsg.intent;
      _followUps = replyMsg.followUps;

      // Handle intent-specific metadata inside messages
      if (replyMsg.intent == 'skill_gap' && replyMsg.data != null) {
        _skillGap = SkillGap.fromJson(replyMsg.data!);
        _roadmap = _skillGap?.roadmap ?? [];
        _mentors = _skillGap?.mentors ?? [];
      } else if (replyMsg.intent == 'mentor_recommendation' && replyMsg.data != null) {
        final parsed = SkillGap.fromJson(replyMsg.data!);
        _mentors = parsed.mentors;
      }

      // Refresh conversations list in background
      loadConversations();
    } catch (e, stack) {
      debugPrint('AssistantProvider.sendMessage exception: $e');
      debugPrintStack(stackTrace: stack);
      // Gracefully handle AI service offline or network errors by showing assistant fallback
      final fallbackMsg = AiMessage(
        role: 'assistant',
        content: "I'm sorry, I'm having trouble connecting right now. Please try again in a moment.",
        createdAt: DateTime.now(),
      );
      _messages.add(fallbackMsg);
      _currentIntent = 'unknown';
      _followUps = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> submitAssessment(Map<String, int> assessment) async {
    _isLoading = true;
    _error = null;
    _careerRecommendations = [];
    notifyListeners();

    try {
      _careerRecommendations = await _service.recommendCareer(assessment);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('AssistantProvider.submitAssessment error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchDirectSkillGap(String career) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _skillGap = await _service.fetchSkillGap(career);
      _roadmap = _skillGap?.roadmap ?? [];
      _mentors = _skillGap?.mentors ?? [];
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('AssistantProvider.fetchDirectSkillGap error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateRoadmap(String career, List<String> missingSkills) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _roadmap = await _service.fetchRoadmap(career, missingSkills);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      debugPrint('AssistantProvider.generateRoadmap error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
