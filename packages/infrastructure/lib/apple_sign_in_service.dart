import 'package:sign_in_with_apple/sign_in_with_apple.dart';

abstract class AppleSignInService {
  Future<AuthorizationCredentialAppleID> getAppleIDCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    WebAuthenticationOptions? webAuthenticationOptions,
  });
}

class AppleSignInServiceImpl implements AppleSignInService {
  @override
  Future<AuthorizationCredentialAppleID> getAppleIDCredential({
    required List<AppleIDAuthorizationScopes> scopes,
    WebAuthenticationOptions? webAuthenticationOptions,
  }) {
    return SignInWithApple.getAppleIDCredential(
        scopes: scopes, webAuthenticationOptions: webAuthenticationOptions);
  }
}
