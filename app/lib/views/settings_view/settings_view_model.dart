// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/auth/auth.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/shared/toast.dart';

class SettingsViewModel extends ChangeNotifier {
  final AuthUsecase _authUc;
  late BuildContext _context;
  String _selectedDebridType = "";
  String get selectedDebridType => _selectedDebridType;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  final TextEditingController apiKeyController = TextEditingController();

  // Library items state management
  List<ProfileLibraryItem> _libraryItems = [];
  List<ProfileLibraryItem> get libraryItems => _libraryItems;

  bool _hasLibraryChanges = false;
  bool get hasLibraryChanges => _hasLibraryChanges;

  int? _initializedProfileId;

  SettingsViewModel(this._authUc);

  void init(Profile? currentProfile) {
    if (currentProfile == null) return;

    // Only initialize if we haven't initialized for this profile yet
    if (_initializedProfileId == currentProfile.id) return;

    _initializedProfileId = currentProfile.id;

    if (currentProfile.debridType.isNotEmpty) {
      _selectedDebridType = currentProfile.debridType;
    }
    // Initialize library items from profile
    _libraryItems = List.from(currentProfile.libraryItems);
    _hasLibraryChanges = false;
    // notifyListeners();
  }

  set context(BuildContext context) => _context = context;

  // Library Items CRUD Methods
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
      _isLoading = true;
      notifyListeners();

      await _authUc.updateProfileList(_libraryItems);

      _hasLibraryChanges = false;
      showToast(_context, false, "Home page lists saved", "");
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> storeDebridKey() async {
    try {
      _isLoading = true;
      notifyListeners();
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
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> removeDebridKey() async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authUc.deleteUserDebridKey();
      _selectedDebridType = "";
      final newProfile = await _authUc.getUserProfile();
      _context.read<UserBloc>().profile = newProfile;
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      _isLoading = false;
      notifyListeners();
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
      _isLoading = true;
      notifyListeners();
      await _authUc.createProfile(name, pin, copyDebrid);
      final user = await _authUc.getUser();
      showToast(_context, false, "Profile Created", "");
      _context.read<UserBloc>().user = user;
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(String name, int id, {String? pin}) async {
    try {
      if (name.isEmpty) {
        showToast(_context, true, "Name cannot be empty", "");
        return;
      }
      _isLoading = true;
      notifyListeners();
      await _authUc.updateProfile(name, pin, id);
      final user = await _authUc.getUser();
      final profile = await _authUc.getUserProfile();
      showToast(_context, false, "Profile Updated", "");
      _context.read<UserBloc>().user = user;
      _context.read<UserBloc>().profile = profile;
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProfile(int id) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _authUc.deleteProfile(id);
      final user = await _authUc.getUser();
      showToast(_context, false, "Profile Deleted", "");
      _context.read<UserBloc>().user = user;
    } catch (e) {
      showToast(_context, true, e.toString(), "");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    apiKeyController.dispose();
    super.dispose();
  }
}
