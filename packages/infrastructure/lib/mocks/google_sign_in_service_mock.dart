import 'dart:async';
import 'package:mockito/mockito.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../google_sign_in_service.dart';

class MockGoogleSignInService extends Mock implements GoogleSignInService {
  @override
  Future<GoogleSignInUser?> signIn({
    List<String> scopes = const <String>[],
    String? hostedDomain,
    String? clientId,
    String? serverClientId,
    bool forceCodeForRefreshToken = false,
  }) {
    return super.noSuchMethod(
      Invocation.method(#signIn, [], {
        #scopes: scopes,
        #hostedDomain: hostedDomain,
        #clientId: clientId,
        #serverClientId: serverClientId,
        #forceCodeForRefreshToken: forceCodeForRefreshToken,
      }),
      returnValue: Future.value(GoogleSignInUser(
          email: "test.user@example.com",
          displayName: "Test User",
          photoUrl: "https://example.com/photo.jpg",
          idToken: "idToken")),
      returnValueForMissingStub: Future.value(GoogleSignInUser(
          email: "test.user@example.com",
          displayName: "Test User",
          photoUrl: "https://example.com/photo.jpg",
          idToken: "idToken")),
    );
  }
}
