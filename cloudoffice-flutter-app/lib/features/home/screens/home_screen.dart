import 'package:cloudoffice_flutter_app/features/home/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// 首页
///
/// 展示用户信息卡片，提供退出登录功能。
/// 使用 [HomeProvider] 管理状态，[GoRouter] 进行页面跳转。
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 确保 Widget 挂载后加载用户信息
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<HomeProvider>().loadUserInfo();
    });
  }

  /// 退出登录
  ///
  /// 弹出确认对话框 → 调用 [HomeProvider.logout] → 跳转到登录页。
  /// API 调用失败时显示 SnackBar，但仍会清除本地 Token 并跳转。
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认退出'),
        content: const Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<HomeProvider>().logout();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('退出登录失败，已离线清除登录状态')),
      );
    }

    if (!mounted) return;
    context.go('/login');
  }

  /// 掩码手机号
  ///
  /// 显示前 3 位 + "****" + 后 4 位，不足 7 位或为 null 时返回 "未绑定"。
  String _maskPhone(String? phone) {
    if (phone == null || phone.length < 7) return '未绑定';
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }

  /// 掩码邮箱
  ///
  /// 显示前 2 位 + "***@" + 域名，不含 @ 或为 null 时返回 "未绑定"。
  String _maskEmail(String? email) {
    if (email == null || !email.contains('@')) return '未绑定';
    final parts = email.split('@');
    final name = parts[0];
    final domain = parts.sublist(1).join('@');
    if (name.length < 2) {
      return '${name}***@$domain';
    }
    return '${name.substring(0, 2)}***@$domain';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('云漫智企'),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '退出登录',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Consumer<HomeProvider>(
        builder: (context, homeProvider, _) {
          if (homeProvider.isLoading && homeProvider.userInfo == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final userInfo = homeProvider.userInfo;
          if (userInfo == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '暂无用户信息',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            );
          }

          final displayName = userInfo.userName ?? userInfo.loginName ?? '用户';

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  margin: const EdgeInsets.all(8),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 欢迎语
                        Text(
                          '欢迎回来，$displayName！',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 登录名
                        _InfoRow(
                          label: '登录名',
                          value: userInfo.loginName ?? '未设置',
                        ),
                        const SizedBox(height: 16),
                        // 真实姓名
                        _InfoRow(
                          label: '真实姓名',
                          value: userInfo.userName ?? '未设置',
                        ),
                        const SizedBox(height: 16),
                        // 手机号
                        _InfoRow(
                          label: '手机号',
                          value: _maskPhone(userInfo.phone),
                        ),
                        const SizedBox(height: 16),
                        // 邮箱
                        _InfoRow(
                          label: '邮箱',
                          value: _maskEmail(userInfo.email),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 信息行组件
///
/// 用于用户信息卡片中展示键值对：上标签（[bodySmall]、[onSurfaceVariant]），
/// 下值（[bodyLarge]）。
class _InfoRow extends StatelessWidget {
  /// 标签文本
  final String label;

  /// 值文本
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}
