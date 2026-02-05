import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zxy_app/app_theme.dart';
import 'package:zxy_app/views/login_view/login_view_model.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final LoginViewModel viewModel;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    viewModel = context.read<LoginViewModel>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: ValueListenableBuilder<bool>(
            valueListenable: viewModel.isLoginMode,
            builder: (context, isLogin, _) {
              return ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingXL),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          isLogin ? 'Welcome Back' : 'Create Account',
                          style: Theme.of(context).textTheme.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        AppTheme.boxHeightXL,
                        ValueListenableBuilder<String?>(
                          valueListenable: viewModel.error,
                          builder: (context, error, _) {
                            if (error == null) return const SizedBox.shrink();
                            return Container(
                              margin: const EdgeInsets.only(
                                bottom: AppTheme.spacingL,
                              ),
                              padding: const EdgeInsets.all(AppTheme.spacingM),
                              decoration: BoxDecoration(
                                color: AppTheme.errorColor.withOpacity(0.1),
                                borderRadius: AppTheme.roundedSmall,
                                border: Border.all(
                                  color: AppTheme.errorColor.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                error,
                                style: const TextStyle(
                                  color: AppTheme.errorColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          },
                        ),
                        if (!isLogin) ...[
                          _buildTextField(
                            controller: _nameController,
                            label: 'Name',
                            icon: Icons.person_outline,
                          ),
                          AppTheme.boxHeightM,
                        ],
                        _buildTextField(
                          controller: _emailController,
                          label: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        AppTheme.boxHeightM,
                        _buildTextField(
                          controller: _passwordController,
                          label: 'Password',
                          icon: Icons.lock_outline,
                          isPassword: true,
                        ),
                        if (!isLogin) ...[
                          AppTheme.boxHeightM,
                          _buildTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                          ),
                        ],
                        AppTheme.boxHeightXL,
                        ValueListenableBuilder<bool>(
                          valueListenable: viewModel.isLoading,
                          builder: (context, isLoading, _) {
                            if (isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return ElevatedButton(
                              onPressed: () {
                                if (isLogin) {
                                  viewModel.login(
                                    context,
                                    _emailController.text,
                                    _passwordController.text,
                                  );
                                } else {
                                  viewModel.signup(
                                    context,
                                    _nameController.text,
                                    _emailController.text,
                                    _passwordController.text,
                                    _confirmPasswordController.text,
                                  );
                                }
                              },
                              child: Text(
                                isLogin ? 'Login' : 'Sign Up',
                                style: Theme.of(context).textTheme.labelLarge!
                                    .copyWith(color: AppTheme.textBlack),
                              ),
                            );
                          },
                        ),
                        AppTheme.boxHeightL,
                        TextButton(
                          onPressed: viewModel.toggleMode,
                          child: Text(
                            isLogin
                                ? "Don't have an account? Sign Up"
                                : "Already have an account? Login",
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary),
      ),
    );
  }
}
