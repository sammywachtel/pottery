class AuthSession {
  const AuthSession({
    required this.token,
    required this.username,
    this.userId,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  final String token;
  final String username;
  final String? userId;
  final String? email;
  final String? displayName;
  final String? photoUrl;
}
