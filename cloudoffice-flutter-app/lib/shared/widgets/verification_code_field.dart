import 'package:flutter/material.dart';

/// 验证码输入框组件
///
/// 集成了手机号输入和获取验证码按钮，包含倒计时功能。
class VerificationCodeField extends StatelessWidget {
  /// 手机号文本控制器
  final TextEditingController phoneController;

  /// 验证码文本控制器
  final TextEditingController codeController;

  /// 获取验证码回调
  final VoidCallback? onSendCode;

  /// 是否正在倒计时
  final bool isCountingDown;

  /// 倒计时秒数
  final int countdownSeconds;

  /// 手机号校验
  final String? Function(String?)? phoneValidator;

  /// 验证码校验
  final String? Function(String?)? codeValidator;

  /// 手机号变化回调
  final ValueChanged<String>? onPhoneChanged;

  /// 验证码变化回调
  final ValueChanged<String>? onCodeChanged;

  const VerificationCodeField({
    super.key,
    required this.phoneController,
    required this.codeController,
    this.onSendCode,
    this.isCountingDown = false,
    this.countdownSeconds = 0,
    this.phoneValidator,
    this.codeValidator,
    this.onPhoneChanged,
    this.onCodeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 手机号输入（带获取验证码按钮）
        TextFormField(
          controller: phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 11,
          decoration: InputDecoration(
            labelText: '手机号',
            hintText: '请输入手机号',
            prefixIcon: const Icon(Icons.phone_android_outlined),
            counterText: '',
            suffixIcon: SizedBox(
              width: 120,
              child: Center(
                child: TextButton(
                  onPressed: isCountingDown ? null : onSendCode,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    disabledForegroundColor: Colors.grey,
                  ),
                  child: Text(
                    isCountingDown
                        ? '${countdownSeconds}s后重新获取'
                        : '获取验证码',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
          validator: phoneValidator,
          onChanged: onPhoneChanged,
        ),
        const SizedBox(height: 16),
        // 验证码输入
        TextFormField(
          controller: codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: '验证码',
            hintText: '请输入6位验证码',
            prefixIcon: Icon(Icons.sms_outlined),
            counterText: '',
          ),
          validator: codeValidator,
          onChanged: onCodeChanged,
        ),
      ],
    );
  }
}
