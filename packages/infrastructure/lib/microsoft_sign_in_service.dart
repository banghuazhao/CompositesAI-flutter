/// Microsoft credentials scoped to this application's MSAL client.
/// Implementations must never sign out a broker or shared device globally.
abstract class MicrosoftSignInService {
  /// Returns null when the user cancels the account picker.
  Future<String?> acquireAccessToken({bool Function()? isActive});

  /// Removes only Microsoft accounts/tokens cached for this application.
  Future<void> clearAppSession();
}

class MicrosoftSessionCleanupException implements Exception {
  const MicrosoftSessionCleanupException();

  @override
  String toString() =>
      'Microsoft sign-in could not be reset. Please try again or use another sign-in option.';
}
