import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/mise_text_field.dart';
import '../../core/widgets/mise_button.dart';
import '../../app.dart';

class HouseholdSetupScreen extends StatefulWidget {
  const HouseholdSetupScreen({super.key});

  @override
  State<HouseholdSetupScreen> createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends State<HouseholdSetupScreen> {
  final _householdNameController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  bool _loadingCreate = false;
  bool _loadingJoin = false;
  String? _errorMessage;

  @override
  void dispose() {
    _householdNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _createHousehold() async {
    if (_householdNameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter a household name.');
      return;
    }
    setState(() {
      _loadingCreate = true;
      _errorMessage = null;
    });

    // TODO: replace with HouseholdBloc call in phase 3
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _loadingCreate = false);
    _goToMain();
  }

  Future<void> _joinHousehold() async {
    if (_inviteCodeController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter an invite code.');
      return;
    }
    setState(() {
      _loadingJoin = true;
      _errorMessage = null;
    });

    // TODO: replace with HouseholdBloc call in phase 3
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _loadingJoin = false);
    _goToMain();
  }

  void _goToMain() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (_) => false,
    );
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
              Container(
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
              ),
              const SizedBox(height: 24),
              Text('Your\nhousehold', style: AppTextStyles.greeting),
              const SizedBox(height: 4),
              Text(
                'Create one or join with a code',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 32),

              // Create section
              _SectionCard(
                icon: Icons.home_rounded,
                iconBg: AppColors.primaryLight,
                iconColor: AppColors.primaryText,
                title: 'Create a household',
                subtitle: 'Start fresh, invite others later',
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    MiseTextField(
                      label: 'Household name',
                      placeholder: 'e.g. Flat 4B',
                      controller: _householdNameController,
                    ),
                    MiseButton(
                      label: 'Create household',
                      onTap: _createHousehold,
                      loading: _loadingCreate,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Expanded(
                    child: Divider(color: AppColors.border, thickness: 0.5),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or join an existing one',
                      style: AppTextStyles.caption,
                    ),
                  ),
                  const Expanded(
                    child: Divider(color: AppColors.border, thickness: 0.5),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              MiseTextField(
                label: 'Invite code',
                placeholder: 'ABC-123',
                controller: _inviteCodeController,
              ),

              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
                          _errorMessage!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.dangerText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              MiseButton(
                label: 'Join household',
                onTap: _joinHousehold,
                loading: _loadingJoin,
                variant: ButtonVariant.secondary,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.heading3),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ],
          ),
          child,
        ],
      ),
    );
  }
}