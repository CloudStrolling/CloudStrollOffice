import 'package:cloudoffice_flutter_app/core/http/api_result.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/login_request.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/register_request.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/register_result.dart';
import 'package:cloudoffice_flutter_app/features/auth/models/token_pair.dart';
import 'package:cloudoffice_flutter_app/features/auth/repositories/auth_repository.dart';

/// 手动 AuthRepository 桩 - 由测试控制每个方法的返回值
///
/// 方法签名与 AuthRepository 完全一致，避免 Mockito 的 any() 类型问题。
class StubAuthRepository extends AuthRepository {
  Future<ApiResult<TokenPair>> Function(LoginRequest)? onLogin;
  Future<ApiResult<RegisterResult>> Function(RegisterRequest)? onRegister;
  Future<ApiResult<void>> Function()? onLogout;
  Future<ApiResult<void>> Function(String, String, String?)? onSendCode;
  Future<ApiResult<void>> Function(String, String, String, String)?
      onForgotPassword;

  /// 记录调用历史
  final List<String> invocations = [];

  StubAuthRepository();

  @override
  Future<ApiResult<TokenPair>> login(LoginRequest request) async {
    invocations.add('login');
    if (onLogin != null) return onLogin!(request);
    return ApiResult<TokenPair>.error('未桩化', code: 500);
  }

  @override
  Future<ApiResult<RegisterResult>> register(RegisterRequest request) async {
    invocations.add('register');
    if (onRegister != null) return onRegister!(request);
    return ApiResult<RegisterResult>.error('未桩化', code: 500);
  }

  @override
  Future<ApiResult<void>> logout() async {
    invocations.add('logout');
    if (onLogout != null) return onLogout!();
    return ApiResult<void>.error('未桩化', code: 500);
  }

  @override
  Future<ApiResult<void>> sendVerificationCode(
    String target,
    String purpose, [
    String? mode,
  ]) async {
    invocations.add('sendVerificationCode');
    if (onSendCode != null) return onSendCode!(target, purpose, mode);
    return ApiResult<void>.error('未桩化', code: 500);
  }

  @override
  Future<ApiResult<void>> forgotPasswordReset(
    String mode,
    String target,
    String code,
    String newPassword,
  ) async {
    invocations.add('forgotPasswordReset');
    if (onForgotPassword != null) {
      return onForgotPassword!(mode, target, code, newPassword);
    }
    return ApiResult<void>.error('未桩化', code: 500);
  }
}
