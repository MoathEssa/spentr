/// The signed-in account, returned by `POST /api/auth/login` and
/// `POST /api/auth/register`. The JWT itself is kept in
/// flutter_secure_storage, not in this object.
class User {
  const User({
    required this.id,
    required this.email,
    this.displayName,
  });

  final String id;
  final String email;
  final String? displayName;

  /// Name shown in Settings; falls back to the part of the email before `@`.
  String get name => displayName ?? email.split('@').first;
}
