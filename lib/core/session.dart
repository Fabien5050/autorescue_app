import 'package:shared_preferences/shared_preferences.dart';

/// App-wide holder for the signed-in user's session. Populated by
/// [AuthApi] calls and persisted so it survives a hot restart.
class Session {
  Session._();

  static final Session instance = Session._();

  String? token;
  int? userId;
  String? fullName;
  String? email;
  String? role;
  int? workshopId;

  bool get isLoggedIn => token != null;

  void update({
    required String token,
    required int userId,
    required String fullName,
    required String email,
    required String role,
    int? workshopId,
  }) {
    this.token = token;
    this.userId = userId;
    this.fullName = fullName;
    this.email = email;
    this.role = role;
    this.workshopId = workshopId;
    _persist();
  }

  /// Clears both the in-memory session and its persisted copy. Callers
  /// should `await` this — if the process dies right after logout but
  /// before the (previously fire-and-forget) prefs writes landed, the next
  /// [restore] would read the stale token back and silently "undo" the
  /// logout.
  Future<void> clear() async {
    token = null;
    userId = null;
    fullName = null;
    email = null;
    role = null;
    workshopId = null;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await Future.wait(<String>[
      'token',
      'userId',
      'fullName',
      'email',
      'role',
      'workshopId',
    ].map((String suffix) => prefs.remove('$_key.$suffix')));
  }

  Future<void> restore() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('$_key.token');
    if (token == null) return;
    this.token = token;
    userId = prefs.getInt('$_key.userId');
    fullName = prefs.getString('$_key.fullName');
    email = prefs.getString('$_key.email');
    role = prefs.getString('$_key.role');
    workshopId = prefs.getInt('$_key.workshopId');
  }

  Future<void> _persist() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_key.token', token!);
    await prefs.setInt('$_key.userId', userId!);
    await prefs.setString('$_key.fullName', fullName!);
    await prefs.setString('$_key.email', email!);
    await prefs.setString('$_key.role', role!);
    if (workshopId != null) {
      await prefs.setInt('$_key.workshopId', workshopId!);
    } else {
      await prefs.remove('$_key.workshopId');
    }
  }

  static const String _key = 'autorescue.session';
}
