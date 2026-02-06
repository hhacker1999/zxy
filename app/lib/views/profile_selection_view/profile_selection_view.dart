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
                                child: Text(
                                  "Enter",
                                  style: Theme.of(context).textTheme.labelSmall!
                                      .copyWith(color: AppTheme.textBlack),
                                ),
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

class _ProfileCard extends StatefulWidget {
  final Profile profile;
  final VoidCallback onTap;

  const _ProfileCard({required this.profile, required this.onTap});

  @override
  State<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<_ProfileCard> {
  bool _isHovered = false;

  Widget build(BuildContext context) {
    final screen = Screen.of(context);
    final size = screen.shouldRenderMobile ? 120.0 : 160.0;
    final fontSize = screen.shouldRenderMobile ? 48.0 : 64.0;

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

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      shape: BoxShape.circle,
                      border: _isHovered
                          ? Border.all(color: Colors.white, width: 4)
                          : null,
                      boxShadow: _isHovered
                          ? [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        widget.profile.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Lock icon for PIN protected
                  if (widget.profile.isPinProtected)
                    Positioned(
                      bottom: 8,
                      right: screen.shouldRenderMobile ? 4 : 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock,
                          size: screen.shouldRenderMobile ? 14 : 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingM),
              Text(
                widget.profile.name,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
