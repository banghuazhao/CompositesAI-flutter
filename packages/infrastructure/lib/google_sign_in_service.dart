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
  Future<GoogleSignInUser?> signIn({
    List<String> scopes = const <String>[],
    String? hostedDomain,
    String? clientId,
    String? serverClientId,
    bool forceCodeForRefreshToken = false,
  }) async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: scopes,
      hostedDomain: hostedDomain,
      clientId: clientId,
      serverClientId: serverClientId,
      forceCodeForRefreshToken: forceCodeForRefreshToken,
    );
    GoogleSignInAccount? user = await googleSignIn.signIn();
    final GoogleSignInAuthentication? auth = await user?.authentication;
    if (user != null) {
      return GoogleSignInUser(
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoUrl,
          idToken: auth?.idToken ?? '');
    } else {
      return null;
    }
  }
}
