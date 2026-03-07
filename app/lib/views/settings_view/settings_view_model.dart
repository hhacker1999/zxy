// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/service/web_socket.dart';
import 'package:zxy_app/usecase/auth/auth.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/base_home_view/base_home_view_model.dart';
import 'package:zxy_app/views/home_view/home_view_model.dart';
import 'package:zxy_app/views/shared/toast.dart';

class SettingsViewModel extends ChangeNotifier {
  final WebSocketService wsService;
  final AuthUsecase _authUc;
  late BuildContext _context;
  String _selectedDebridType = "";
  String get selectedDebridType => _selectedDebridType;

  final TextEditingController apiKeyController = TextEditingController();

  List<ProfileLibraryItem> _libraryItems = [];
  List<ProfileLibraryItem> get libraryItems => _libraryItems;

  bool _hasLibraryChanges = false;
  bool get hasLibraryChanges => _hasLibraryChanges;

  int? _initializedProfileId;
  Timer? _traktLoginTimer;

  SettingsViewModel(this._authUc, this.wsService);

  void init(Profile? currentProfile) {
    if (currentProfile == null) return;

    // Only initialize if we haven't initialized for this profile yet
    if (_initializedProfileId == currentProfile.id) return;

    _initializedProfileId = currentProfile.id;

    if (currentProfile.debridType.isNotEmpty) {
      _selectedDebridType = currentProfile.debridType;
    }
    _libraryItems = List.from(currentProfile.libraryItems);
    _hasLibraryChanges = false;
  }

  set context(BuildContext context) => _context = context;

  void addLibraryItem(ProfileLibraryItem item) {
    _libraryItems.add(item);
    _hasLibraryChanges = true;
    notifyListeners();
  }

  void updateLibraryItem(int index, ProfileLibraryItem item) {
    if (index >= 0 && index < _libraryItems.length) {
      _libraryItems[index] = item;
      _hasLibraryChanges = true;
      notifyListeners();
    }
  }

  void deleteLibraryItem(int index) {
    if (index >= 0 && index < _libraryItems.length) {
      _libraryItems.removeAt(index);
      _hasLibraryChanges = true;
      notifyListeners();
    }
  }

  void reorderLibraryItems(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _libraryItems.removeAt(oldIndex);
    _libraryItems.insert(newIndex, item);
    _hasLibraryChanges = true;
    notifyListeners();
  }

  Future<void> saveLibraryItems() async {
    try {
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = true;
      await _authUc.updateProfileList(_libraryItems);
      final profile = await _authUc.getUserProfile();
      _context.read<UserBloc>().profile = profile;
      _context.read<HomeViewModel>().reload(_context);
      _hasLibraryChanges = false;
      showToast(_context, false, "Home page lists saved", "");
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      notifyListeners();
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = false;
    }
  }

  Future<void> storeDebridKey() async {
    try {
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = true;
      if (_selectedDebridType != "tb" && _selectedDebridType != "rd") {
        showToast(_context, true, "Invalid debrid provider", "");
        return;
      }
      if (apiKeyController.text.isEmpty) {
        showToast(_context, true, "Invalid api key", "");
        return;
      }
      await _authUc.storeUserDebridKey(
        _selectedDebridType,
        apiKeyController.text,
      );
      final newProfile = await _authUc.getUserProfile();
      _context.read<UserBloc>().profile = newProfile;
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      notifyListeners();
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = false;
    }
  }

  Future<void> removeDebridKey() async {
    try {
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = true;
      await _authUc.deleteUserDebridKey();
      _selectedDebridType = "";
      final newProfile = await _authUc.getUserProfile();
      _context.read<UserBloc>().profile = newProfile;
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      notifyListeners();
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = false;
    }
  }

  void selectDebridType(String type) {
    if (_selectedDebridType != type) {
      _selectedDebridType = type;
      notifyListeners();
    }
  }

  Future<void> createProfile(String name, String? pin, bool copyDebrid) async {
    try {
      if (name.isEmpty) {
        showToast(_context, true, "Name cannot be empty", "");
        return;
      }
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = true;
      await _authUc.createProfile(name, pin, copyDebrid);
      final user = await _authUc.getUser();
      showToast(_context, false, "Profile Created", "");
      _context.read<UserBloc>().user = user;
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      notifyListeners();
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = false;
    }
  }

  Future<void> updateProfile(String name, int id, {String? pin}) async {
    try {
      if (name.isEmpty) {
        showToast(_context, true, "Name cannot be empty", "");
        return;
      }
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = true;
      await _authUc.updateProfile(name, pin, id);
      final user = await _authUc.getUser();
      final profile = await _authUc.getUserProfile();
      showToast(_context, false, "Profile Updated", "");
      _context.read<UserBloc>().user = user;
      _context.read<UserBloc>().profile = profile;
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      notifyListeners();
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = false;
    }
  }

  Future<void> loginTrakt() async {
    try {
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = true;
      _context.read<UserBloc>().waitingTraktLogin.value = true;
      final url = await _authUc.getTraktLoginUrl();
      await launchUrlString(url, mode: LaunchMode.platformDefault);
      _traktLoginTimer?.cancel();
      _traktLoginTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        final profile = await _authUc.getUserProfile();
        if (profile.isTraktValid) {
          _traktLoginTimer?.cancel();
          _context.read<UserBloc>().waitingTraktLogin.value = false;
          _context.read<UserBloc>().profile = profile;
          // NOTE: Update continue watching now
          _context.read<HomeViewModel>().initialiseContinueWatching();
        }
      });
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = false;
    }
  }

  Future<void> deleteTrakt() async {
    try {
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = true;
      await _authUc.deleteTraktLogin();
      final profile = await _authUc.getUserProfile();
      _context.read<UserBloc>().profile = profile;
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = false;
    }
  }

  Future<void> deleteProfile(int id) async {
    try {
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = true;
      await _authUc.deleteProfile(id);
      final user = await _authUc.getUser();
      showToast(_context, false, "Profile Deleted", "");
      _context.read<UserBloc>().user = user;
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      notifyListeners();
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = false;
    }
  }

  Future<void> logout() async {
    try {
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = true;
      await _authUc.logout();
      wsService.clean();
      showToast(_context, false, "Logged out", "");
      Navigator.pushNamedAndRemoveUntil(_context, AppRoutes.loginView, (_) {
        return false;
      });
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      notifyListeners();
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    try {
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = true;
      await _authUc.deleteAccount();
      showToast(_context, false, "Account Deleted successfully", "");
      Navigator.pushNamedAndRemoveUntil(_context, AppRoutes.loginView, (_) {
        return false;
      });
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      notifyListeners();
      _context.read<BaseHomeViewModel>().scaffoldLoading.value = false;
    }
  }

  @override
  void dispose() {
    apiKeyController.dispose();
    _traktLoginTimer?.cancel();
    super.dispose();
  }
}
