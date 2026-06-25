import 'package:flutter/material.dart';

import '../../core/utils/validators.dart';

/// 密码强度指示器组件
///
/// 实时显示密码强度，三级：弱（红色）、中（橙色）、强（绿色）。
class PasswordStrengthIndicator extends StatelessWidget {
  /// 密码文本
  final String password;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = Validators.calculatePasswordStrength(password);
    final label = Validators.getPasswordStrengthLabel(strength);

    Color color;
    double progress;
    switch (strength) {
      case 0:
        color = Colors.red;
        progress = 0.33;
        break;
      case 1:
        color = Colors.orange;
        progress = 0.66;
        break;
      case 2:
        color = Colors.green;
        progress = 1.0;
        break;
      default:
        color = Colors.grey;
        progress = 0;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 强度进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 2),
          // 强度文字
          Text(
            '密码强度：$label',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
