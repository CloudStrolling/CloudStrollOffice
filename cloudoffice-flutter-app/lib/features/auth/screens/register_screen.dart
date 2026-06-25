import 'package:cloudoffice_flutter_app/core/utils/validators.dart';
import 'package:cloudoffice_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:cloudoffice_flutter_app/shared/widgets/custom_text_field.dart';
import 'package:cloudoffice_flutter_app/shared/widgets/loading_button.dart';
import 'package:cloudoffice_flutter_app/shared/widgets/password_field.dart';
import 'package:cloudoffice_flutter_app/shared/widgets/password_strength_indicator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 注册页面
///
/// 提供用户名 + 真实姓名 + 密码 + 确认密码的注册方式。
/// 使用 [AuthProvider] 管理注册状态，注册成功自动登录并跳转至首页。
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginNameController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _loginNameFocusNode = FocusNode();
  final _userNameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  bool _isLoading = false;
  String _password = '';

  @override
  void dispose() {
    _loginNameController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _loginNameFocusNode.dispose();
    _userNameFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  /// 校验确认密码（与密码字段比较）
  String? _validateConfirmPassword(String? value) {
    return Validators.validateConfirmPassword(_passwordController.text, value);
  }

  /// 提交注册表单
  ///
  /// 校验表单 → 调用 [AuthProvider.register] → 成功则自动登录并跳转首页 / 失败则显示错误。
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final loginName = _loginNameController.text.trim();
      final password = _passwordController.text;
      final userName = _userNameController.text.trim();

      final success = await authProvider.register(loginName, password, userName);

      if (!mounted) return;

      if (success) {
        context.go('/');
      } else {
        final errorMessage = authProvider.errorMessage ?? '注册失败';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注册异常，请稍后重试')),
      );
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo 区域
                Text(
                  '云漫智企',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '企业智能管理平台',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  '注册新账号',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                // 注册表单
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _loginNameController,
                        focusNode: _loginNameFocusNode,
                        labelText: '用户名',
                        hintText: '请输入用户名',
                        prefixIcon: const Icon(Icons.person_outline),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        validator: Validators.validateLoginName,
                        onFieldSubmitted: (_) {
                          _userNameFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _userNameController,
                        focusNode: _userNameFocusNode,
                        labelText: '真实姓名',
                        hintText: '请输入真实姓名',
                        prefixIcon: const Icon(Icons.badge_outlined),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        validator: Validators.validateUserName,
                        onFieldSubmitted: (_) {
                          _passwordFocusNode.requestFocus();
                        },
                      ),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        labelText: '密码',
                        hintText: '请输入密码',
                        validator: Validators.validatePassword,
                        onChanged: (value) {
                          setState(() {
                            _password = value;
                          });
                        },
                      ),
                      PasswordStrengthIndicator(password: _password),
                      const SizedBox(height: 16),
                      PasswordField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocusNode,
                        labelText: '确认密码',
                        hintText: '请再次输入密码',
                        validator: _validateConfirmPassword,
                      ),
                      const SizedBox(height: 24),
                      LoadingButton(
                        text: '注 册',
                        isLoading: _isLoading,
                        onPressed: _handleRegister,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 登录入口
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '已有账号？',
                      style: theme.textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Text(
                        '去登录',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
