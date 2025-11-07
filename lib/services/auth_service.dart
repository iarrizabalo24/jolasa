import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AppUser {
  final String username;
  final bool isAdmin;
  const AppUser({required this.username, required this.isAdmin});
}

class ScoreEntry {
  final String username;
  final int bestScore;
  final int lastScore;
  final int updatedAtMillis;
  ScoreEntry({
    required this.username,
    required this.bestScore,
    required this.lastScore,
    required this.updatedAtMillis,
  });

  Map<String, dynamic> toJson() => {
    'username': username,
    'bestScore': bestScore,
    'lastScore': lastScore,
    'updatedAt': updatedAtMillis,
  };

  factory ScoreEntry.fromJson(Map<String, dynamic> j) => ScoreEntry(
    username: j['username'],
    bestScore: j['bestScore'],
    lastScore: j['lastScore'],
    updatedAtMillis: j['updatedAt'],
  );
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  static const _kUsersKey = 'users_v1';
  static const _kPendingKey = 'pending_users_v1';
  static const _kCurrentUserKey = 'current_user_v1';
  static const _kRankingKey = 'ranking_v1';

  AppUser? _current;
  AppUser? get currentUser => _current;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final usersRaw = prefs.getString(_kUsersKey);
    Map<String, dynamic> users = {};
    if (usersRaw != null) users = jsonDecode(usersRaw);

    if (!users.containsKey('admin')) {
      users['admin'] = {'hash': _hash('1234'), 'admin': true};
      await prefs.setString(_kUsersKey, jsonEncode(users));
    }

    final curRaw = prefs.getString(_kCurrentUserKey);
    if (curRaw != null) {
      final m = jsonDecode(curRaw);
      _current = AppUser(username: m['username'], isAdmin: m['admin']);
    }
  }

  String _hash(String s) {
    final bytes = utf8.encode(s);
    int sum = 0;
    for (final b in bytes) sum = (sum * 31 + b) & 0x7fffffff;
    return sum.toRadixString(16);
  }

  Future<bool> userExists(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUsersKey);
    if (raw == null) return false;
    final users = jsonDecode(raw);
    return users.containsKey(username);
  }

  Future<bool> pendingExists(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPendingKey);
    if (raw == null) return false;
    final pending = jsonDecode(raw) as List;
    return pending.any((p) => p['username'] == username);
  }

  Future<bool> register(String user, String pass) async {
    final prefs = await SharedPreferences.getInstance();

    final rawUsers = prefs.getString(_kUsersKey);
    final rawPending = prefs.getString(_kPendingKey);

    Map<String, dynamic> users = rawUsers != null ? jsonDecode(rawUsers) : {};
    List pending = rawPending != null ? jsonDecode(rawPending) : [];

    if (users.containsKey(user) ||
        pending.any((p) => p['username'] == user)) return false;

    pending.add({
      'username': user,
      'hash': _hash(pass),
      'fecha': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_kPendingKey, jsonEncode(pending));
    return true;
  }

  Future<bool> login(String user, String pass) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUsersKey);
    if (raw == null) return false;
    final users = jsonDecode(raw);
    final entry = users[user];
    if (entry == null) return false;
    if (entry['hash'] != _hash(pass)) return false;

    _current = AppUser(username: user, isAdmin: entry['admin'] ?? false);
    await prefs.setString(_kCurrentUserKey,
        jsonEncode({'username': user, 'admin': entry['admin']}));
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    _current = null;
    await prefs.remove(_kCurrentUserKey);
  }

  Future<List<Map<String, dynamic>>> getPendingUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPendingKey);
    if (raw == null) return [];
    final list = jsonDecode(raw);
    return (list as List).map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<bool> approvePending(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final rawUsers = prefs.getString(_kUsersKey);
    final rawPending = prefs.getString(_kPendingKey);

    Map<String, dynamic> users = rawUsers != null ? jsonDecode(rawUsers) : {};
    List pending = rawPending != null ? jsonDecode(rawPending) : [];

    final idx = pending.indexWhere((p) => p['username'] == username);
    if (idx == -1) return false;

    final entry = pending[idx];
    users[username] = {'hash': entry['hash'], 'admin': false};
    pending.removeAt(idx);

    await prefs.setString(_kUsersKey, jsonEncode(users));
    await prefs.setString(_kPendingKey, jsonEncode(pending));
    return true;
  }

  Future<bool> rejectPending(String username) async {
    final prefs = await SharedPreferences.getInstance();
    final rawPending = prefs.getString(_kPendingKey);
    if (rawPending == null) return false;

    final pending = jsonDecode(rawPending);
    pending.removeWhere((p) => p['username'] == username);
    await prefs.setString(_kPendingKey, jsonEncode(pending));
    return true;
  }

  // === RANKING ===
  Future<void> saveScore(int score) async {
    final user = _current;
    if (user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRankingKey);
    List list = raw != null ? jsonDecode(raw) : [];
    final entries = list.map((e) => ScoreEntry.fromJson(e)).toList();
    final idx = entries.indexWhere((e) => e.username == user.username);
    final now = DateTime.now().millisecondsSinceEpoch;
    if (idx >= 0) {
      final cur = entries[idx];
      final best = score > cur.bestScore ? score : cur.bestScore;
      entries[idx] = ScoreEntry(
          username: user.username,
          bestScore: best,
          lastScore: score,
          updatedAtMillis: now);
    } else {
      entries.add(ScoreEntry(
          username: user.username,
          bestScore: score,
          lastScore: score,
          updatedAtMillis: now));
    }
    entries.sort((a, b) => b.bestScore.compareTo(a.bestScore));
    await prefs.setString(
        _kRankingKey, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }

  Future<List<ScoreEntry>> getRanking() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kRankingKey);
    if (raw == null) return [];
    final list = jsonDecode(raw);
    return (list as List).map((e) => ScoreEntry.fromJson(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUsersKey);
    if (raw == null) return [];
    final users = Map<String, dynamic>.from(jsonDecode(raw));
    final list = users.entries
        .where((e) => e.key != 'admin')
        .map((e) => {
      'username': e.key,
      'isAdmin': e.value['admin'] ?? false,
    })
        .toList();
    return list;
  }

  Future<bool> deleteUser(String username) async {
    if (username == 'admin') return false;
    final prefs = await SharedPreferences.getInstance();

    final rawUsers = prefs.getString(_kUsersKey);
    if (rawUsers == null) return false;
    final users = Map<String, dynamic>.from(jsonDecode(rawUsers));
    users.remove(username);
    await prefs.setString(_kUsersKey, jsonEncode(users));

    final rawRanking = prefs.getString(_kRankingKey);
    if (rawRanking != null) {
      final list = jsonDecode(rawRanking) as List;
      list.removeWhere((r) => r['username'] == username);
      await prefs.setString(_kRankingKey, jsonEncode(list));
    }
    return true;
  }

  Future<bool> updateUser(String username, {String? newUsername, String? newPassword, bool? makeAdmin}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUsersKey);
    if (raw == null) return false;
    final users = Map<String, dynamic>.from(jsonDecode(raw));
    if (!users.containsKey(username)) return false;

    if (newPassword != null && newPassword.isNotEmpty) {
      users[username]['hash'] = _hash(newPassword);
    }
    if (makeAdmin != null) {
      users[username]['admin'] = makeAdmin;
    }

    await prefs.setString(_kUsersKey, jsonEncode(users));
    return true;
  }
}