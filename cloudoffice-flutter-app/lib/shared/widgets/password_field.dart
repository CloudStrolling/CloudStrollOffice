import 'package:flutter/material.dart';

/// 密码输入框组件
///
/// 包含显示/隐藏密码切换功能。
class PasswordField extends StatefulWidget {
  /// 标签文本
  final String? labelText;

  /// 提示文本
  final String? hintText;

  /// 校验函数
  final String? Function(String?)? validator;

  /// 值变化回调
  final ValueChanged<String>? onChanged;

  /// 文本控制器
  final TextEditingController? controller;

  /// 焦点节点
  final FocusNode? focusNode;

  const PasswordField({
    super.key,
    this.labelText,
    this.hintText,
    this.validator,
    this.onChanged,
    this.controller,
    this.focusNode,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscureText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.labelText ?? '密码',
        hintText: widget.hintText ?? '请输入密码',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        ),
      ),
    );
  }
}
