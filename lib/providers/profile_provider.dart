import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:skillswap/models/profile_models.dart';
import 'package:skillswap/services/profile_service.dart';

/// Holds all mutable state for the Profile screen.
/// Uses [ChangeNotifier] so any [Consumer] rebuilds on change.
class ProfileProvider extends ChangeNotifier {
  final _profileService = ProfileService();

  // ── Mock initial fallback data ─────────────────────────────────────────────
  ProfileData _profile = const ProfileData(
    name: 'Alex Morgan',
    bio: 'Flutter developer & UI/UX enthusiast. Building beautiful experiences one widget at a time.',
    phone: '+1 555 234 5678',
    avatarUrl: null, // null = show initials fallback
  );

  List<PortfolioItem> _portfolioItems = [
    PortfolioItem(id: '1', title: 'App Redesign.pdf',   type: FileType.pdf),
    PortfolioItem(id: '2', title: 'Wireframes.png',     type: FileType.image),
    PortfolioItem(id: '3', title: 'Case Study.docx',    type: FileType.word),
    PortfolioItem(id: '4', title: 'Prototype.png',      type: FileType.image),
    PortfolioItem(id: '5', title: 'Brief.pdf',          type: FileType.pdf),
  ];

  bool _isSaving = false;
  bool _isLoading = false;
  String? _error;

  // ── Constructor ──
  ProfileProvider() {
    loadData();
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  ProfileData get profile => _profile;
  List<PortfolioItem> get portfolioItems => List.unmodifiable(_portfolioItems);
  bool get isSaving => _isSaving;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> loadData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final profileFuture = _profileService.fetchProfile();
      final portfolioFuture = _profileService.fetchPortfolio();
      
      final results = await Future.wait([profileFuture, portfolioFuture]);
      
      _profile = results[0] as ProfileData;
      _portfolioItems = results[1] as List<PortfolioItem>;
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
      notifyListeners();
    } catch (e) {
      debugPrint('ProfileProvider.deleteAvatar error: $e');
      _profile = _profile.copyWith(clearAvatar: true);
      notifyListeners();
    }
  }

  Future<void> uploadAvatar(Uint8List bytes, String filename) async {
    try {
      final newUrl = await _profileService.uploadProfilePicture(bytes, filename);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cacheBustedUrl = newUrl.contains('?') ? '$newUrl&t=$timestamp' : '$newUrl?t=$timestamp';
      
      _profile = _profile.copyWith(avatarUrl: cacheBustedUrl);
      notifyListeners();
    } catch (e) {
      debugPrint('ProfileProvider.uploadAvatar error: $e');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _profile = _profile.copyWith(
        avatarUrl: 'https://i.pravatar.cc/150?img=12&t=$timestamp',
      );
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addPortfolioItem(PortfolioItem item, Uint8List bytes) async {
    try {
      final serverItem = await _profileService.addPortfolioItem(item, bytes);
      
      // Merge properties: use local custom title if server's parsed title is empty
      final resolvedItem = PortfolioItem(
        id: serverItem.id.isNotEmpty ? serverItem.id : item.id,
        title: serverItem.title.isNotEmpty ? serverItem.title : item.title,
        type: serverItem.type,
        fileUrl: serverItem.fileUrl ?? item.fileUrl,
      );

      _portfolioItems = [..._portfolioItems, resolvedItem];
      notifyListeners();
    } catch (e) {
      debugPrint('ProfileProvider.addPortfolioItem error: $e');
      _portfolioItems = [..._portfolioItems, item];
      notifyListeners();
      rethrow;
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