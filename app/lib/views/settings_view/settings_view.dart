import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/zxy_button.dart';

import 'settings_view_model.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final userBloc = context.read<UserBloc>();
        final settingsVm = context.watch<SettingsViewModel>()
          ..context = context;
        return Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: ValueListenableBuilder<Profile?>(
                  valueListenable: userBloc.profileNotifier,
                  builder: (_, profile, _) {
                    if (profile == null) return const SizedBox();
                    // We also need the full User object to list all profiles
                    return ValueListenableBuilder<User?>(
                      valueListenable: userBloc.userNotifier,
                      builder: (_, user, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Account",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutes.profileSelectionView);
                                  },
                                  icon: const Icon(Icons.people_outline),
                                  label: const Text("Switch Profile"),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppTheme.spacingL),
                            // Profile Management Section (Admin Only)
                            if (profile.isAdmin && user != null) ...[
                              _buildProfileManagementSection(
                                context,
                                user,
                                profile,
                              ),
                              const SizedBox(height: AppTheme.spacingL),
                            ],
                            Text(
                              "Debrid Integration",
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            _buildDebridSection(context, profile),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            if (settingsVm.isLoading)
              // 1. Block interactions
              const Opacity(
                opacity: 0.3,
                child: ModalBarrier(dismissible: false, color: Colors.black),
              ),
            if (settingsVm.isLoading)
              // 2. Show indicator
              const Center(child: CircularProgressIndicator()),
          ],
        );
      },
    );
  }

  Widget _buildDebridSection(BuildContext context, Profile profile) {
    final viewModel = context.watch<SettingsViewModel>();
    final isConnected = profile.debridType.isNotEmpty;
    final isMobile = Screen.of(context).shouldRenderMobile;

    if (isConnected) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: AppTheme.roundedMedium,
          border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.successColor),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  "Connected to ${profile.debridType == 'rd' ? 'Real Debrid' : 'Torbox'}",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            ZxyButton(
              color: AppTheme.errorColor.withOpacity(0.2),
              child: Text(
                "Disconnect",
                style: TextStyle(color: AppTheme.errorColor),
              ),
              onTap: () {
                viewModel.removeDebridKey();
              },
            ),
          ],
        ),
      );
    }

    // Disconnected State
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile)
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: _DebridSelectionCard(
                  title: "Real Debrid",
                  isSelected: viewModel.selectedDebridType == 'rd',
                  onTap: () => viewModel.selectDebridType('rd'),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              SizedBox(
                width: double.infinity,
                child: _DebridSelectionCard(
                  title: "Torbox",
                  isSelected: viewModel.selectedDebridType == 'tb',
                  onTap: () => viewModel.selectDebridType('tb'),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _DebridSelectionCard(
                  title: "Real Debrid",
                  isSelected: viewModel.selectedDebridType == 'rd',
                  onTap: () => viewModel.selectDebridType('rd'),
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: _DebridSelectionCard(
                  title: "Torbox",
                  isSelected: viewModel.selectedDebridType == 'tb',
                  onTap: () => viewModel.selectDebridType('tb'),
                ),
              ),
            ],
          ),

        // Show input field if a type is selected
        if (viewModel.selectedDebridType.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingL),
          TextField(
            controller: viewModel.apiKeyController,
            decoration: InputDecoration(
              labelText:
                  "${viewModel.selectedDebridType == 'rd' ? 'Real Debrid' : 'Torbox'} API Key",
              hintText: "Enter your API key here",
              prefixIcon: Icon(Icons.vpn_key, color: AppTheme.accentColor),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Align(
            alignment: Alignment.centerRight,
            child: ZxyButton(
              color: AppTheme.accentColor,
              onTap: () {
                viewModel.storeDebridKey();
              },
              child: const Text("Add API Key"),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildProfileManagementSection(
    BuildContext context,
    User user,
    Profile currentProfile,
  ) {
    final viewModel = context.read<SettingsViewModel>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Profiles", style: Theme.of(context).textTheme.titleLarge),
            IconButton(
              onPressed: () =>
                  _showProfileDialog(context, currentProfile: currentProfile),
              icon: const Icon(Icons.add),
              tooltip: "Create Profile",
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingM),
        Wrap(
          spacing: AppTheme.spacingM,
          runSpacing: AppTheme.spacingM,
          children:
              [
                _ProfileChip(
                  profile: currentProfile,
                  onEdit: () => _showProfileDialog(
                    context,
                    profileToEdit: currentProfile,
                    currentProfile: currentProfile,
                  ),
                  onDelete: () => viewModel.deleteProfile(currentProfile.id),
                  isCurrent: true,
                ),
              ]..addAll(
                user.profiles.where((e) => e.id != currentProfile.id).map((p) {
                  return _ProfileChip(
                    profile: p,
                    onEdit: () => _showProfileDialog(
                      context,
                      profileToEdit: p,
                      currentProfile: currentProfile,
                    ),
                    onDelete: () => viewModel.deleteProfile(p.id),
                    isCurrent: p.id == currentProfile.id,
                  );
                }).toList(),
              ),
        ),
      ],
    );
  }

  void _showProfileDialog(
    BuildContext context, {
    Profile? profileToEdit,
    required Profile currentProfile,
  }) {
    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<SettingsViewModel>(),
        child: _ProfileDialog(
          profileToEdit: profileToEdit,
          currentProfile: currentProfile,
        ),
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final Profile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isCurrent;

  const _ProfileChip({
    required this.profile,
    required this.onEdit,
    required this.onDelete,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      padding: const EdgeInsets.all(AppTheme.spacingS),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: AppTheme.roundedMedium,
        border: isCurrent ? Border.all(color: AppTheme.accentColor) : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (profile.isAdmin)
                Icon(
                  Icons.admin_panel_settings,
                  size: 16,
                  color: AppTheme.accentColor,
                )
              else
                const SizedBox(width: 16),

              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.edit, size: 16),
                onPressed: onEdit,
              ),
            ],
          ),
          CircleAvatar(
            backgroundColor: AppTheme.surfaceColor,
            child: Text(profile.name.substring(0, 1)),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Text(
            profile.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          if (!isCurrent)
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: AppTheme.errorColor,
                size: 18,
              ),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}

class _ProfileDialog extends StatefulWidget {
  final Profile? profileToEdit;
  final Profile currentProfile;

  const _ProfileDialog({this.profileToEdit, required this.currentProfile});

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late TextEditingController _nameController;
  late TextEditingController _pinController;
  bool _copyDebrid = false;

  bool get isEditing => widget.profileToEdit != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.profileToEdit?.name ?? "",
    );
    _pinController =
        TextEditingController(); // Don't pre-fill PIN for security/edit logic simplicity
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.read<SettingsViewModel>();
    final hasDebrid = widget.currentProfile.debridType.isNotEmpty;

    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: Text(isEditing ? "Edit Profile" : "Create Profile"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Profile Name"),
          ),
          const SizedBox(height: AppTheme.spacingM),
          TextField(
            controller: _pinController,
            decoration: const InputDecoration(labelText: "PIN (Optional)"),
            keyboardType: TextInputType.number,
            maxLength: 6,
            obscureText: true,
          ),
          if (!isEditing && hasDebrid) ...[
            const SizedBox(height: AppTheme.spacingM),
            CheckboxListTile(
              title: const Text("Include Debrid Key"),
              subtitle: const Text("Copy from current profile"),
              value: _copyDebrid,
              onChanged: (val) => setState(() => _copyDebrid = val ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (isEditing) {
              viewModel.updateProfile(
                _nameController.text.isEmpty ? "" : _nameController.text,
                widget.profileToEdit!.id,
                pin: _pinController.text.isNotEmpty
                    ? _pinController.text
                    : null,
              );
            } else {
              viewModel.createProfile(
                _nameController.text,
                _pinController.text.isNotEmpty ? _pinController.text : null,
                _copyDebrid,
              );
            }
            Navigator.pop(context);
          },
          child: Text(isEditing ? "Save" : "Create"),
        ),
      ],
    );
  }
}

class _DebridSelectionCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _DebridSelectionCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingL,
          horizontal: AppTheme.spacingM,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentColor.withOpacity(0.1)
              : AppTheme.surfaceColor,
          borderRadius: AppTheme.roundedMedium,
          border: Border.all(
            color: isSelected ? AppTheme.accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Placeholder Icon/Logo could go here
            Icon(
              Icons.cloud_download_outlined,
              size: 32,
              color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected
                    ? AppTheme.textPrimary
                    : AppTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
