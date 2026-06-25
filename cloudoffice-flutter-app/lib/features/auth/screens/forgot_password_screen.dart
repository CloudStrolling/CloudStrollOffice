import 'package:cloudoffice_flutter_app/core/utils/validators.dart';
import 'package:cloudoffice_flutter_app/features/auth/providers/forgot_password_provider.dart';
import 'package:cloudoffice_flutter_app/shared/widgets/loading_button.dart';
import 'package:cloudoffice_flutter_app/shared/widgets/password_field.dart';
import 'package:cloudoffice_flutter_app/shared/widgets/password_strength_indicator.dart';
import 'package:cloudoffice_flutter_app/shared/widgets/verification_code_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 找回密码页面
///
/// 提供两步找回密码流程：
/// Step 0: 身份验证（输入手机号 + 验证码）
/// Step 1: 重置密码（输入新密码 + 确认新密码）
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String _password = '';

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// 校验确认密码（与密码字段比较）
  String? _validateConfirmPassword(String? value) {
    return Validators.validateConfirmPassword(_passwordController.text, value);
  }

  /// 发送验证码
  ///
  /// 校验手机号格式后调用 [ForgotPasswordProvider.sendVerificationCode]。
  Future<void> _handleSendCode() async {
    final phone = _phoneController.text.trim();
    final phoneError = Validators.validatePhone(phone);
    if (phoneError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(phoneError)),
      );
      return;
    }

    final provider = context.read<ForgotPasswordProvider>();
    provider.setTarget(phone);
    final success = await provider.sendVerificationCode();

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? '发送验证码失败')),
      );
    }
  }

  /// 身份验证（第一步）
  ///
  /// 校验表单后调用 [ForgotPasswordProvider.verifyIdentity]，
  /// 验证通过则自动进入下一步（provider.currentStep 变为 1），
  /// 验证失败则显示错误提示。
  Future<void> _handleNextStep() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<ForgotPasswordProvider>();
      provider.setTarget(_phoneController.text.trim());
      provider.setVerificationCode(_codeController.text.trim());

      final verified = provider.verifyIdentity();
      if (!mounted) return;

      if (!verified) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? '验证失败')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 重置密码（第二步）
  ///
  /// 手动校验两次密码一致性后调用 [ForgotPasswordProvider.resetPassword]，
  /// 成功则显示成功提示并在 2 秒后跳转至登录页，
  /// 失败则显示错误提示。
  Future<void> _handleResetPassword() async {
    // 手动校验密码
    final passwordError = Validators.validatePassword(_passwordController.text);
    if (passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(passwordError)),
      );
      return;
    }

    final confirmError = Validators.validateConfirmPassword(
      _passwordController.text,
      _confirmPasswordController.text,
    );
    if (confirmError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(confirmError)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final provider = context.read<ForgotPasswordProvider>();
      provider.setNewPassword(_passwordController.text);
      provider.setConfirmPassword(_confirmPasswordController.text);

      final success = await provider.resetPassword();
      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('密码重置成功')),
        );
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.errorMessage ?? '密码重置失败')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Consumer<ForgotPasswordProvider>(
              builder: (context, provider, _) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 页面标题
                    Text(
                      '找回密码',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (provider.currentStep == 0) ...[
                      // ====== 第一步：身份验证 ======
                      _buildStepIndicator(
                        currentStep: 1,
                        totalSteps: 2,
                        theme: theme,
                      ),
                      const SizedBox(height: 24),
                      Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: VerificationCodeField(
                          phoneController: _phoneController,
                          codeController: _codeController,
                          onSendCode: _handleSendCode,
                          isCountingDown: provider.countdownSeconds > 0,
                          countdownSeconds: provider.countdownSeconds,
                          phoneValidator: Validators.validatePhone,
                          codeValidator: Validators.validateVerificationCode,
                        ),
                      ),
                      const SizedBox(height: 24),
                      LoadingButton(
                        text: '下一步',
                        isLoading: _isLoading,
                        onPressed: _handleNextStep,
                      ),
                    ] else ...[
                      // ====== 第二步：重置密码 ======
                      _buildStepIndicator(
                        currentStep: 2,
                        totalSteps: 2,
                        theme: theme,
                      ),
                      const SizedBox(height: 24),
                      PasswordField(
                        controller: _passwordController,
                        labelText: '新密码',
                        hintText: '请输入新密码',
                        validator: Validators.validatePassword,
                        onChanged: (value) {
                          setState(() {
                            _password = value;
                          });
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: PasswordStrengthIndicator(password: _password),
                      ),
                      PasswordField(
                        controller: _confirmPasswordController,
                        labelText: '确认新密码',
                        hintText: '请再次输入新密码',
                        validator: _validateConfirmPassword,
                      ),
                      const SizedBox(height: 24),
                      LoadingButton(
                        text: '重置密码',
                        isLoading: _isLoading,
                        onPressed: _handleResetPassword,
                      ),
                    ],
                    const SizedBox(height: 24),
                    // 返回登录入口
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        '返回登录',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 构建步骤指示器
  ///
  /// 显示当前步骤 / 总步骤数，并通过圆点连线的方式可视化步骤进度。
  Widget _buildStepIndicator({
    required int currentStep,
    required int totalSteps,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 步骤 1 圆点
        _buildStepDot(
          stepNumber: 1,
          isActive: currentStep >= 1,
          theme: theme,
        ),
        // 连接线
        Container(
          width: 40,
          height: 2,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: currentStep >= 2
                ? colorScheme.primary
                : colorScheme.outlineVariant,
          ),
        ),
        // 步骤 2 圆点
        _buildStepDot(
          stepNumber: 2,
          isActive: currentStep >= 2,
          theme: theme,
        ),
        const SizedBox(width: 8),
        // 步骤文字
        Text(
          '步骤 $currentStep/$totalSteps',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  /// 构建步骤圆点
  Widget _buildStepDot({
    required int stepNumber,
    required bool isActive,
    required ThemeData theme,
  }) {
    final colorScheme = theme.colorScheme;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? colorScheme.primary : colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$stepNumber',
          style: TextStyle(
            color: isActive
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
