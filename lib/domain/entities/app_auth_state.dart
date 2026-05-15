import 'package:habitflow/domain/entities/entities.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AppAuthState — lives in its own file so it is never in scope with
//  Supabase's AuthState, which prevents the name-clash compiler error.
// ─────────────────────────────────────────────────────────────────────────────

enum AuthStatus { loading, authenticated, unauthenticated }

class AppAuthState {
  final AuthStatus status;
  final AppUser? user;
  final String? error;

  const AppAuthState({required this.status, this.user, this.error});

  const AppAuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        error = null;

  const AppAuthState.unauthenticated()
      : status = AuthStatus.unauthenticated,
        user = null,
        error = null;

  AppAuthState.authenticated(AppUser u)
      : status = AuthStatus.authenticated,
        user = u,
        error = null;

  AppAuthState.withError(String e)
      : status = AuthStatus.unauthenticated,
        user = null,
        error = e;

  bool get isLoading => status == AuthStatus.loading;
  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isUnauthenticated => status == AuthStatus.unauthenticated;
}
