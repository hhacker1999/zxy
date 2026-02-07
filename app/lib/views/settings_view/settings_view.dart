import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_constants.dart';
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
                        // Initialize library items from profile
                        settingsVm.init(profile);
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
                            const SizedBox(height: AppTheme.spacingXL),
                            _buildHomePageCustomizationSection(
                              context,
                              settingsVm,
                            ),
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

Widget _buildHomePageCustomizationSection(
  BuildContext context,
  SettingsViewModel viewModel,
) {
  final isMobile = Screen.of(context).shouldRenderMobile;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Library customization",
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              if (viewModel.hasLibraryChanges)
                Padding(
                  padding: const EdgeInsets.only(right: AppTheme.spacingS),
                  child: ZxyButton(
                    color: AppTheme.accentColor,
                    onTap: viewModel.saveLibraryItems,
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(color: AppTheme.textBlack),
                    ),
                  ),
                ),
              IconButton(
                onPressed: () =>
                    _showLibraryItemForm(context, viewModel, null, -1),
                icon: const Icon(Icons.add),
                tooltip: "Add List",
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: AppTheme.spacingM),
      if (viewModel.libraryItems.isEmpty)
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: AppTheme.roundedMedium,
            border: Border.all(color: AppTheme.surfaceLight.withOpacity(0.3)),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.playlist_add,
                  size: 48,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  "No custom lists yet",
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  "Tap the + button to create your first custom list",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        )
      else
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: AppTheme.roundedMedium,
            border: Border.all(color: AppTheme.surfaceLight.withOpacity(0.3)),
          ),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: viewModel.libraryItems.length,
            onReorder: viewModel.reorderLibraryItems,
            itemBuilder: (context, index) {
              final item = viewModel.libraryItems[index];
              return _LibraryItemTile(
                key: ValueKey('library_item_$index'),
                item: item,
                index: index,
                onEdit: () =>
                    _showLibraryItemForm(context, viewModel, item, index),
                onDelete: () =>
                    _showDeleteConfirmation(context, viewModel, index),
                isMobile: isMobile,
              );
            },
          ),
        ),
    ],
  );
}

void _showLibraryItemForm(
  BuildContext context,
  SettingsViewModel viewModel,
  ProfileLibraryItem? existingItem,
  int index,
) {
  final isMobile = Screen.of(context).shouldRenderMobile;

  if (isMobile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LibraryFilterFormSheet(
        existingItem: existingItem,
        onSave: (item) {
          if (index >= 0) {
            viewModel.updateLibraryItem(index, item);
          } else {
            viewModel.addLibraryItem(item);
          }
        },
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (_) => _LibraryFilterFormDialog(
        existingItem: existingItem,
        onSave: (item) {
          if (index >= 0) {
            viewModel.updateLibraryItem(index, item);
          } else {
            viewModel.addLibraryItem(item);
          }
        },
      ),
    );
  }
}

void _showDeleteConfirmation(
  BuildContext context,
  SettingsViewModel viewModel,
  int index,
) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: const Text("Delete List"),
      content: Text(
        "Are you sure you want to delete '${viewModel.libraryItems[index].name}'?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            viewModel.deleteLibraryItem(index);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
          child: const Text("Delete"),
        ),
      ],
    ),
  );
}

class _LibraryItemTile extends StatelessWidget {
  final ProfileLibraryItem item;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isMobile;

  const _LibraryItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.onEdit,
    required this.onDelete,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceLight.withOpacity(0.2)),
        ),
      ),
      child: ListTile(
        // leading: ReorderableDragStartListener(
        //   index: index,
        //   child: const Icon(Icons.drag_handle, color: AppTheme.textSecondary),
        // ),
        title: Text(
          item.name,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          item.filter.isMovie ? "Movies" : "TV Shows",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppTheme.spacingS,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
              tooltip: "Edit",
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: AppTheme.errorColor,
              ),
              onPressed: onDelete,
              tooltip: "Delete",
            ),
            AppTheme.boxWidthS,
          ],
        ),
      ),
    );
  }
}

// Desktop Dialog for Library Filter Form
class _LibraryFilterFormDialog extends StatefulWidget {
  final ProfileLibraryItem? existingItem;
  final void Function(ProfileLibraryItem) onSave;

  const _LibraryFilterFormDialog({this.existingItem, required this.onSave});

  @override
  State<_LibraryFilterFormDialog> createState() =>
      _LibraryFilterFormDialogState();
}

class _LibraryFilterFormDialogState extends State<_LibraryFilterFormDialog> {
  late TextEditingController _nameController;
  late LibraryFilter _filter;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingItem?.name ?? "",
    );
    _filter = widget.existingItem?.filter ?? LibraryFilter.defaultFilter();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceColor,
      title: Text(widget.existingItem != null ? "Edit List" : "Create List"),
      content: SizedBox(
        width: 500,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(child: _buildFormContent()),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _onSave,
          child: const Text(
            "Save",
            style: TextStyle(color: AppTheme.textBlack),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTheme.boxHeightS,
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: "List Name",
            hintText: "e.g. Top Rated Action Movies",
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        // Media Type
        _buildSwitchField(
          label: "Media Type",
          value: _filter.isMovie,
          trueLabel: "Movies",
          falseLabel: "TV Shows",
          onChanged: (val) =>
              setState(() => _filter = _filter.copyWith(isMovie: val)),
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Time Period
        _buildTimePeriodSelector(),
        const SizedBox(height: AppTheme.spacingM),
        // Date Type (for shows only)
        if (!_filter.isMovie)
          _buildDropdownField(
            label: "Date Type",
            value: _filter.isFirstAir ? "first" : "last",
            items: const [
              DropdownMenuItem(value: "first", child: Text("First Air Date")),
              DropdownMenuItem(value: "last", child: Text("Last Air Date")),
            ],
            onChanged: (val) => setState(
              () => _filter = _filter.copyWith(isFirstAir: val == "first"),
            ),
          ),
        if (!_filter.isMovie) const SizedBox(height: AppTheme.spacingM),
        // IMDB Rating
        _buildDropdownField(
          label: "Min IMDB Rating",
          value: _filter.imdbRating,
          items: List.generate(
            10,
            (i) =>
                DropdownMenuItem(value: i, child: Text(i == 0 ? "Any" : "$i+")),
          ),
          onChanged: (val) =>
              setState(() => _filter = _filter.copyWith(imdbRating: val ?? 0)),
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Language
        _buildDropdownField(
          label: "Language",
          value: _filter.language.isEmpty ? null : _filter.language,
          items: [
            const DropdownMenuItem(value: null, child: Text("Any Language")),
            ...AppConstants.isoLanguages.entries.map(
              (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
            ),
          ],
          onChanged: (val) =>
              setState(() => _filter = _filter.copyWith(language: val ?? "")),
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Included Genres
        _buildGenreSelector(
          label: "Include Genres",
          selectedGenres: _filter.includedGenres,
          onChanged: (genres) => setState(
            () => _filter = _filter.copyWith(includedGenres: genres),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Excluded Genres
        _buildGenreSelector(
          label: "Exclude Genres",
          selectedGenres: _filter.excludedGenres,
          onChanged: (genres) => setState(
            () => _filter = _filter.copyWith(excludedGenres: genres),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Items Count
        _buildDropdownField(
          label: "Items in List",
          value: _filter.items,
          items: const [
            DropdownMenuItem(value: 10, child: Text("10")),
            DropdownMenuItem(value: 20, child: Text("20")),
            DropdownMenuItem(value: 30, child: Text("30")),
            DropdownMenuItem(value: 50, child: Text("50")),
          ],
          onChanged: (val) =>
              setState(() => _filter = _filter.copyWith(items: val ?? 20)),
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Sort Type
        _buildDropdownField(
          label: "Sort By",
          value: _filter.sort,
          items: const [
            DropdownMenuItem(value: "popularity", child: Text("Popularity")),
            DropdownMenuItem(value: "imdb_rating", child: Text("IMDB Rating")),
            DropdownMenuItem(value: "date", child: Text("Release Date")),
          ],
          onChanged: (val) => setState(
            () => _filter = _filter.copyWith(sort: val ?? "popularity"),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Sort Order
        _buildSwitchField(
          label: "Sort Order",
          value: _filter.isAsc,
          trueLabel: "Ascending",
          falseLabel: "Descending",
          onChanged: (val) =>
              setState(() => _filter = _filter.copyWith(isAsc: val)),
        ),
      ],
    );
  }

  Widget _buildSwitchField({
    required String label,
    required bool value,
    required String trueLabel,
    required String falseLabel,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(trueLabel)),
            ButtonSegment(value: false, label: Text(falseLabel)),
          ],
          selected: {value},
          onSelectionChanged: (set) => onChanged(set.first),
        ),
      ],
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePeriodSelector() {
    String currentPeriod = "all";
    if (_filter.thisWeek) {
      currentPeriod = "week";
    } else if (_filter.thisMonth) {
      currentPeriod = "month";
    } else if (_filter.years.isNotEmpty) {
      if (_filter.years.length == 1) {
        currentPeriod = _filter.years.first.toString();
      } else {
        // It's a decade
        final decade = (_filter.years.first ~/ 10) * 10;
        currentPeriod = "${decade}s";
      }
    }

    final currentYear = DateTime.now().year;
    final currentDecade = (currentYear ~/ 10) * 10;

    final List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem(value: "all", child: Text("All Time")),
      const DropdownMenuItem(value: "week", child: Text("This Week")),
      const DropdownMenuItem(value: "month", child: Text("This Month")),
      // Current decade years
      ...List.generate(currentYear - currentDecade + 1, (i) {
        final year = currentYear - i;
        return DropdownMenuItem(
          value: year.toString(),
          child: Text(year.toString()),
        );
      }),
      // Previous decades
      ...List.generate(4, (i) {
        final decade = currentDecade - ((i + 1) * 10);
        return DropdownMenuItem(value: "${decade}s", child: Text("${decade}s"));
      }),
    ];

    return _buildDropdownField(
      label: "Time Period",
      value: currentPeriod,
      items: items,
      onChanged: (val) {
        setState(() {
          if (val == "week") {
            _filter = _filter.copyWith(
              thisWeek: true,
              thisMonth: false,
              years: [],
            );
          } else if (val == "month") {
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: true,
              years: [],
            );
          } else if (val == "all") {
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: false,
              years: [],
            );
          } else if (val != null && val.endsWith("s")) {
            // Decade
            final decade = int.parse(val.replaceAll("s", ""));
            final years = List.generate(10, (i) => decade + i);
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: false,
              years: years,
            );
          } else if (val != null) {
            // Single year
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: false,
              years: [int.parse(val)],
            );
          }
        });
      },
    );
  }

  Widget _buildGenreSelector({
    required String label,
    required List<int> selectedGenres,
    required ValueChanged<List<int>> onChanged,
  }) {
    final genres = _filter.isMovie
        ? AppConstants.movieGenre
        : AppConstants.showGenre;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingS),
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          children: genres.entries.map((entry) {
            final isSelected = selectedGenres.contains(entry.key);
            return FilterChip(
              label: Text(entry.value.name),
              selected: isSelected,
              onSelected: (selected) {
                final newList = List<int>.from(selectedGenres);
                if (selected) {
                  newList.add(entry.key);
                } else {
                  newList.remove(entry.key);
                }
                onChanged(newList);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  void _onSave() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a list name")));
      return;
    }

    final item = ProfileLibraryItem(
      name: _nameController.text,
      filter: _filter,
    );
    widget.onSave(item);
    Navigator.pop(context);
  }
}

// Mobile Bottom Sheet for Library Filter Form
class _LibraryFilterFormSheet extends StatefulWidget {
  final ProfileLibraryItem? existingItem;
  final void Function(ProfileLibraryItem) onSave;

  const _LibraryFilterFormSheet({this.existingItem, required this.onSave});

  @override
  State<_LibraryFilterFormSheet> createState() =>
      _LibraryFilterFormSheetState();
}

class _LibraryFilterFormSheetState extends State<_LibraryFilterFormSheet> {
  late TextEditingController _nameController;
  late LibraryFilter _filter;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingItem?.name ?? "",
    );
    _filter = widget.existingItem?.filter ?? LibraryFilter.defaultFilter();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            left: AppTheme.spacingM,
            right: AppTheme.spacingM,
            top: AppTheme.spacingM,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingM,
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppTheme.spacingM),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.existingItem != null ? "Edit List" : "Create List",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              // Form content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [_buildMobileFormContent()],
                ),
              ),
              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text("Save"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileFormContent() {
    final genres = _filter.isMovie
        ? AppConstants.movieGenre
        : AppConstants.showGenre;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: "List Name",
            hintText: "e.g. Top Rated Action Movies",
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        // Media Type
        Text("Media Type", style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingS),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text("Movies")),
            ButtonSegment(value: false, label: Text("TV Shows")),
          ],
          selected: {_filter.isMovie},
          onSelectionChanged: (set) =>
              setState(() => _filter = _filter.copyWith(isMovie: set.first)),
        ),
        const SizedBox(height: AppTheme.spacingL),
        // Time Period
        _buildMobileDropdown(
          label: "Time Period",
          child: _buildTimePeriodDropdown(),
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Date Type (for shows)
        if (!_filter.isMovie) ...[
          _buildMobileDropdown(
            label: "Date Type",
            child: DropdownButtonFormField<String>(
              value: _filter.isFirstAir ? "first" : "last",
              items: const [
                DropdownMenuItem(value: "first", child: Text("First Air Date")),
                DropdownMenuItem(value: "last", child: Text("Last Air Date")),
              ],
              onChanged: (val) => setState(
                () => _filter = _filter.copyWith(isFirstAir: val == "first"),
              ),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
        ],
        // IMDB Rating
        _buildMobileDropdown(
          label: "Min IMDB Rating",
          child: DropdownButtonFormField<int>(
            value: _filter.imdbRating,
            items: List.generate(
              10,
              (i) => DropdownMenuItem(
                value: i,
                child: Text(i == 0 ? "Any" : "$i+"),
              ),
            ),
            onChanged: (val) => setState(
              () => _filter = _filter.copyWith(imdbRating: val ?? 0),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Language
        _buildMobileDropdown(
          label: "Language",
          child: DropdownButtonFormField<String?>(
            value: _filter.language.isEmpty ? null : _filter.language,
            items: [
              const DropdownMenuItem(value: null, child: Text("Any Language")),
              ...AppConstants.isoLanguages.entries.map(
                (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
              ),
            ],
            onChanged: (val) =>
                setState(() => _filter = _filter.copyWith(language: val ?? "")),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        // Included Genres
        Text("Include Genres", style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingS),
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          children: genres.entries.map((entry) {
            final isSelected = _filter.includedGenres.contains(entry.key);
            return FilterChip(
              label: Text(entry.value.name),
              selected: isSelected,
              onSelected: (selected) {
                final newList = List<int>.from(_filter.includedGenres);
                if (selected) {
                  newList.add(entry.key);
                } else {
                  newList.remove(entry.key);
                }
                setState(
                  () => _filter = _filter.copyWith(includedGenres: newList),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.spacingL),
        // Excluded Genres
        Text("Exclude Genres", style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingS),
        Wrap(
          spacing: AppTheme.spacingS,
          runSpacing: AppTheme.spacingS,
          children: genres.entries.map((entry) {
            final isSelected = _filter.excludedGenres.contains(entry.key);
            return FilterChip(
              label: Text(entry.value.name),
              selected: isSelected,
              onSelected: (selected) {
                final newList = List<int>.from(_filter.excludedGenres);
                if (selected) {
                  newList.add(entry.key);
                } else {
                  newList.remove(entry.key);
                }
                setState(
                  () => _filter = _filter.copyWith(excludedGenres: newList),
                );
              },
            );
          }).toList(),
        ),
        const SizedBox(height: AppTheme.spacingL),
        // Items Count
        _buildMobileDropdown(
          label: "Items in List",
          child: DropdownButtonFormField<int>(
            value: _filter.items,
            items: const [
              DropdownMenuItem(value: 10, child: Text("10")),
              DropdownMenuItem(value: 20, child: Text("20")),
              DropdownMenuItem(value: 30, child: Text("30")),
              DropdownMenuItem(value: 50, child: Text("50")),
            ],
            onChanged: (val) =>
                setState(() => _filter = _filter.copyWith(items: val ?? 20)),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),
        // Sort Type
        _buildMobileDropdown(
          label: "Sort By",
          child: DropdownButtonFormField<String>(
            value: _filter.sort,
            items: const [
              DropdownMenuItem(value: "popularity", child: Text("Popularity")),
              DropdownMenuItem(
                value: "imdb_rating",
                child: Text("IMDB Rating"),
              ),
              DropdownMenuItem(value: "date", child: Text("Release Date")),
            ],
            onChanged: (val) => setState(
              () => _filter = _filter.copyWith(sort: val ?? "popularity"),
            ),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingL),
        // Sort Order
        Text("Sort Order", style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingS),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text("Descending")),
            ButtonSegment(value: true, label: Text("Ascending")),
          ],
          selected: {_filter.isAsc},
          onSelectionChanged: (set) =>
              setState(() => _filter = _filter.copyWith(isAsc: set.first)),
        ),
        const SizedBox(height: AppTheme.spacingXL),
      ],
    );
  }

  Widget _buildMobileDropdown({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppTheme.spacingS),
        child,
      ],
    );
  }

  Widget _buildTimePeriodDropdown() {
    String currentPeriod = "all";
    if (_filter.thisWeek) {
      currentPeriod = "week";
    } else if (_filter.thisMonth) {
      currentPeriod = "month";
    } else if (_filter.years.isNotEmpty) {
      if (_filter.years.length == 1) {
        currentPeriod = _filter.years.first.toString();
      } else {
        final decade = (_filter.years.first ~/ 10) * 10;
        currentPeriod = "${decade}s";
      }
    }

    final currentYear = DateTime.now().year;
    final currentDecade = (currentYear ~/ 10) * 10;

    final List<DropdownMenuItem<String>> items = [
      const DropdownMenuItem(value: "all", child: Text("All Time")),
      const DropdownMenuItem(value: "week", child: Text("This Week")),
      const DropdownMenuItem(value: "month", child: Text("This Month")),
      ...List.generate(currentYear - currentDecade + 1, (i) {
        final year = currentYear - i;
        return DropdownMenuItem(
          value: year.toString(),
          child: Text(year.toString()),
        );
      }),
      ...List.generate(4, (i) {
        final decade = currentDecade - ((i + 1) * 10);
        return DropdownMenuItem(value: "${decade}s", child: Text("${decade}s"));
      }),
    ];

    return DropdownButtonFormField<String>(
      value: currentPeriod,
      items: items,
      onChanged: (val) {
        setState(() {
          if (val == "week") {
            _filter = _filter.copyWith(
              thisWeek: true,
              thisMonth: false,
              years: [],
            );
          } else if (val == "month") {
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: true,
              years: [],
            );
          } else if (val == "all") {
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: false,
              years: [],
            );
          } else if (val != null && val.endsWith("s")) {
            final decade = int.parse(val.replaceAll("s", ""));
            final years = List.generate(10, (i) => decade + i);
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: false,
              years: years,
            );
          } else if (val != null) {
            _filter = _filter.copyWith(
              thisWeek: false,
              thisMonth: false,
              years: [int.parse(val)],
            );
          }
        });
      },
      decoration: const InputDecoration(
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  void _onSave() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a list name")));
      return;
    }

    final item = ProfileLibraryItem(
      name: _nameController.text,
      filter: _filter,
    );
    widget.onSave(item);
    Navigator.pop(context);
  }
}
