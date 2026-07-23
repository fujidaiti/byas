/// Signs up and signs in against the auth API. Both calls issue a bearer
/// token to attach to subsequent requests.
abstract interface class AuthRepository {
  /// `POST /signup` → creates the account and returns the issued token.
  Future<String> signUp({
    required String email,
    required String password,
    required String device,
  });

  /// `POST /signin` → authenticates and returns the issued token.
  Future<String> signIn({
    required String email,
    required String password,
    required String device,
  });
}
