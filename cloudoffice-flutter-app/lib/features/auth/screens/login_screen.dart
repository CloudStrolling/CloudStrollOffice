import 'package:cloudoffice_flutter_app/core/utils/validators.dart';
import 'package:cloudoffice_flutter_app/features/auth/providers/auth_provider.dart';
import 'package:cloudoffice_flutter_app/shared/widgets/custom_text_field.dart';
import 'package:cloudoffice_flutter_app/shared/widgets/loading_button.dart';
import 'package:cloudoffice_flutter_app/shared/widgets/password_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 登录页面
///
/// 提供用户名/手机号 + 密码的登录方式，支持"记住我"功能。
/// 使用 [AuthProvider] 管理登录状态，[SharedPreferences] 持久化登录名。
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _loginNameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRememberedLoginName();
  }

  @override
  void dispose() {
    _loginNameController.dispose();
    _passwordController.dispose();
    _loginNameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// 从 SharedPreferences 加载已记住的登录名
  Future<void> _loadRememberedLoginName() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLoginName = prefs.getString('remembered_login_name');
    if (savedLoginName != null && savedLoginName.isNotEmpty) {
      _loginNameController.text = savedLoginName;
      setState(() {
        _rememberMe = true;
      });
    }
  }

  /// 根据"记住我"状态保存或清除登录名
  Future<void> _updateRememberedLoginName() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString(
        'remembered_login_name',
        _loginNameController.text.trim(),
      );
    } else {
      await prefs.remove('remembered_login_name');
    }
  }

  /// 提交登录表单
  ///
  /// 校验表单 → 调用 [AuthProvider.login] → 成功则跳转首页 / 失败则显示错误。
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final loginName = _loginNameController.text.trim();
      final password = _passwordController.text;

      final success = await authProvider.login(loginName, password);

      if (!mounted) return;

      if (success) {
        await _updateRememberedLoginName();
        if (!mounted) return;
        context.go('/');
      } else {
        final errorMessage = authProvider.errorMessage ?? '登录失败';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('登录异常，请稍后重试')),
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
                const SizedBox(height: 48),
                // 登录表单
                Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomTextField(
                        controller: _loginNameController,
                        focusNode: _loginNameFocusNode,
                        labelText: '登录名/手机号',
                        hintText: '请输入登录名或手机号',
                        prefixIcon: const Icon(Icons.person_outline),
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.next,
                        validator: Validators.validateLoginName,
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
                      ),
                      const SizedBox(height: 12),
                      // 记住我
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  _rememberMe = value ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            child: Text(
                              '记住我',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      LoadingButton(
                        text: '登 录',
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 注册入口
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '没有账号？',
                      style: theme.textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        '去注册',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 忘记密码
                GestureDetector(
                  onTap: () => context.go('/forgot-password'),
                  child: Text(
                    '忘记密码？',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
