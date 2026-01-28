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
        final settingsVm = context.watch<SettingsViewModel>();
        return Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: ValueListenableBuilder<Profile?>(
                  valueListenable: userBloc.profileNotifier,
                  builder: (_, profile, _) {
                    if (profile == null) return const SizedBox();
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
                        Text(
                          "Debrid Integration",
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        _buildDebridSection(context, profile),
                      ],
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
                viewModel.removeDebridKey(context);
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
                viewModel.storeDebridKey(context);
              },
              child: const Text("Add API Key"),
            ),
          ),
        ],
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
