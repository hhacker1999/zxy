import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/bloc/user_bloc.dart';
import 'package:zxy_app/usecase/auth/user.dart';
import 'package:zxy_app/views/profile_selection_view/profile_selection_view_model.dart';
import 'package:zxy_app/views/screen.dart';
import 'package:zxy_app/views/shared/zxy_button.dart';

class ProfileSelectionView extends StatelessWidget {
  const ProfileSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final user = context.watch<UserBloc>().userNotifier.value;
        if (user == null) {
          return const Scaffold(body: Center(child: Text("No User Logged In")));
        }
        final viewModel = context.watch<ProfileSelectionViewModel>();
        return Scaffold(
          backgroundColor: AppTheme.backgroundDark,
          body: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppTheme.spacingL),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Who's Watching?",
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: AppTheme.spacingXXL),
                      Wrap(
                        spacing: AppTheme.spacingL,
                        runSpacing: AppTheme.spacingL,
                        alignment: WrapAlignment.center,
                        children: user.profiles.map((profile) {
                          return _ProfileCard(
                            profile: profile,
                            onTap: () =>
                                viewModel.selectProfile(context, profile),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // PIN Overlay
              if (viewModel.showPinInput)
                Container(
                  color: Colors.black.withOpacity(0.8),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(AppTheme.spacingXL),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: AppTheme.roundedLarge,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Enter PIN",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          TextField(
                            controller: viewModel.pinController,
                            autofocus: true,
                            maxLength: 6,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              letterSpacing: 8,
                              color: AppTheme.textPrimary,
                            ),
                            decoration: InputDecoration(
                              counterText: "",
                              border: OutlineInputBorder(
                                borderRadius: AppTheme.roundedMedium,
                              ),
                              fillColor: AppTheme.backgroundDark,
                              filled: true,
                            ),
                            onSubmitted: (_) => viewModel.submitPin(context),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: viewModel.cancelPinInput,
                                child: const Text("Cancel"),
                              ),
                              const SizedBox(width: AppTheme.spacingM),
                              ZxyButton(
                                onTap: () => viewModel.submitPin(context),
                                color: AppTheme.accentColor,
                                child: const Text("Enter"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (viewModel.isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Profile profile;
  final VoidCallback onTap;

  const _ProfileCard({required this.profile, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screen = Screen.of(context);
    final size = screen.shouldRenderMobile ? 120.0 : 160.0;

    return InkWell(
      splashColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(
                size / 2,
              ),
              border: Border.all(color: Colors.transparent, width: 2),
            ),
            // Placeholder for avatar logic - assuming standard or name initials
            child: Center(
              child: Text(
                profile.name.substring(0, 1).toUpperCase(),
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingM),
          Text(
            profile.name,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (profile.isPinProtected)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Icon(Icons.lock, size: 14, color: AppTheme.textSecondary),
            ),
        ],
      ),
    );
  }
}
