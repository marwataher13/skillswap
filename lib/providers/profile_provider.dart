import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillswap/models/profile_models.dart';
import 'package:skillswap/services/profile_service.dart';

/// Holds all mutable state for the logged-in user's profile.
class ProfileProvider extends ChangeNotifier {
  final _profileService = ProfileService();

  ProfileData _profile = const ProfileData(
    name: '',
    username: '',
    bio: '',
    phone: '',
    avatarUrl: null,
  );

  List<PortfolioItem> _portfolioItems = [];

  bool _isSaving = false;
  bool _isLoading = false;
  String? _error;

  ProfileProvider() {
    loadData();
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  ProfileData get profile => _profile;
  List<PortfolioItem> get portfolioItems =>
      List.unmodifiable(_portfolioItems);
  bool get isSaving => _isSaving;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _profileService.fetchProfile(),
        _profileService.fetchPortfolio(),
      ]);

      _profile = results[0] as ProfileData;
      _portfolioItems = results[1] as List<PortfolioItem>;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_user_id', _profile.id);
    } catch (e) {
      _error = e.toString();
      debugPrint('ProfileProvider.loadData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfile(ProfileData updated) async {
    _isSaving = true;
    notifyListeners();

    try {
      final serverProfile = await _profileService.updateProfile(updated);
      _profile = serverProfile;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_user_id', _profile.id);
    } catch (e) {
      debugPrint('ProfileProvider.saveProfile error: $e');
      _profile = updated;
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> deleteAvatar() async {
    try {
      await _profileService.deleteProfilePicture();
      _profile = _profile.copyWith(clearAvatar: true);
    } catch (e) {
      debugPrint('ProfileProvider.deleteAvatar error: $e');
      _profile = _profile.copyWith(clearAvatar: true);
    } finally {
      notifyListeners();
    }
  }

  Future<void> uploadAvatar(Uint8List bytes, String filename) async {
    try {
      final newUrl =
          await _profileService.uploadProfilePicture(bytes, filename);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cacheBustedUrl = newUrl.contains('?')
          ? '$newUrl&t=$timestamp'
          : '$newUrl?t=$timestamp';
      _profile = _profile.copyWith(avatarUrl: cacheBustedUrl);
    } catch (e) {
      debugPrint('ProfileProvider.uploadAvatar error: $e');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _profile = _profile.copyWith(
        avatarUrl: 'https://i.pravatar.cc/150?img=12&t=$timestamp',
      );
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> addPortfolioItem(PortfolioItem item, Uint8List bytes) async {
    try {
      final serverItem =
          await _profileService.addPortfolioItem(item, bytes);

      final resolvedItem = PortfolioItem(
        id: serverItem.id.isNotEmpty ? serverItem.id : item.id,
        title: serverItem.title.isNotEmpty ? serverItem.title : item.title,
        type: serverItem.type,
        fileUrl: serverItem.fileUrl ?? item.fileUrl,
      );

      _portfolioItems = [..._portfolioItems, resolvedItem];
    } catch (e) {
      debugPrint('ProfileProvider.addPortfolioItem error: $e');
      _portfolioItems = [..._portfolioItems, item];
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> deletePortfolioItem(String id) async {
    try {
      await _profileService.deletePortfolioItem(id);
      _portfolioItems = _portfolioItems.where((e) => e.id != id).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('ProfileProvider.deletePortfolioItem error: $e');
      rethrow;
    }
  }
}
