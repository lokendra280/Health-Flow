import 'package:habitflow/domain/entities/app_auth_state.dart';
import 'package:habitflow/domain/entities/entities.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isSignedIn => currentUser != null;

  Stream<AppAuthState> get authStateChanges =>
      _client.auth.onAuthStateChange.map((e) {
        final u = e.session?.user;
        if (u == null) return const AppAuthState.unauthenticated();
        return AppAuthState.authenticated(_mapUser(u));
      });

  Future<AppUser> signUp(
      {required String email,
      required String password,
      String? username}) async {
    final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: username != null ? {'username': username} : null);
    if (res.user == null)
      throw Exception('Sign up failed. Please confirm your email.');
    if (username?.isNotEmpty == true)
      await _upsertProfile(res.user!.id, username!);
    return _mapUser(res.user!);
  }

  Future<AppUser> deleteAccount() async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    // remove profile row from the database
    await _client.from('profiles').delete().eq('id', uid);
    // Deleting the auth user record requires a secure server-side call with the service_role key.
    // Throw to indicate that the client cannot complete the full account deletion.
    throw UnimplementedError(
        'Deleting the auth user must be done from a secure server with the service_role key.');
  }

  Future<void> sendOtp({
    required String email,
  }) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email,
    );
  }

  Future<AppUser> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final res = await _client.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: otp,
    );

    if (res.user == null) {
      throw Exception('Invalid OTP');
    }

    return _mapUser(res.user!);
  }

  Future<AppUser> signIn(
      {required String email, required String password}) async {
    final res =
        await _client.auth.signInWithPassword(email: email, password: password);
    if (res.user == null) throw Exception('Invalid credentials.');
    return _mapUser(res.user!);
  }

  Future<void> signInWithGoogle() async =>
      _client.auth.signInWithOAuth(OAuthProvider.google,
          redirectTo: 'io.supabase.habitflow://login-callback/');

  Future<void> signInWithApple() async =>
      _client.auth.signInWithOAuth(OAuthProvider.apple,
          redirectTo: 'io.supabase.habitflow://login-callback/');

  Future<void> sendMagicLink(String email) async => _client.auth.signInWithOtp(
      email: email, emailRedirectTo: 'io.supabase.habitflow://login-callback/');

  Future<void> sendPasswordReset(String email) async =>
      _client.auth.resetPasswordForEmail(email,
          redirectTo: 'io.supabase.habitflow://reset-callback/');

  Future<void> updatePassword(String newPassword) async =>
      _client.auth.updateUser(UserAttributes(password: newPassword));

  Future<AppUser> updateProfile({String? username, String? avatarUrl}) async {
    final uid = currentUser?.id;
    if (uid == null) throw Exception('Not signed in');
    await _upsertProfile(uid, username, avatarUrl: avatarUrl);
    final profile =
        await _client.from('profiles').select().eq('id', uid).single();
    return _mapUser(currentUser!, profile: profile);
  }

  Future<AppUser?> getProfile() async {
    final u = currentUser;
    if (u == null) return null;
    try {
      final profile =
          await _client.from('profiles').select().eq('id', u.id).maybeSingle();
      return _mapUser(u, profile: profile);
    } catch (_) {
      return _mapUser(u);
    }
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<void> _upsertProfile(String uid, String? username,
          {String? avatarUrl}) =>
      _client.from('profiles').upsert({
        'id': uid,
        if (username != null) 'username': username,
        if (avatarUrl != null) 'avatar_url': avatarUrl,
      });

  AppUser _mapUser(User u, {Map<String, dynamic>? profile}) => AppUser(
        id: u.id,
        email: u.email ?? '',
        username: profile?['username'] as String? ??
            u.userMetadata?['username'] as String?,
        avatarUrl: profile?['avatar_url'] as String? ??
            u.userMetadata?['avatar_url'] as String?,
        createdAt: DateTime.tryParse(u.createdAt) ?? DateTime.now(),
      );
}
