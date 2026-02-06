import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_routes.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/settings_bloc.dart';
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
                        final settingsBloc = context.read<SettingsBloc>();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Account",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                FilledButton.tonalIcon(
                                  onPressed: () {
                                    Navigator.of(
                                      context,
                                    ).pushNamed(AppRoutes.profileSelectionView);
                                  },
                                  icon: const Icon(
                                    Icons.people_outline,
                                    size: 18,
                                  ),
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
                              const SizedBox(height: AppTheme.spacingXL),
                            ],
                            Text(
                              "General",
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: AppTheme.spacingM),
                            _buildGeneralSection(context, settingsBloc),
                            const SizedBox(height: AppTheme.spacingXL),
                            Text(
                              "Debrid Integration",
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildGeneralSection(BuildContext context, SettingsBloc settingsBloc) {
    final isMobile = Screen.of(context).shouldRenderMobile;

    return Container(
      padding: EdgeInsets.all(isMobile ? AppTheme.spacingM : AppTheme.spacingL),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.surfaceColor,
            AppTheme.surfaceColor.withOpacity(0.8),
          ],
        ),
        borderRadius: AppTheme.roundedLarge,
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _ModernSettingTile(
            title: "AMOLED Theme",
            subtitle: "Pure black background for OLED displays",
            icon: Icons.dark_mode_outlined,
            valueNotifier: settingsBloc.isAmoled,
            onChanged: (value) {
              settingsBloc.isAmoled = value;
            },
          ),
          const SizedBox(height: AppTheme.spacingM),
          _ModernSettingTile(
            title: "Show Poster Ratings",
            subtitle: "Display ratings on movie and TV show posters",
            icon: Icons.star_outline,
            valueNotifier: settingsBloc.showPosterRatings,
            onChanged: (value) {
              settingsBloc.showPosterRatings = value;
            },
          ),
        ],
      ),
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

class _ProfileChip extends StatefulWidget {
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
  State<_ProfileChip> createState() => _ProfileChipState();
}

class _ProfileChipState extends State<_ProfileChip> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isMobile = Screen.of(context).shouldRenderMobile;

    // Netflix-style solid colors
    final colors = [
      const Color(0xFF229ED9), // Blue
      const Color(0xFFE50914), // Netflix Red
      const Color(0xFF2E7D32), // Green
      const Color(0xFFFFA000), // Yellow
      const Color(0xFF7B1FA2), // Purple
      const Color(0xFF00ACC1), // Cyan
    ];
    final avatarColor =
        colors[widget.profile.name.hashCode.abs() % colors.length];

    // Show buttons on mobile always, or on hover for desktop
    final showButtons = isMobile || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 160,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar container
            Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    borderRadius: BorderRadius.circular(8),
                    border: widget.isCurrent
                        ? Border.all(color: AppTheme.textPrimary, width: 4)
                        : _isHovered
                        ? Border.all(color: Colors.white, width: 3)
                        : null,
                    boxShadow: _isHovered
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      widget.profile.name.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                // Admin badge
                if (widget.profile.isAdmin)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            "Admin",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Menu button (shown on hover or always on mobile)
                if (showButtons)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: PopupMenuButton<String>(
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.more_horiz,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                      offset: const Offset(0, 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          widget.onEdit();
                        } else if (value == 'delete') {
                          widget.onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 12),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        if (!widget.isCurrent)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: AppTheme.errorColor,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: AppTheme.errorColor),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            // Profile name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    widget.profile.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: widget.isCurrent
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.isCurrent) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.spacingL,
          horizontal: AppTheme.spacingM,
        ),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.accentColor.withOpacity(0.2),
                    AppTheme.accentColor.withOpacity(0.1),
                  ],
                )
              : null,
          color: isSelected ? null : AppTheme.surfaceColor,
          borderRadius: AppTheme.roundedLarge,
          border: Border.all(
            color: isSelected
                ? AppTheme.accentColor
                : AppTheme.surfaceLight.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              Icons.cloud_download_outlined,
              size: 40,
              color: isSelected ? AppTheme.accentColor : AppTheme.textSecondary,
            ),
            const SizedBox(height: AppTheme.spacingM),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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

class _ModernSettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueNotifier<bool> valueNotifier;
  final ValueChanged<bool> onChanged;

  const _ModernSettingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.valueNotifier,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: valueNotifier,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(AppTheme.spacingM),
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight.withOpacity(0.3),
            borderRadius: AppTheme.roundedMedium,
            border: Border.all(
              color: value
                  ? AppTheme.accentColor.withOpacity(0.3)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: value
                      ? AppTheme.accentColor.withOpacity(0.1)
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: value ? AppTheme.accentColor : AppTheme.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppTheme.accentColor,
              ),
            ],
          ),
        );
      },
    );
  }
}
