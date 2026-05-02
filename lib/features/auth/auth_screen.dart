import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/mise_text_field.dart';
import '../../core/widgets/mise_button.dart';
import '../../core/services/auth_service.dart'; // ✅ ADDED
import 'household_setup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignIn = true;
  bool _loading = false;
  String? _errorMessage;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isSignIn = !_isSignIn;
      _errorMessage = null;
    });
  }

  // 🔥 UPDATED FUNCTION (REAL BACKEND)
  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields.');
      return;
    }
    if (!_isSignIn && name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your name.');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final auth = AuthService();

    try {
      if (_isSignIn) {
        // 🔐 LOGIN
        await auth.signIn(email: email, password: password);
      } else {
        // 🆕 REGISTER
        await auth.signUp(email: email, password: password);
      }

      if (!mounted) return;

      // ✅ SUCCESS → go to next screen
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const HouseholdSetupScreen()));
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              _Logo(),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _isSignIn ? 'Welcome\nback' : 'Create\naccount',
                  key: ValueKey(_isSignIn),
                  style: AppTextStyles.greeting,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _isSignIn
                    ? 'Sign in to your household'
                    : 'Join or start a household',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 24),
              _Toggle(isSignIn: _isSignIn, onToggle: _toggleMode),
              const SizedBox(height: 20),
              if (!_isSignIn)
                MiseTextField(
                  label: 'Name',
                  placeholder: 'Your name',
                  controller: _nameController,
                ),
              MiseTextField(
                label: 'Email',
                placeholder: 'your@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              MiseTextField(
                label: 'Password',
                placeholder: '••••••••',
                controller: _passwordController,
                obscure: true,
              ),
              if (_errorMessage != null) ...[
                _ErrorBox(message: _errorMessage!),
                const SizedBox(height: 8),
              ],
              MiseButton(
                label: _isSignIn ? 'Sign in' : 'Create account',
                onTap: _submit,
                loading: _loading,
              ),
              const SizedBox(height: 20),
              _Divider(),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _toggleMode,
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.bodySecondary,
                      children: [
                        TextSpan(
                          text: _isSignIn
                              ? 'New here? '
                              : 'Already have an account? ',
                        ),
                        TextSpan(
                          text: _isSignIn ? 'Create an account' : 'Sign in',
                          style: AppTextStyles.bodySecondary.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets (unchanged) ───────────────────────────────────────────────

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Text(
          'M',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.background,
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  final bool isSignIn;
  final VoidCallback onToggle;

  const _Toggle({required this.isSignIn, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          _ToggleItem(
            label: 'Sign in',
            active: isSignIn,
            onTap: isSignIn ? null : onToggle,
          ),
          _ToggleItem(
            label: 'Create account',
            active: !isSignIn,
            onTap: !isSignIn ? null : onToggle,
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _ToggleItem({required this.label, required this.active, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.background : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.textPrimary : AppColors.textTertiary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 15,
            color: AppColors.dangerText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.dangerText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, thickness: 0.5)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: AppTextStyles.caption),
        ),
        const Expanded(child: Divider(color: AppColors.border, thickness: 0.5)),
      ],
    );
  }
}
