import 'package:flutter/material.dart';

/// 加载状态按钮组件
///
/// 在加载中显示 CircularProgressIndicator 并禁用点击，防止重复提交。
class LoadingButton extends StatelessWidget {
  /// 按钮文本
  final String text;

  /// 是否正在加载
  final bool isLoading;

  /// 点击回调
  final VoidCallback? onPressed;

  /// 是否禁用
  final bool disabled;

  /// 按钮类型
  final ButtonType type;

  const LoadingButton({
    super.key,
    required this.text,
    this.isLoading = false,
    this.onPressed,
    this.disabled = false,
    this.type = ButtonType.primary,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = disabled || isLoading;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: type == ButtonType.text
            ? TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )
            : ElevatedButton.styleFrom(
                backgroundColor:
                    isDisabled ? Colors.grey.shade300 : theme.colorScheme.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

/// 按钮类型
enum ButtonType {
  /// 主要按钮（实心填充）
  primary,

  /// 文字按钮
  text,
}
