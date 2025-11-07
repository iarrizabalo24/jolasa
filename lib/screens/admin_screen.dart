import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localdbservice.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import '../utils/snackbar.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _kargatzen = false;
  List<Product> _zerrenda = [];
  List<Map<String, dynamic>> _pendingUsers = [];
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredPending = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _kargatu();
    _kargatuPending();
    _kargatuUsers();
    _searchCtrl.addListener(() => _filterUsers(_searchCtrl.text));
  }

  Future<void> _kargatu() async {
    setState(() => _kargatzen = true);
    final produktuak = await context.read<LocalDbService>().getLocalProducts();
    setState(() {
      _zerrenda = produktuak;
      _kargatzen = false;
    });
  }

  Future<void> _kargatuPending() async {
    final list = await AuthService.instance.getPendingUsers();
    setState(() {
      _pendingUsers = list;
      _filteredPending = List.from(list);
    });
  }

  Future<void> _kargatuUsers() async {
    final list = await AuthService.instance.getAllUsers();
    setState(() {
      _allUsers = list;
      _filteredUsers = List.from(list);
    });
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _allUsers
          .where((u) =>
          u['username'].toLowerCase().contains(query.toLowerCase()))
          .toList();

      _filteredPending = _pendingUsers
          .where((u) =>
          u['username'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _approveUser(String username) async {
    final ok = await AuthService.instance.approvePending(username);
    if (ok) {
      showCustomSnackBar(context, '$username onartu da ✅',
          color: Colors.green.shade300, icon: Icons.check_circle);
      _kargatuPending();
      _kargatuUsers();
    }
  }

  Future<void> _rejectUser(String username) async {
    final ok = await AuthService.instance.rejectPending(username);
    if (ok) {
      showCustomSnackBar(context, '$username baztertua ❌',
          color: Colors.red.shade200, icon: Icons.cancel);
      _kargatuPending();
    }
  }

  Future<void> _deleteUser(String username) async {
    final konfirmatu = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erabiltzailea ezabatu'),
        content: Text(
            'Ziur zaude "$username" erabiltzailea betirako ezabatu nahi duzula?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Utzi'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ezabatu'),
          ),
        ],
      ),
    ) ??
        false;

    if (!konfirmatu) return;

    final ok = await AuthService.instance.deleteUser(username);
    if (ok) {
      showCustomSnackBar(context, 'Erabiltzailea ezabatua: $username',
          color: Colors.blue.shade200, icon: Icons.person_remove);
      _kargatuUsers();
    }
  }

  Future<void> _editUser(String username) async {
    final TextEditingController nameCtrl =
    TextEditingController(text: username);
    final TextEditingController passCtrl = TextEditingController();
    bool makeAdmin =
        _allUsers.firstWhere((u) => u['username'] == username)['isAdmin'] ??
            false;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editatu erabiltzailea: $username'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Erabiltzaile berria',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Pasahitza berria',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 10),
              StatefulBuilder(builder: (ctx, setStateDialog) {
                return CheckboxListTile(
                  value: makeAdmin,
                  onChanged: (v) => setStateDialog(() => makeAdmin = v ?? false),
                  title: const Text('Admin bihurtu'),
                );
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Utzi'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, {
                'newUsername': nameCtrl.text.trim(),
                'newPassword': passCtrl.text.trim(),
                'admin': makeAdmin,
              });
            },
            child: const Text('Gorde'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final newUsername = result['newUsername'];
    final newPass = result['newPassword'];
    final newIsAdmin = result['admin'];

    final ok = await AuthService.instance.updateUser(username,
        newUsername: newUsername.isNotEmpty ? newUsername : null,
        newPassword: newPass.isNotEmpty ? newPass : null,
        makeAdmin: newIsAdmin);

    if (ok) {
      showCustomSnackBar(context, 'Erabiltzailea eguneratua ✅',
          color: Colors.green.shade300, icon: Icons.check_circle);
      _kargatuUsers();
    } else {
      showCustomSnackBar(context, 'Errorea erabiltzailea eguneratzean ⚠️',
          color: Colors.redAccent.shade100, icon: Icons.error_outline);
    }
  }

  Future<void> _ezabatu(Product p) async {
    final konfirmatu = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Produktua ezabatu'),
        content: Text('Ziur zaude "${p.izena}" produktua ezabatu nahi duzula?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Utzi'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ezabatu'),
          ),
        ],
      ),
    ) ??
        false;

    if (konfirmatu) {
      await context.read<LocalDbService>().deleteProduct(p.id);
      _kargatu();
      showCustomSnackBar(
        context,
        '"${p.izena}" produktua ezabatu egin da ✅',
        color: Colors.blueAccent.shade100,
        icon: Icons.delete_outline,
      );
    }
  }

  Future<void> _irten() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final totalResults = _filteredUsers.length + _filteredPending.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kudeaketa - Produktuak eta Erabiltzaileak'),
        backgroundColor: cs.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Eguneratu datuak',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _kargatu();
              _kargatuPending();
              _kargatuUsers();
            },
          ),
          IconButton(
            tooltip: 'Saioa itxi',
            icon: const Icon(Icons.logout),
            onPressed: _irten,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                labelText: 'Bilatu erabiltzailea...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchCtrl.clear();
                    _filterUsers('');
                  },
                )
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              totalResults > 0
                  ? '$totalResults erabiltzaile aurkituta'
                  : 'Ez da emaitzarik aurkitu',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: totalResults > 0 ? Colors.grey.shade700 : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            if (_filteredPending.isNotEmpty)
              _buildPendingCard()
            else if (_pendingUsers.isNotEmpty)
              _buildEmptyCard('Ez dago emaitzarik eskaera pendenteetan'),
            const SizedBox(height: 16),
            _buildUsersCard(),
            const SizedBox(height: 16),
            _buildProductCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildPendingCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Erabiltzaileen eskaerak',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            const Divider(),
            ..._filteredPending.map((u) {
              return ListTile(
                leading:
                const Icon(Icons.pending_actions, color: Colors.indigo),
                title: Text(u['username']),
                subtitle: Text('Data: ${u['fecha'].substring(0, 10)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle, color: Colors.green),
                      onPressed: () => _approveUser(u['username']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel, color: Colors.redAccent),
                      onPressed: () => _rejectUser(u['username']),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Erabiltzaile aktiboak',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
            const Divider(),
            if (_filteredUsers.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Ez dago erabiltzaile aktiborik',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ..._filteredUsers.map((u) => ListTile(
                leading: Icon(
                  u['isAdmin'] == true
                      ? Icons.verified_user
                      : Icons.person,
                  color:
                  u['isAdmin'] == true ? Colors.amber : Colors.blue,
                ),
                title: Text(u['username']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon:
                      const Icon(Icons.edit, color: Colors.green),
                      tooltip: 'Editatu erabiltzailea',
                      onPressed: () => _editUser(u['username']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      tooltip: 'Ezabatu erabiltzailea',
                      onPressed: () => _deleteUser(u['username']),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard() {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text('Produktuen zerrenda',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_zerrenda.length}',
                    style: TextStyle(
                        color: cs.primary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          if (_zerrenda.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Ez dago produkturik',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _zerrenda.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final p = _zerrenda[i];
                return ListTile(
                  leading: Icon(Icons.shopping_bag, color: cs.primary),
                  title: Text(p.izena),
                  subtitle: Text('€ ${p.prezioa.toStringAsFixed(2)}',
                      style: TextStyle(color: cs.primary)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () => _ezabatu(p),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}