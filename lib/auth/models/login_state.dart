sealed class LoginState {
  const LoginState();
}

class LoginStateLoading extends LoginState {
  const LoginStateLoading();
}

class LoginStateServerSelection extends LoginState {
  const LoginStateServerSelection();
}

class LoginStateUserSelection extends LoginState {
  final String serverId;
  const LoginStateUserSelection({required this.serverId});
}

class LoginStateAuthenticated extends LoginState {
  final String userId;
  final String serverId;
  const LoginStateAuthenticated({
    required this.userId,
    required this.serverId,
  });
}

class LoginStateError extends LoginState {
  final String message;
  const LoginStateError({required this.message});
}
