import 'user.dart';

class AuthSession {
  final String token;
  final String? tokenType;
  final User? user;
  final int? expiresAt;
  final String? oauthSub;
  final bool? hasPassword;
  final Map<String, dynamic>? permissions;

  const AuthSession({
    required this.token,
    this.tokenType,
    this.user,
    this.expiresAt,
    this.oauthSub,
    this.hasPassword,
    this.permissions,
  });

  static Map<String, dynamic>? _parsePermissions(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    // Accept a few common shapes:
    // - { token, user, expires_at, permissions }
    // - { accessToken, user, expiresAt, permissions }
    // - { data: { token, user, ... } }
    Map<String, dynamic> src = json;
    final dynamic data = json['data'];
    if (data is Map<String, dynamic>) {
      src = data;
    }

    final token = (src['token'] ??
            src['accessToken'] ??
            src['access_token'] ??
            src['jwt'])
        ?.toString();

    final tokenType =
        (src['token_type'] ?? src['tokenType'] ?? src['tokenType'])?.toString();

    final dynamic userRaw = src['user'] ?? src['profile'] ?? src['payload'];
    User? user;
    if (userRaw is Map<String, dynamic>) {
      // Some APIs nest the actual user object under payload.user
      final dynamic nestedUser = userRaw['user'];
      if (nestedUser is Map<String, dynamic>) {
        user = User.fromJson(nestedUser);
      } else {
        user = User.fromJson(userRaw);
      }
    }
    // SessionUserResponse may return user fields at the top-level.
    user ??= User.fromJson(src);

    final dynamic expiresRaw = src['expires_at'] ?? src['expiresAt'];
    final int? expiresAt = expiresRaw is int
        ? expiresRaw
        : int.tryParse(expiresRaw?.toString() ?? '');

    return AuthSession(
      token: token ?? '',
      tokenType: tokenType,
      user: user,
      expiresAt: expiresAt,
      oauthSub: (src['oauth_sub'] ?? src['oauthSub'])?.toString(),
      hasPassword: src['has_password'] is bool
          ? src['has_password'] as bool
          : (src['hasPassword'] is bool ? src['hasPassword'] as bool : null),
      permissions: _parsePermissions(src['permissions']),
    );
  }
}

