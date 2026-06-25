import 'package:flutter/material.dart';

/// 自定义输入框组件
///
/// 基于 TextFormField 的统一封装，遵循 Material Design 3 风格。
class CustomTextField extends StatelessWidget {
  /// 标签文本
  final String? labelText;

  /// 提示文本
  final String? hintText;

  /// 前置图标
  final Widget? prefixIcon;

  /// 后置图标/按钮
  final Widget? suffixIcon;

  /// 校验函数
  final String? Function(String?)? validator;

  /// 值变化回调
  final ValueChanged<String>? onChanged;

  /// 焦点失去回调
  final ValueChanged<String>? onFieldSubmitted;

  /// 键盘类型
  final TextInputType? keyboardType;

  /// 最大长度
  final int? maxLength;

  /// 是否隐藏文本（密码场景）
  final bool obscureText;

  /// 文本控制器
  final TextEditingController? controller;

  /// 是否启用
  final bool enabled;

  /// 自动聚焦
  final bool autofocus;

  /// 焦点节点
  final FocusNode? focusNode;

  /// 文本操作类型
  final TextInputAction? textInputAction;

  const CustomTextField({
    super.key,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.keyboardType,
    this.maxLength,
    this.obscureText = false,
    this.controller,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      autofocus: autofocus,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        counterText: '', // 隐藏默认字数统计
      ),
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
    );
  }
}
