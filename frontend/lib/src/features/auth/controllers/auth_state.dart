class AuthState {
  const AuthState({
    required this.isInitializing,
    required this.isLoading,
    required this.isAuthenticated,
    this.username,
    this.token,
    this.userId,
    this.email,
    this.displayName,
    this.photoUrl,
    this.errorMessage,
  });

  factory AuthState.initial() {
    return const AuthState(
      isInitializing: true,
      isLoading: false,
      isAuthenticated: false,
    );
  }

  static const _undefined = Object();

  final bool isInitializing;
  final bool isLoading;
  final bool isAuthenticated;
  final String? username;
  final String? token;
  final String? userId;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? errorMessage;

  AuthState copyWith({
    bool? isInitializing,
    bool? isLoading,
    bool? isAuthenticated,
    Object? username = _undefined,
    Object? token = _undefined,
    Object? userId = _undefined,
    Object? email = _undefined,
    Object? displayName = _undefined,
    Object? photoUrl = _undefined,
    Object? errorMessage = _undefined,
  }) {
    return AuthState(
      isInitializing: isInitializing ?? this.isInitializing,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: identical(username, _undefined)
          ? this.username
          : username as String?,
      token: identical(token, _undefined) ? this.token : token as String?,
      userId: identical(userId, _undefined) ? this.userId : userId as String?,
      email: identical(email, _undefined) ? this.email : email as String?,
      displayName: identical(displayName, _undefined)
          ? this.displayName
          : displayName as String?,
      photoUrl: identical(photoUrl, _undefined)
          ? this.photoUrl
          : photoUrl as String?,
      errorMessage: identical(errorMessage, _undefined)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}
