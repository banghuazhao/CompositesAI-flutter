import 'package:google_sign_in/google_sign_in.dart';

// Abstract service interface
abstract class GoogleSignInService {
  Future<GoogleSignInUser?> signIn({
    List<String> scopes = const <String>[],
    String? hostedDomain,
    String? clientId,
    String? serverClientId,
    bool forceCodeForRefreshToken = false,
  });
}

class GoogleSignInUser {
  String email;
  String? displayName;
  String? photoUrl;
  String? idToken;

  // Constructor
  GoogleSignInUser(
      {required this.email, this.displayName, this.photoUrl, required this.idToken});
}

// Implementation of the service
class GoogleSignInServiceImpl implements GoogleSignInService {
  static bool _initialized = false;

  @override
  Future<GoogleSignInUser?> signIn({
    List<String> scopes = const <String>[],
    String? hostedDomain,
    String? clientId,
    String? serverClientId,
    bool forceCodeForRefreshToken = false,
  }) async {
    if (!_initialized) {
      await GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
        hostedDomain: hostedDomain,
      );
      _initialized = true;
    }

    try {
      final GoogleSignInAccount account = await GoogleSignIn.instance
          .authenticate(scopeHint: scopes);
      final GoogleSignInAuthentication auth = account.authentication;
      return GoogleSignInUser(
        email: account.email,
        displayName: account.displayName,
        photoUrl: account.photoUrl,
        idToken: auth.idToken ?? '',
      );
    } on GoogleSignInException catch (e) {
      switch (e.code) {
        case GoogleSignInExceptionCode.canceled:
        case GoogleSignInExceptionCode.interrupted:
        case GoogleSignInExceptionCode.uiUnavailable:
          return null;
        // ignore: no_default_cases
        default:
          rethrow;
      }
    }
  }
}
